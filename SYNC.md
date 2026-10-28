# Sync (device ⇄ Supabase)

Status: **accounts, categories and transactions** sync. Scan records and slip
images do not yet (see "Not yet").

## Principles

- The database on the device (Drift) stays the primary one. The app never
  waits for the network; sync runs in the background.
- Each user's data is separate on the device (`moneylens_<user id>.sqlite`)
  and in the cloud (Row Level Security on `user_id`).
- One rule for conflicts: **the most recent edit of a record wins**
  (`updated_at`). Good enough for personal finance, easy to explain.

## How it works

1. **Outbox.** SQLite triggers (`lib/infrastructure/database/sync.drift`)
   record every insert, update and delete of the three tables in
   `sync_outbox`: one row per record, replaced by later changes. No
   repository has to remember to call sync.
2. **Push.** Rows in the outbox are sent in batches (accounts, categories,
   transactions; deletes in the reverse order). A row leaves the outbox only
   after the server accepted it and only if it was not changed meanwhile.
3. **Pull.** For each table the app asks for rows whose
   `server_updated_at` is after its saved cursor. The server sets that column
   itself, so a device that was offline for a week cannot slip changes in
   "behind" another device's cursor.
4. **Apply.** Pulled rows are written with the `applying` flag on, so the
   triggers do not send them back. A pulled row replaces the local one only
   if it is at least as new.
5. **Deletes** are soft in the cloud (`deleted_at`), so other devices learn
   about them. On the device a deleted row is simply gone.
6. **Stale writes** are rejected by the server (trigger
   `sync_before_write`): an older `updated_at` never overwrites a newer row.

When it runs: after sign-in, a few seconds after a local change, every five
minutes, and from the Account screen ("Sync now"). Offline or failing, the
outbox just waits.

## Details worth knowing

- Defaults created by a fresh install (default categories, cash account)
  carry an old timestamp (2000-01-01), so the cloud copy wins on a new device
  rather than being overwritten by a fresh default.
- "Delete all data" deletes the rows locally and therefore in the cloud too.
- Existing data from before sync is queued once by the v3 database migration.
- A transaction's link to its slip (`scan_record_id`) and `attachment_path`
  stay on the device for now.

## Not yet

- Scan records and slip images (needs Supabase Storage and a decision on OCR
  text retention, DATABASE.md §9).
- A conflict screen: edits to the same record from two devices at once keep
  the later one without telling the user.
