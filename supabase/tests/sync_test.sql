-- Sync support: server timestamps, stale-write protection, soft deletes.
-- Run like schema_test.sql (see README).
begin;

insert into auth.users (id, instance_id, aud, role, email) values
  ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'a@test.dev');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);

insert into accounts (id, name, kind, currency_code, opening_balance_minor, created_at, updated_at)
  values ('cash', 'Cash', 'cash', 'THB', 100000, '2026-10-01 10:00+00', '2026-10-01 10:00+00');
insert into categories (id, name, kind, created_at, updated_at)
  values ('default-expense-food', 'Food', 'expense', '2026-10-01 10:00+00', '2026-10-01 10:00+00');
insert into transactions (id,type,amount_minor,currency_code,account_id,category_id,source,occurred_at,created_at,updated_at)
  values ('t1','expense',4500,'THB','cash','default-expense-food','manual','2026-10-02 10:00+00','2026-10-02 10:00+00','2026-10-02 10:00+00');

-- The server stamps every write, later writes get later stamps.
do $$
declare first_stamp timestamptz;
begin
  select server_updated_at into first_stamp from transactions where id = 't1';
  assert first_stamp is not null, 'stamped on insert';
  update transactions set note = 'newer', updated_at = '2026-10-03 10:00+00' where id = 't1';
  assert (select server_updated_at from transactions where id = 't1') > first_stamp, 'stamp moves on update';
  assert (select note from transactions where id = 't1') = 'newer';
  raise notice 'ok: server_updated_at is set on insert and moves on update';
end $$;

-- A write with an older updated_at is ignored (the newer edit wins).
do $$
declare stamp timestamptz;
begin
  select server_updated_at into stamp from transactions where id = 't1';
  update transactions set note = 'stale', updated_at = '2026-10-02 12:00+00' where id = 't1';
  assert (select note from transactions where id = 't1') = 'newer', 'stale edit ignored';
  assert (select server_updated_at from transactions where id = 't1') = stamp, 'stamp unchanged';
  raise notice 'ok: a stale write does not overwrite a newer row';
end $$;

-- ...also when it arrives as an upsert (how the app sends changes).
insert into transactions (id,type,amount_minor,currency_code,account_id,category_id,source,occurred_at,created_at,updated_at,note)
  values ('t1','expense',4500,'THB','cash','default-expense-food','manual','2026-10-02 10:00+00','2026-10-02 10:00+00','2026-10-01 00:00+00','old upsert')
  on conflict (user_id, id) do update set note = excluded.note, updated_at = excluded.updated_at;
do $$ begin
  assert (select note from transactions where id = 't1') = 'newer', 'stale upsert ignored';
  raise notice 'ok: a stale upsert is ignored';
end $$;

-- Soft delete: the row stays (so other devices learn about it) but no longer
-- counts towards balances.
do $$ begin
  assert (select balance_minor from account_balances where account_id = 'cash') = 100000 - 4500, 'before delete';
end $$;
update transactions set deleted_at = '2026-10-04 10:00+00', updated_at = '2026-10-04 10:00+00' where id = 't1';
do $$ begin
  assert (select count(*) from transactions where id = 't1' and deleted_at is not null) = 1, 'tombstone kept';
  assert (select balance_minor from account_balances where account_id = 'cash') = 100000, 'deleted tx ignored';
  raise notice 'ok: soft-deleted transactions keep a tombstone and leave the balance';
end $$;

-- A newer edit brings it back.
update transactions set deleted_at = null, updated_at = '2026-10-05 10:00+00' where id = 't1';
do $$ begin
  assert (select balance_minor from account_balances where account_id = 'cash') = 100000 - 4500, 'restored';
  raise notice 'ok: a newer write can undelete';
end $$;

-- Soft-deleted accounts disappear from the balances view.
update accounts set deleted_at = '2026-10-06 10:00+00', updated_at = '2026-10-06 10:00+00' where id = 'cash';
do $$ begin
  assert (select count(*) from account_balances) = 0, 'deleted account hidden';
  raise notice 'ok: deleted accounts are not in account_balances';
end $$;

rollback;
