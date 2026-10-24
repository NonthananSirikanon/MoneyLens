import '../../../core/dates/date_range.dart';
import 'transaction.dart';

abstract interface class TransactionRepository {
  /// Most recent first.
  Stream<List<MoneyTransaction>> watchRecent({int limit = 50});

  /// Transactions whose `occurredAt` falls within [range].
  Stream<List<MoneyTransaction>> watchInRange(DateRange range);

  /// Inserts an already-validated draft.
  Future<MoneyTransaction> create(TransactionDraft draft);

  /// Atomically creates the transaction for [scanRecordId] and marks the
  /// scan confirmed.
  ///
  /// Idempotent: repeating the call for the same scan returns the existing
  /// transaction with [ConfirmResult.alreadyConfirmed] set, and never
  /// inserts a second row.
  Future<ConfirmResult> confirmFromScan({
    required String scanRecordId,
    required TransactionDraft draft,
  });
}
