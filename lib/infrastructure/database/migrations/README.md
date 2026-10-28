# Database migrations

Schema version: **2** (`AppDatabase.schemaVersion`). Snapshots live in
`drift_schemas/moneylens/`.

To change the schema:

1. Edit the tables in `../tables/` and bump `schemaVersion`.
2. Run `dart run drift_dev make-migrations`. Drift dumps the new schema,
   generates step-by-step helpers (`schema_versions.dart`) next to the
   database, and writes migration tests under `test/drift/`.
3. Replace the `onUpgrade` guard in `app_database.dart` with
   `stepByStep(from1To2: ...)` and put each step's code in this folder.
4. Fill in the generated migration tests with data checks, then run
   `flutter test`.

History: v2 adds `accounts.last_four` (step `from1To2` in
`app_database.dart`) and seeds the extra default categories and the default
cash account.

Never recreate tables destructively on user data (DATABASE.md §10).
