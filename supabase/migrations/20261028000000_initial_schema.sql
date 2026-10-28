-- MoneyLens cloud schema (PostgreSQL / Supabase).
--
-- Mirrors the on-device Drift schema in DATABASE.md §3 so records can be
-- synced one-to-one. Differences from the local database:
--   * every row belongs to a user (`user_id`, filled from the JWT) and every
--     table has Row Level Security, so a user can only see their own data;
--   * primary keys are (user_id, id). Ids stay TEXT because the app seeds
--     default categories with stable ids such as 'default-expense-food',
--     which would collide between users if `id` were the only key;
--   * timestamps are timestamptz (UTC) and money is bigint minor units.
-- Account balances are never stored (DATABASE.md §3.1); see the
-- `account_balances` view.

-- ---------------------------------------------------------------- accounts
create table public.accounts (
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  id text not null,
  name text not null check (length(name) >= 1),
  kind text not null check (kind in ('cash', 'bank', 'ewallet', 'other')),
  currency_code text not null check (length(currency_code) = 3),
  opening_balance_minor bigint,
  is_archived boolean not null default false,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  primary key (user_id, id)
);

-- -------------------------------------------------------------- categories
create table public.categories (
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  id text not null,
  name text not null check (length(name) >= 1),
  kind text not null check (kind in ('income', 'expense')),
  icon_key text,
  color_value bigint,
  is_default boolean not null default false,
  is_archived boolean not null default false,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  primary key (user_id, id)
);

-- ------------------------------------------------------------ scan_records
-- `transaction_id` mirrors `transactions.scan_record_id` for lookups; its
-- foreign key is added after `transactions` exists (the two reference each
-- other). `transactions.scan_record_id` stays authoritative.
-- Sensitive OCR text (`raw_text`) is deliberately not stored in the cloud
-- until a retention policy exists (DATABASE.md §9).
create table public.scan_records (
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  id text not null,
  source text not null
    check (source in ('camera', 'gallery', 'share_sheet', 'discovery')),
  attachment_path text,
  image_fingerprint text,
  extracted_payload jsonb,
  status text not null check (status in (
    'queued', 'processing', 'needs_review', 'confirmed',
    'duplicate', 'failed', 'discarded')),
  failure_code text,
  failure_message text,
  duplicate_of_scan_id text,
  transaction_id text,
  processor_version text,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  processed_at timestamptz,
  deleted_at timestamptz,
  primary key (user_id, id),
  foreign key (user_id, duplicate_of_scan_id)
    references public.scan_records (user_id, id)
    on delete set null (duplicate_of_scan_id)
);

-- ------------------------------------------------------------ transactions
create table public.transactions (
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  id text not null,
  type text not null check (type in ('income', 'expense', 'transfer')),
  amount_minor bigint not null check (amount_minor > 0),
  currency_code text not null check (length(currency_code) = 3),
  account_id text not null,
  destination_account_id text,
  category_id text,
  merchant text,
  note text,
  occurred_at timestamptz not null,
  source text not null
    check (source in ('manual', 'ocr', 'import', 'recurring')),
  scan_record_id text,
  attachment_path text,
  provider_reference text,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  primary key (user_id, id),
  foreign key (user_id, account_id)
    references public.accounts (user_id, id),
  foreign key (user_id, destination_account_id)
    references public.accounts (user_id, id),
  foreign key (user_id, category_id)
    references public.categories (user_id, id),
  foreign key (user_id, scan_record_id)
    references public.scan_records (user_id, id)
    on delete set null (scan_record_id),
  -- A scan can never be confirmed twice, even if the app checks are bypassed.
  unique (user_id, scan_record_id),
  -- Transfers need a distinct destination and no category; income and
  -- expense must not have a destination (DATABASE.md §3.3).
  check (
    (type = 'transfer'
      and destination_account_id is not null
      and destination_account_id <> account_id
      and category_id is null)
    or (type <> 'transfer' and destination_account_id is null)
  )
);

alter table public.scan_records
  add foreign key (user_id, transaction_id)
    references public.transactions (user_id, id)
    on delete set null (transaction_id);

-- ----------------------------------------------------------------- indexes
-- DATABASE.md §8. The (user_id, ...) prefix serves RLS-filtered queries.
create index idx_transactions_occurred_at
  on public.transactions (user_id, occurred_at);
create index idx_transactions_type_occurred_at
  on public.transactions (user_id, type, occurred_at);
create index idx_transactions_account_occurred_at
  on public.transactions (user_id, account_id, occurred_at);
create index idx_transactions_category_occurred_at
  on public.transactions (user_id, category_id, occurred_at);
create index idx_scan_records_status_created_at
  on public.scan_records (user_id, status, created_at);
create index idx_scan_records_image_fingerprint
  on public.scan_records (user_id, image_fingerprint);

-- ---------------------------------------------------- Row Level Security
-- Each user can read and write only their own rows. Nothing is granted to
-- the anonymous role.
alter table public.accounts enable row level security;
alter table public.categories enable row level security;
alter table public.scan_records enable row level security;
alter table public.transactions enable row level security;

create policy "own rows" on public.accounts
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "own rows" on public.categories
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "own rows" on public.scan_records
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "own rows" on public.transactions
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

revoke all on public.accounts, public.categories,
  public.scan_records, public.transactions from anon;
grant select, insert, update, delete on public.accounts, public.categories,
  public.scan_records, public.transactions to authenticated;

-- ---------------------------------------------------------------- balances
-- balance = opening balance + effect of every transaction (DATABASE.md §3.1):
-- income adds, expense subtracts, a transfer subtracts from its source and
-- adds to its destination. `security_invoker` makes the view obey the
-- caller's RLS, so users only ever see their own accounts.
create view public.account_balances
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
  and (t.account_id = a.id or t.destination_account_id = a.id)
group by a.user_id, a.id, a.currency_code, a.opening_balance_minor;

revoke all on public.account_balances from anon;
grant select on public.account_balances to authenticated;
