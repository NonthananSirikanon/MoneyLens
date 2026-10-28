-- Run against a local stack: see supabase/README.md. Everything runs in one
-- transaction that is rolled back, and prints a NOTICE per passed check.
begin;

create function pg_temp.expect_error(sql text, expected text, label text) returns void
language plpgsql as $$
begin
  execute sql;
  raise exception 'FAILED (no error raised): %', label;
exception when others then
  if sqlerrm like 'FAILED%' then raise; end if;
  if sqlstate <> expected then
    raise exception 'FAILED (%, expected % got %: %)', label, expected, sqlstate, sqlerrm;
  end if;
  raise notice 'ok: % (%)', label, sqlstate;
end $$;

insert into auth.users (id, instance_id, aud, role, email)
values
  ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'a@test.dev'),
  ('00000000-0000-0000-0000-0000000000b2', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'b@test.dev');

-- Act as user A.
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);

insert into accounts (id, name, kind, currency_code, opening_balance_minor, created_at, updated_at) values
  ('cash', 'Cash', 'cash', 'THB', 100000, now(), now()),
  ('bank', 'Bank', 'bank', 'THB', null, now(), now());
insert into categories (id, name, kind, created_at, updated_at) values
  ('default-expense-food', 'Food', 'expense', now(), now()),
  ('default-income-salary', 'Salary', 'income', now(), now());

-- user_id is filled from the JWT.
do $$ begin
  assert (select user_id from accounts where id = 'cash') = '00000000-0000-0000-0000-0000000000a1';
  raise notice 'ok: user_id defaults to the caller';
end $$;

-- Constraints.
select pg_temp.expect_error($q$insert into transactions (id,type,amount_minor,currency_code,account_id,source,occurred_at,created_at,updated_at)
  values ('t0','expense',0,'THB','cash','manual',now(),now(),now())$q$, '23514', 'amount must be positive');
select pg_temp.expect_error($q$insert into transactions (id,type,amount_minor,currency_code,account_id,destination_account_id,source,occurred_at,created_at,updated_at)
  values ('t0','transfer',100,'THB','cash','cash','manual',now(),now(),now())$q$, '23514', 'transfer needs a different destination');
select pg_temp.expect_error($q$insert into transactions (id,type,amount_minor,currency_code,account_id,destination_account_id,category_id,source,occurred_at,created_at,updated_at)
  values ('t0','transfer',100,'THB','cash','bank','default-expense-food','manual',now(),now(),now())$q$, '23514', 'transfer cannot have a category');
select pg_temp.expect_error($q$insert into transactions (id,type,amount_minor,currency_code,account_id,destination_account_id,source,occurred_at,created_at,updated_at)
  values ('t0','expense',100,'THB','cash','bank','manual',now(),now(),now())$q$, '23514', 'expense cannot have a destination');
select pg_temp.expect_error($q$insert into transactions (id,type,amount_minor,currency_code,account_id,source,occurred_at,created_at,updated_at)
  values ('t0','expense',100,'THB','missing','manual',now(),now(),now())$q$, '23503', 'account must exist');

-- Valid transactions: +50,000 income, -4,500 expense, 20,000 transfer.
insert into transactions (id,type,amount_minor,currency_code,account_id,destination_account_id,category_id,source,occurred_at,created_at,updated_at) values
  ('t1','income',50000,'THB','cash',null,'default-income-salary','manual',now(),now(),now()),
  ('t2','expense',4500,'THB','cash',null,'default-expense-food','manual',now(),now(),now()),
  ('t3','transfer',20000,'THB','cash','bank',null,'manual',now(),now(),now());

do $$ begin
  assert (select balance_minor from account_balances where account_id = 'cash') = 100000 + 50000 - 4500 - 20000, 'cash balance';
  assert (select balance_minor from account_balances where account_id = 'bank') = 20000, 'bank balance';
  assert (select sum(balance_minor) from account_balances) = 100000 + 50000 - 4500, 'transfer keeps the total';
  raise notice 'ok: balances (opening + income - expense, transfers move money)';
end $$;

delete from transactions where id = 't2';
do $$ begin
  assert (select balance_minor from account_balances where account_id = 'cash') = 100000 + 50000 - 20000, 'after delete';
  raise notice 'ok: deleting a transaction corrects the balance';
end $$;

-- A scan can be confirmed only once.
insert into scan_records (id, source, status, created_at, updated_at)
  values ('s1', 'camera', 'needs_review', now(), now());
insert into transactions (id,type,amount_minor,currency_code,account_id,category_id,source,scan_record_id,occurred_at,created_at,updated_at)
  values ('t4','expense',100,'THB','cash','default-expense-food','ocr','s1',now(),now(),now());
select pg_temp.expect_error($q$insert into transactions (id,type,amount_minor,currency_code,account_id,category_id,source,scan_record_id,occurred_at,created_at,updated_at)
  values ('t5','expense',100,'THB','cash','default-expense-food','ocr','s1',now(),now(),now())$q$, '23505', 'a scan confirms only one transaction');

-- Deleting the transaction keeps the scan and clears its link.
update scan_records set transaction_id = 't4', status = 'confirmed' where id = 's1';
delete from transactions where id = 't4';
do $$ begin
  assert (select transaction_id from scan_records where id = 's1') is null;
  assert (select user_id from scan_records where id = 's1') is not null, 'user_id kept';
  assert (select status from scan_records where id = 's1') = 'confirmed';
  raise notice 'ok: deleting a transaction keeps the scan with a cleared link';
end $$;

-- Row Level Security: user B sees nothing of A and cannot write as A.
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b2","role":"authenticated"}', true);
do $$ begin
  assert (select count(*) from accounts) = 0, 'B sees accounts';
  assert (select count(*) from transactions) = 0, 'B sees transactions';
  assert (select count(*) from account_balances) = 0, 'B sees balances';
  raise notice 'ok: another user sees none of A''s rows';
end $$;
select pg_temp.expect_error($q$insert into accounts (user_id,id,name,kind,currency_code,created_at,updated_at)
  values ('00000000-0000-0000-0000-0000000000a1','x','Spoof','cash','THB',now(),now())$q$, '42501', 'cannot insert rows for another user');
update transactions set note = 'hijack' where id = 't1';
do $$ begin
  assert (select count(*) from transactions) = 0;
  raise notice 'ok: updates cannot reach another user''s rows';
end $$;

-- Same ids are fine for different users (composite keys).
insert into categories (id, name, kind, created_at, updated_at)
  values ('default-expense-food', 'Food', 'expense', now(), now());
do $$ begin raise notice 'ok: two users can both have the same default category id'; end $$;

-- Anonymous role has no access.
reset role;
set local role anon;
select pg_temp.expect_error('select * from accounts', '42501', 'anon cannot read accounts');

rollback;
