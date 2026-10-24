import 'package:drift/drift.dart';

import 'accounts.dart';
import 'categories.dart';
import 'scan_records.dart';

/// DATABASE.md §3.3. Indexes follow §8.
///
/// `scan_record_id` is UNIQUE and is the source of truth for the
/// scan→transaction link, so a scan can never be confirmed twice even if
/// application checks are bypassed.
@DataClassName('TransactionRow')
@TableIndex(name: 'idx_transactions_occurred_at', columns: {#occurredAt})
@TableIndex(
  name: 'idx_transactions_type_occurred_at',
  columns: {#type, #occurredAt},
)
@TableIndex(
  name: 'idx_transactions_account_occurred_at',
  columns: {#accountId, #occurredAt},
)
@TableIndex(
  name: 'idx_transactions_category_occurred_at',
  columns: {#categoryId, #occurredAt},
)
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();
  @ReferenceName('sourceTransactions')
  TextColumn get accountId => text().references(Accounts, #id)();
  @ReferenceName('incomingTransfers')
  TextColumn get destinationAccountId =>
      text().nullable().references(Accounts, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get merchant => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get source => text()();
  TextColumn get scanRecordId => text().nullable().unique().references(
    ScanRecords,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get attachmentPath => text().nullable()();
  TextColumn get providerReference => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (type IN ('income', 'expense', 'transfer'))",
    'CHECK (amount_minor > 0)',
    "CHECK (source IN ('manual', 'ocr', 'import', 'recurring'))",
    // Transfers need a distinct destination and no category; income and
    // expense must not have a destination (DATABASE.md §3.3).
    "CHECK ((type = 'transfer' AND destination_account_id IS NOT NULL "
        'AND destination_account_id <> account_id AND category_id IS NULL) '
        "OR (type <> 'transfer' AND destination_account_id IS NULL))",
  ];
}
