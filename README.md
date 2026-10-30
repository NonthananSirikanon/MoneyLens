# MoneyLens

Offline-first personal finance app for iOS and Android. Payment slips are imported, read with OCR, and turned into transactions that the user must review before they are saved.

This is the **initial scaffold** (ROADMAP week 1). The product, architecture, database, and plan documents are the source of truth:
[PROJECT.md](PROJECT.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · [DATABASE.md](DATABASE.md) · [ROADMAP.md](ROADMAP.md) · [SYNC.md](SYNC.md) · [RUNNING.md](RUNNING.md) (how to run on an emulator)

## Requirements

- Flutter 3.47 (stable) / Dart 3.13
- Xcode 16+ and CocoaPods for iOS
- Android SDK 36 and JDK 17+ for Android (Android Studio's bundled JBR works:
  `flutter config --jdk-dir "/Applications/Android Studio.app/Contents/jbr/Contents/Home"`)

## Commands

```sh
flutter pub get
dart run build_runner build      # Drift code generation (writes *.g.dart)
flutter gen-l10n                 # Localizations (also runs automatically on build)
dart format lib test integration_test
flutter analyze
flutter test                     # unit + widget tests
flutter test integration_test -d <simulator-or-device-id>
flutter run                      # or press F5 in VS Code ("MoneyLens (debug)")
flutter build apk --debug
flutter build ios --simulator --debug
```

Generated files (`*.g.dart`, `lib/l10n/app_localizations*.dart`) are committed, so a fresh clone builds without running generators first. Re-run the generators after changing tables or ARB files. Use `dart run build_runner watch` while editing tables.

## Architecture

The code is organized by feature. Dependencies flow **Presentation → Application → Domain ← Data**.

```
lib/
  app/             App widget, GoRouter, theme, bottom-nav shell, startup provider
  core/            Money (integer minor units), dates (UTC + Asia/Bangkok), failures,
                   privacy-safe logger, ID generation, shared loading/empty/error widgets
  infrastructure/
    database/      Drift database, tables (DATABASE.md §3), seed, migrations guide
    platform/      image_picker camera/gallery adapter, Share Sheet placeholder
  features/
    accounts/      domain entity + repository interface, Drift implementation
    categories/    domain entity + repository interface, Drift implementation
    transactions/  domain rules (TransactionValidator), repository, CreateTransaction,
                   history screen
    dashboard/     SummaryCalculator (the single place totals are computed), screen
    slip_import/   ports (ImageSourceAdapter, ImageValidator, SlipImageStore, OcrService,
                   ExtractionService, DuplicateDetector, ScanRepository), the shared
                   SlipImportPipeline, ConfirmScan, import screen
  l10n/            Thai (primary/fallback) and English ARB files
```

- **Domain** classes are plain Dart with no Flutter or platform imports, so they are unit-testable.
- **Application** classes hold use cases and Riverpod providers. Each feature's providers bind its interfaces to implementations, and tests replace them with `overrideWith`/`overrideWithValue`.
- **Data / infrastructure** contains the Drift repositories and platform adapters. Widgets never access tables directly.

### Key rules and where they are enforced

| Rule | Where |
|---|---|
| Money is stored as integer minor units, never `double` | `core/money/money.dart`, `amount_minor INTEGER CHECK (> 0)` |
| Transfers are never counted as income or expense | `SummaryCalculator`, `TransactionValidator`, SQL `CHECK` |
| A transfer needs a destination that differs from the source, and no category | `TransactionValidator` + SQL `CHECK` |
| OCR never auto-confirms a transaction | `ScanStatus.canTransitionTo` (only `needs_review → confirmed`), `ScanRepository.transition` refuses `confirmed` |
| Confirmation is idempotent | `confirmFromScan` runs in one DB transaction; `transactions.scan_record_id` is `UNIQUE` |
| Every import source uses one pipeline | `SlipImportPipeline.ingest` |
| Interrupted processing is recoverable | `recoverInterrupted()` at startup; queued/failed scans can be retried |
| No financial or OCR content in logs | `AppLogger` accepts event codes only and redacts `String` metadata |

### Decisions taken in this scaffold

- **Scan↔transaction link:** `transactions.scan_record_id` (UNIQUE) is the source of truth. `scan_records.transaction_id` is a mirror, written in the same DB transaction.
- **Currency:** THB only, but the code is structured to add more. `Currency` carries per-currency minor digits.
- **Time:** instants are stored in UTC. Reports use Asia/Bangkok as a fixed UTC+7 offset (Thailand has no DST), so no tz database is needed. Report ranges are half-open `[start, end)`.
- **Raw OCR text** is not persisted (`scan_records.raw_text` stays null) until a retention policy exists (DATABASE.md §9).
- **Default categories** are seeded with stable IDs using `INSERT OR IGNORE`, so seeding is idempotent.

## UI and data

The screens implement `design/mockups/prototype.html` using the design system in `design/mockups/index.html`, built on Forui. Tokens and text styles are in `lib/app/theme/`, and the shared widgets (`Ml*`) are in `lib/core/widgets/`.

**Transactions, accounts, categories, balances and reports use the real Drift database.** `DemoStore` (`lib/demo/demo_store.dart`) mirrors the database for the UI and writes every change back through the repositories. A fresh install starts empty with a default cash account and the default categories. Balances are `opening balance + transactions` (`AccountBalanceCalculator`), and reports come from `ReportCalculator`.

**Slip import is real.** Choosing photos (or sharing images into the app) saves the image, reads it with the on-device OCR engine, extracts amount, date, payee and type, and opens the review screen with the fields it could not read left blank and the doubtful ones highlighted. Nothing is saved until the user confirms. Sample mode (below) still loads the prototype's accounts and a simulated slip queue.

| Platform | Engine | Notes |
|---|---|---|
| iOS | Apple Vision (`VNRecognizeTextRequest`, `th-TH` + `en-US`), iOS 16+ | Not yet run inside the app on a device. The same recognizer read all 12 real sample slips correctly in a standalone check. |
| Android | Tesseract4Android 4.9.0, Thai model (`tessdata_fast`, Apache-2.0) bundled in `android/app/src/main/assets/tessdata/` | On the 12 real sample slips: amount 10/12, date 7/12, payee 11/12. Misses are left blank or flagged, never invented. |

Both sit behind the `moneylens/ocr` platform channel (`PlatformOcrService`) and `ThaiSlipExtractionService` turns the text into fields. Test fixtures in `test/fixtures/slips/` are invented text, not real slips. OCR text is never logged or stored.

```sh
flutter run --dart-define=ML_SAMPLE_DATA=true   # sample mode with the simulated queue
```

Also simulated: permissions and Face ID.

Preview states with `flutter run --dart-define=ML_SCENARIO=<offline|dbError|loading>`. Strings live in `lib/l10n/app_th.arb` (Thai, copied from the prototype) and `app_en.arb`; Settings → ภาษา switches the language.

## Sign-in (Google)

Sign-in is required before the app can be used: onboarding → sign-in → birth date → permissions → Home. Google opens the browser and returns through `com.moneylens.app://login-callback/`. The design in `design/mockups` (board "Sign in & Profile" and the clickable `prototype.html`) matches this.

**Without a Supabase key the app uses an in-memory fake**: "Continue with Google" signs in a demo user and nothing is saved. That is what `flutter run`, the tests and the simulator smoke test use.

**To use the real backend**, pass the project's publishable key (never the `service_role`/secret key):

```sh
flutter run --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

`SUPABASE_URL` defaults to this project's URL. Before the real flows work, configure Supabase (Dashboard → Authentication):

1. **Providers → Google:** create OAuth clients in Google Cloud and paste them in.
2. **URL Configuration → Redirect URLs:** add `com.moneylens.app://login-callback/`.
3. Push the `profiles` migration (`npx supabase@2.122.0 db push`); the birth date is saved there.

Notes and limits:

- If the profile cannot be read (offline), a returning user is let in so that data on the device stays reachable; the birth-date check repeats on the next start.
- **Data on the device is per account.** Each user has their own database file (`moneylens_<user id>.sqlite`), so signing in as someone else shows none of the previous account's data; signing out keeps the file. The shared database from before accounts existed goes to the first account that signs in after the update. While signed out the app uses an empty in-memory database. Files are not encrypted, and "delete all data" only clears the signed-in account.

## CSV export

Settings → ข้อมูลและการส่งออก: choose a period (this month, last 3 months, this year, all) and **ส่งออก CSV**. The file is built on the device from the local database and handed to the system share sheet (Save to Files, e-mail, Drive, ...). Format: UTF-8 with a byte order mark (so Excel shows Thai correctly), CRLF, quoted fields, dates as Gregorian `YYYY-MM-DD` in Asia/Bangkok, amounts as plain decimals (always positive; the type column gives the direction). Text starting with `=`, `+`, `-`, `@` is prefixed with `'` so spreadsheets do not run it as a formula. Provider references and slip image paths are not exported. The temporary file is deleted at the next export.

## Account deletion

Settings → profile card → **ลบบัญชี** deletes the account on Supabase through the `delete_my_account()` function (every table cascades from `auth.users`) and then removes this device's database file and slip images. It needs an internet connection and asks twice; if the server cannot be reached nothing is deleted. The Google account itself is untouched. Slip image *objects* in Supabase Storage are not handled yet because nothing uploads them (PR-12).

## Sync

Entries (accounts, categories, transactions) are backed up to Supabase and shared between a user's devices while signed in; see [SYNC.md](SYNC.md). The device database stays the primary one, so the app works offline and syncs when it can. Slip images and scan records are not synced yet. Status and a "sync now" button are on Settings → profile card. Sync is off when no `SUPABASE_PUBLISHABLE_KEY` is passed.

## Database migrations

The schema is at version 3, and its snapshots are in `drift_schemas/`. See [lib/infrastructure/database/migrations/README.md](lib/infrastructure/database/migrations/README.md). In short: bump `schemaVersion`, run `dart run drift_dev make-migrations`, write the step, and test it.

## Dependencies

| Package | Why |
|---|---|
| `flutter_riverpod` | State management and dependency injection (ARCHITECTURE.md §2) |
| `go_router` | Navigation; the shell uses `StatefulShellRoute` |
| `drift`, `drift_flutter` | Typed SQLite, migrations, and the on-device DB location |
| `image_picker` | Camera and Gallery/Photos import with one package |
| `path_provider` | App-private directory for imported slip images |
| `crypto` | SHA-256 image fingerprint for exact re-import detection |
| `uuid` | TEXT/UUID primary keys |
| `intl`, `flutter_localizations` | Formatting and Thai/English localization |
| dev: `build_runner`, `drift_dev` | Code generation and schema dumps |
| dev: `integration_test` | On-device smoke test |

The following are deliberately **not added yet**. `fl_chart` waits until a chart exists. `flutter_secure_storage` waits until a secret exists. No Share Sheet intake package has been chosen (see the limitations below).

## Known limitations (not implemented yet)

- **OCR accuracy on Android:** Tesseract misreads some dates (for example a month abbreviation) and amounts on slips with a dark header. A wrong value that parses cleanly is not always flagged, so the review screen is mandatory. Apple Vision is more accurate but not yet verified inside the iOS app.
- **Extraction:** heuristics for Thai transfer and bill slips from KBank, SCB, Krungthai, KKP, TTB, GSB and similar layouts. Unknown layouts fall back to blank fields.
- **Share Sheet:** not wired. Android needs an `ACTION_SEND` intent filter. iOS needs a Share Extension target and an App Group. `UnavailableShareSheetSource` emits nothing, but the app already sends whatever it emits through the shared pipeline.
- **Automatic photo discovery:** not attempted. It is a validation gate (PROJECT.md SL-12), and `ImportSource.discovery` is reserved.
- **Duplicate detection:** only exact image fingerprints are checked. Provider-reference and transaction-fingerprint layers are planned for week 8.
- **Camera and gallery** import has run on an Android emulator only, not on a physical device or iOS.
- **Release builds** need the `INTERNET` permission in the main Android manifest (added); debug builds get it automatically.
