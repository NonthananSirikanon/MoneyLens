-- Mirrors the on-device schema v2: last four digits of an account number.
-- Only the last four digits are ever stored, never the full number.
alter table public.accounts
  add column last_four text
  check (last_four is null or last_four ~ '^[0-9]{4}$');
