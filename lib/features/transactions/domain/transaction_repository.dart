import '../../../core/dates/date_range.dart';
import 'transaction.dart';

abstract interface class TransactionRepository {
  /// Most recent first.
  Stream<List<MoneyTransaction>> watchRecent({int limit = 50});

  /// Every transaction, newest first. Used for balances and reports.
  Stream<List<MoneyTransaction>> watchAll();

  /// One-shot read of every transaction, newest first.
  Future<List<MoneyTransaction>> findAll();

  Future<MoneyTransaction?> findById(String id);

  /// Every transaction that has a provider reference, in no set order.
  /// Used to spot a slip that was already saved.
  ///
  /// Transactions are hard-deleted today. If sync ever adds soft delete
  /// (a `deleted_at` marker), this must skip deleted rows, or a deleted
  /// payment would keep blocking its slip.
  Future<List<MoneyTransaction>> findWithProviderReference();

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
