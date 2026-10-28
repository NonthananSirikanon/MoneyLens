-- Profiles: constraints and RLS. Run like schema_test.sql (see README).
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

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);

insert into profiles (birth_date) values ('1997-03-14');
do $$ begin
  assert (select user_id from profiles) = '00000000-0000-0000-0000-0000000000a1';
  raise notice 'ok: user_id comes from the JWT';
end $$;

select pg_temp.expect_error($q$insert into profiles (birth_date) values ('1998-01-01')$q$, '23505', 'one profile per user');

-- A date in the future / before 1900 is rejected.
update profiles set birth_date = '1999-05-05';
do $$ begin assert (select birth_date from profiles) = date '1999-05-05'; raise notice 'ok: a user can change their own birth date'; end $$;
select pg_temp.expect_error($q$update profiles set birth_date = current_date + 1$q$, '23514', 'birth date cannot be in the future');
select pg_temp.expect_error($q$update profiles set birth_date = '1899-12-31'$q$, '23514', 'birth date cannot be before 1900');
select pg_temp.expect_error($q$update profiles set birth_date = null$q$, '23502', 'birth date is required');

-- Born today is allowed (no age limit).
update profiles set birth_date = current_date;
do $$ begin assert (select birth_date from profiles) = current_date; raise notice 'ok: no minimum age'; end $$;

-- updated_at moves on update.
do $$ declare t0 timestamptz; begin
  select updated_at into t0 from profiles;
  perform pg_sleep(0.01);
  update profiles set birth_date = '1997-03-14';
  assert (select updated_at from profiles) > t0, 'updated_at not bumped';
  raise notice 'ok: updated_at is bumped by the trigger';
end $$;

-- Another user sees nothing and cannot write as A.
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000b2","role":"authenticated"}', true);
do $$ begin assert (select count(*) from profiles) = 0; raise notice 'ok: another user cannot read the profile'; end $$;
select pg_temp.expect_error($q$insert into profiles (user_id, birth_date) values ('00000000-0000-0000-0000-0000000000a1', '2000-01-01')$q$, '42501', 'cannot create a profile for another user');
update profiles set birth_date = '2001-01-01';
delete from profiles;
reset role;
do $$ begin
  assert (select birth_date from profiles where user_id = '00000000-0000-0000-0000-0000000000a1') = date '1997-03-14';
  raise notice 'ok: another user cannot update or delete it';
end $$;

-- Deleting the auth user removes the profile.
delete from auth.users where id = '00000000-0000-0000-0000-0000000000a1';
do $$ begin assert (select count(*) from profiles) = 0; raise notice 'ok: profile is deleted with the account'; end $$;

set local role anon;
select pg_temp.expect_error('select * from profiles', '42501', 'anon cannot read profiles');

rollback;
