import 'package:drift/drift.dart';

import '../../../core/dates/clock.dart';
import '../../../core/dates/date_range.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../../core/utils/id_generator.dart';
import '../../../infrastructure/database/app_database.dart';
import '../../slip_import/domain/scan_status.dart';
import '../domain/transaction.dart';
import '../domain/transaction_repository.dart';
import '../domain/transaction_type.dart';

class DriftTransactionRepository implements TransactionRepository {
  DriftTransactionRepository(this._db, this._clock, this._ids);

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  @override
  Stream<List<MoneyTransaction>> watchRecent({int limit = 50}) {
    final query = _db.select(_db.transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)])
      ..limit(limit);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Stream<List<MoneyTransaction>> watchInRange(DateRange range) {
    final query = _db.select(_db.transactions)
      ..where(
        (t) =>
            t.occurredAt.isBiggerOrEqualValue(range.startUtc) &
            t.occurredAt.isSmallerThanValue(range.endUtc),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<MoneyTransaction> create(TransactionDraft draft) async {
    final now = _clock.nowUtc();
    final row = await _db
        .into(_db.transactions)
        .insertReturning(_companion(draft, id: _ids.newId(), now: now));
    return _toDomain(row);
  }

  @override
  Future<ConfirmResult> confirmFromScan({
    required String scanRecordId,
    required TransactionDraft draft,
  }) {
    return _db.transaction(() async {
      final existing = await (_db.select(
        _db.transactions,
      )..where((t) => t.scanRecordId.equals(scanRecordId))).getSingleOrNull();
      if (existing != null) {
        return ConfirmResult(
          transaction: _toDomain(existing),
          alreadyConfirmed: true,
        );
      }

      final scan = await (_db.select(
        _db.scanRecords,
      )..where((s) => s.id.equals(scanRecordId))).getSingleOrNull();
      if (scan == null) throw const AppFailure(FailureCode.notFound);
      if (!ScanStatus.fromDb(scan.status)
          .canTransitionTo(ScanStatus.confirmed)) {
        throw const AppFailure(FailureCode.invalidScanState);
      }

      final now = _clock.nowUtc();
      // The UNIQUE scan_record_id column rejects a concurrent second insert
      // even if it slipped past the lookup above.
      final row = await _db
          .into(_db.transactions)
          .insertReturning(
            _companion(draft, id: _ids.newId(), now: now).copyWith(
              source: Value(TransactionSource.ocr.dbValue),
              scanRecordId: Value(scanRecordId),
              attachmentPath: Value(scan.attachmentPath),
            ),
          );
      await (_db.update(
        _db.scanRecords,
      )..where((s) => s.id.equals(scanRecordId))).write(
        ScanRecordsCompanion(
          status: Value(ScanStatus.confirmed.dbValue),
          transactionId: Value(row.id),
          updatedAt: Value(now),
        ),
      );
      return ConfirmResult(
        transaction: _toDomain(row),
        alreadyConfirmed: false,
      );
    });
  }

  TransactionsCompanion _companion(
    TransactionDraft draft, {
    required String id,
    required DateTime now,
  }) => TransactionsCompanion.insert(
    id: id,
    type: draft.type.dbValue,
    amountMinor: draft.amount.minor,
    currencyCode: draft.amount.currency.code,
    accountId: draft.accountId,
    destinationAccountId: Value(draft.destinationAccountId),
    categoryId: Value(draft.categoryId),
    merchant: Value(draft.merchant),
    note: Value(draft.note),
    occurredAt: draft.occurredAt.toUtc(),
    source: draft.source.dbValue,
    providerReference: Value(draft.providerReference),
    createdAt: now,
    updatedAt: now,
  );

  static MoneyTransaction _toDomain(TransactionRow row) {
    final currency = Currency.tryFromCode(row.currencyCode);
    if (currency == null) {
      throw StateError('Stored transaction uses unsupported currency');
    }
    return MoneyTransaction(
      id: row.id,
      type: TransactionType.fromDb(row.type),
      amount: Money(row.amountMinor, currency),
      accountId: row.accountId,
      destinationAccountId: row.destinationAccountId,
      categoryId: row.categoryId,
      merchant: row.merchant,
      note: row.note,
      occurredAt: row.occurredAt.toUtc(),
      source: TransactionSource.fromDb(row.source),
      scanRecordId: row.scanRecordId,
      attachmentPath: row.attachmentPath,
      providerReference: row.providerReference,
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
    );
  }
}
