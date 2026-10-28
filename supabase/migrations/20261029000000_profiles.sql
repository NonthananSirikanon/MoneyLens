-- One profile per signed-in user. Holds data collected right after sign-in
-- (birth date). The sign-in method itself (phone or Google) and the contact
-- details live in auth.users and are not copied here.
create table public.profiles (
  user_id uuid primary key default auth.uid()
    references auth.users (id) on delete cascade,
  -- Gregorian date; the app shows it in Buddhist years. No age limit: the
  -- only rule is that it is a real date that is not in the future and not
  -- implausibly old.
  birth_date date not null
    check (birth_date <= current_date and birth_date >= date '1900-01-01'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "own profile" on public.profiles
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

revoke all on public.profiles from anon;
grant select, insert, update, delete on public.profiles to authenticated;

-- Keep updated_at honest even if the client forgets to send it.
create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = clock_timestamp();
  return new;
end $$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();
