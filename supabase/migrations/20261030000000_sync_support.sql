-- What device sync needs from the cloud tables (SYNC.md).
--
--   deleted_at         soft delete, so other devices learn about deletions
--   server_updated_at  set by the server on every write; devices page
--                      through changes by it. (The client-supplied
--                      updated_at cannot be used for that: a device that was
--                      offline pushes old timestamps late.)
--
-- A write with an older updated_at than the stored row is ignored, so the
-- most recent edit wins no matter in which order devices reach the server.
alter table public.accounts
  add column deleted_at timestamptz,
  add column server_updated_at timestamptz not null default clock_timestamp();
alter table public.categories
  add column deleted_at timestamptz,
  add column server_updated_at timestamptz not null default clock_timestamp();
alter table public.transactions
  add column deleted_at timestamptz,
  add column server_updated_at timestamptz not null default clock_timestamp();
alter table public.scan_records
  add column server_updated_at timestamptz not null default clock_timestamp();

create function public.sync_before_write()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and new.updated_at < old.updated_at then
    return null; -- skip this row: the stored one is newer
  end if;
  new.server_updated_at = clock_timestamp();
  return new;
end $$;

create trigger accounts_sync_before_write
  before insert or update on public.accounts
  for each row execute function public.sync_before_write();
create trigger categories_sync_before_write
  before insert or update on public.categories
  for each row execute function public.sync_before_write();
create trigger transactions_sync_before_write
  before insert or update on public.transactions
  for each row execute function public.sync_before_write();
create trigger scan_records_sync_before_write
  before insert or update on public.scan_records
  for each row execute function public.sync_before_write();

create index idx_accounts_server_updated_at
  on public.accounts (user_id, server_updated_at);
create index idx_categories_server_updated_at
  on public.categories (user_id, server_updated_at);
create index idx_transactions_server_updated_at
  on public.transactions (user_id, server_updated_at);
create index idx_scan_records_server_updated_at
  on public.scan_records (user_id, server_updated_at);

-- Deleted records no longer count towards balances.
create or replace view public.account_balances
with (security_invoker = true) as
select
  a.user_id,
  a.id as account_id,
  a.currency_code,
  coalesce(a.opening_balance_minor, 0)
    + coalesce(sum(
        case
          when t.type = 'income' and t.account_id = a.id then t.amount_minor
          when t.type = 'expense' and t.account_id = a.id then -t.amount_minor
          when t.type = 'transfer' and t.account_id = a.id then -t.amount_minor
          when t.type = 'transfer' and t.destination_account_id = a.id
            then t.amount_minor
          else 0
        end
      ), 0) as balance_minor
from public.accounts a
left join public.transactions t
  on t.user_id = a.user_id
  and t.currency_code = a.currency_code
  and t.deleted_at is null
  and (t.account_id = a.id or t.destination_account_id = a.id)
where a.deleted_at is null
group by a.user_id, a.id, a.currency_code, a.opening_balance_minor;
