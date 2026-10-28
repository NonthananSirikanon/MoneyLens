# MoneyLens Supabase backend

PostgreSQL schema, Row Level Security and tests for the optional cloud
backend (ARCHITECTURE.md §3). The app stays offline-first: Drift on the
device is still the primary database, and the app syncs its entries here in
the background (SYNC.md).

## Layout

- `migrations/` – schema, applied in filename order. Change the schema only
  by adding a new migration; never edit one that was already pushed.
- `tests/schema_test.sql` – checks constraints, balances and RLS.
- `tests/profiles_test.sql` – checks the birth-date profile (constraints, RLS, cascade).
- `tests/sync_test.sql` – checks the sync columns (server timestamps, stale-write protection, soft deletes).
- `config.toml` – local stack settings.

## Local development (needs Docker)

The Supabase CLI runs through npx, so nothing is installed globally:

```sh
npx supabase@2.122.0 start        # starts a local stack and applies migrations
npx supabase@2.122.0 db reset     # rebuild from the migrations
docker exec -i supabase_db_MoneyLens psql -U postgres -v ON_ERROR_STOP=1 \
  < supabase/tests/schema_test.sql   # and profiles_test.sql, sync_test.sql
npx supabase@2.122.0 stop
```

The test prints `NOTICE: ok: ...` for each check and ends with `ROLLBACK`
(it changes nothing). A failed check raises an error.

## Pushing to the hosted project

```sh
npx supabase@2.122.0 login                     # opens the browser
npx supabase@2.122.0 link --project-ref <ref>  # ref is in the project URL
npx supabase@2.122.0 db push
```

## Rules

- Never put the `service_role` / secret key in the app or in git. The app
  uses only the publishable (anon) key plus the signed-in user's session.
- Every new table needs `user_id`, RLS enabled and a policy, plus a case in
  `tests/schema_test.sql`.
- Raw OCR text is not stored in the cloud until a retention policy exists
  (DATABASE.md §9).
