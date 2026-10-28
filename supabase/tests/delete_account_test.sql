-- delete_my_account(): removes the caller's account and every row of theirs,
-- and nobody else's. Run like schema_test.sql (see README).
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

insert into auth.users (id, instance_id, aud, role, email) values
  ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'a@test.dev'),
  ('00000000-0000-0000-0000-0000000000b2', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'b@test.dev');

-- Both users have a full set of data.
do $$
declare u uuid;
begin
  foreach u in array array['00000000-0000-0000-0000-0000000000a1'::uuid, '00000000-0000-0000-0000-0000000000b2'::uuid] loop
    insert into public.accounts (user_id, id, name, kind, currency_code, created_at, updated_at)
      values (u, 'cash', 'Cash', 'cash', 'THB', now(), now());
    insert into public.categories (user_id, id, name, kind, created_at, updated_at)
      values (u, 'default-expense-food', 'Food', 'expense', now(), now());
    insert into public.scan_records (user_id, id, source, status, created_at, updated_at)
      values (u, 'scan-1', 'gallery', 'failed', now(), now());
    insert into public.transactions (user_id, id, type, amount_minor, currency_code, account_id, category_id, source, occurred_at, created_at, updated_at)
      values (u, 'tx-1', 'expense', 4500, 'THB', 'cash', 'default-expense-food', 'manual', now(), now(), now());
    insert into public.profiles (user_id, birth_date) values (u, '1997-03-14');
  end loop;
end $$;

-- Not signed in: refused.
set local role authenticated;
select set_config('request.jwt.claims', '', true);
select pg_temp.expect_error($q$select public.delete_my_account()$q$, '28000', 'needs a signed-in user');
reset role;

-- The signed-out role cannot even call it.
set local role anon;
select pg_temp.expect_error($q$select public.delete_my_account()$q$, '42501', 'anon cannot call it');
reset role;

-- User A deletes their account.
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);
select public.delete_my_account();
reset role;

do $$ begin
  assert not exists (select 1 from auth.users where id = '00000000-0000-0000-0000-0000000000a1'), 'A is gone';
  assert (select count(*) from public.accounts where user_id = '00000000-0000-0000-0000-0000000000a1') = 0, 'A accounts';
  assert (select count(*) from public.categories where user_id = '00000000-0000-0000-0000-0000000000a1') = 0, 'A categories';
  assert (select count(*) from public.scan_records where user_id = '00000000-0000-0000-0000-0000000000a1') = 0, 'A scans';
  assert (select count(*) from public.transactions where user_id = '00000000-0000-0000-0000-0000000000a1') = 0, 'A transactions';
  assert (select count(*) from public.profiles where user_id = '00000000-0000-0000-0000-0000000000a1') = 0, 'A profile';
  raise notice 'ok: the account and all of its rows are deleted';
end $$;

-- User B is untouched.
do $$ begin
  assert exists (select 1 from auth.users where id = '00000000-0000-0000-0000-0000000000b2'), 'B exists';
  assert (select count(*) from public.accounts where user_id = '00000000-0000-0000-0000-0000000000b2') = 1, 'B accounts';
  assert (select count(*) from public.categories where user_id = '00000000-0000-0000-0000-0000000000b2') = 1, 'B categories';
  assert (select count(*) from public.scan_records where user_id = '00000000-0000-0000-0000-0000000000b2') = 1, 'B scans';
  assert (select count(*) from public.transactions where user_id = '00000000-0000-0000-0000-0000000000b2') = 1, 'B transactions';
  assert (select count(*) from public.profiles where user_id = '00000000-0000-0000-0000-0000000000b2') = 1, 'B profile';
  raise notice 'ok: another user''s data is untouched';
end $$;

rollback;
