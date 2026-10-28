-- Lets a signed-in user delete their own account (PROJECT.md PR-11).
--
-- Clients cannot write to auth.users, so this runs as the function owner.
-- Every user table (accounts, categories, scan_records, transactions,
-- profiles) references auth.users with `on delete cascade`, so all of the
-- user's rows go with the account. It only ever touches the caller's own
-- row: the id comes from the JWT, not from an argument.
--
-- Files in Storage are not removed by this (there are none yet); whoever adds
-- image sync must delete the user's objects before calling it.
create function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  delete from auth.users where id = auth.uid();
end $$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
