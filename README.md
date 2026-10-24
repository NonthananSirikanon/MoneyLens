# MoneyLens

Offline-first personal finance app for iOS and Android. Payment slips are imported, read with OCR, and turned into transactions that the user must review before they are saved.

This is the **initial scaffold** (ROADMAP week 1). The product, architecture, database, and plan documents are the source of truth:
[PROJECT.md](PROJECT.md) · [ARCHITECTURE.md](ARCHITECTURE.md) · [DATABASE.md](DATABASE.md) · [ROADMAP.md](ROADMAP.md)

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

## Database migrations

The schema is at version 1, and its snapshot is in `drift_schemas/`. See [lib/infrastructure/database/migrations/README.md](lib/infrastructure/database/migrations/README.md). In short: bump `schemaVersion`, run `dart run drift_dev make-migrations`, write the step, and test it.

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

The following are deliberately **not added yet**. `fl_chart` waits until a chart exists. `flutter_secure_storage` waits until a secret exists. No Share Sheet intake package or OCR engine has been chosen (see the limitations below).

## Known limitations (not implemented yet)

- **OCR:** `UnavailableOcrService` is a placeholder. Every import ends in a visible, retryable `failed` state with "Text recognition is not available yet". The OCR engine is chosen in the ROADMAP week 2 spike, and the engine binding goes in `ocrServiceProvider`.
- **Extraction:** `EmptyExtractionService` returns no fields, so the review step will ask the user to fill in everything.
- **Share Sheet:** not wired. Android needs an `ACTION_SEND` intent filter. iOS needs a Share Extension target and an App Group. `UnavailableShareSheetSource` emits nothing, but the app already sends whatever it emits through the shared pipeline.
- **Automatic photo discovery:** not attempted. It is a validation gate (PROJECT.md SL-12), and `ImportSource.discovery` is reserved.
- **Review/confirm screen, manual-entry form, account and category management, period picker, CSV:** not built. The use cases behind them (`CreateTransaction`, `ConfirmScan`, validators) exist and are tested.
- **Duplicate detection:** only exact image fingerprints are checked. Provider-reference and transaction-fingerprint layers are planned for week 8.
- **Camera and gallery** have been built but not exercised on a physical device. Only the simulator smoke test has run.
