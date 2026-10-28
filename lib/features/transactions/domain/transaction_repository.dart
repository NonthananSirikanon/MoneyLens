import '../../../core/dates/date_range.dart';
import 'transaction.dart';

abstract interface class TransactionRepository {
  /// Most recent first.
  Stream<List<MoneyTransaction>> watchRecent({int limit = 50});

  /// Every transaction, newest first. Used for balances and reports.
  Stream<List<MoneyTransaction>> watchAll();

  Future<MoneyTransaction?> findById(String id);

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

  /// Replaces the editable fields of an existing transaction with an
  /// already-validated [draft]. Keeps its id, source, scan link, attachment
  /// and creation time. Throws `AppFailure(notFound)` for an unknown id.
  Future<MoneyTransaction> update(String id, TransactionDraft draft);

  /// Permanently deletes a transaction. A scan that produced it stays
  /// confirmed but loses its link (`transaction_id` is set to null).
  Future<void> delete(String id);
}
