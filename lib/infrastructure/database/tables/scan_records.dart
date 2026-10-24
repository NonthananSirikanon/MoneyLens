import 'package:drift/drift.dart';

import 'transactions.dart';

/// DATABASE.md §3.4. Indexes follow §8.
///
/// `transaction_id` mirrors `transactions.scan_record_id` for lookups. It is
/// written in the same database transaction as the confirmation; the
/// UNIQUE column on `transactions` stays authoritative.
@DataClassName('ScanRecordRow')
@TableIndex(
  name: 'idx_scan_records_status_created_at',
  columns: {#status, #createdAt},
)
@TableIndex(
  name: 'idx_scan_records_image_fingerprint',
  columns: {#imageFingerprint},
)
class ScanRecords extends Table {
  TextColumn get id => text()();
  TextColumn get source => text()();
  TextColumn get attachmentPath => text().nullable()();
  TextColumn get imageFingerprint => text().nullable()();

  /// Sensitive OCR text. The scaffold pipeline never writes it; any future
  /// use needs a documented retention policy (DATABASE.md §9).
  TextColumn get rawText => text().nullable()();

  /// Versioned JSON of extracted fields with per-field confidence.
  TextColumn get extractedPayload => text().nullable()();
  TextColumn get status => text()();
  TextColumn get failureCode => text().nullable()();
  TextColumn get failureMessage => text().nullable()();
  TextColumn get duplicateOfScanId => text().nullable().references(
    ScanRecords,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get transactionId => text().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get processorVersion => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get processedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (source IN ('camera', 'gallery', 'share_sheet', 'discovery'))",
    "CHECK (status IN ('queued', 'processing', 'needs_review', 'confirmed', "
        "'duplicate', 'failed', 'discarded'))",
  ];
}
