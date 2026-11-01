import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../slip_import/application/slip_queue.dart';
import '../domain/transaction_type.dart';
import 'transaction_input.dart';
import 'transaction_providers.dart';

/// Writes to the transaction table. Every write has reloaded
/// [allTransactionsProvider] by the time it returns, so the caller can read
/// (or navigate to) the result at once.
class TransactionActions {
  const TransactionActions(this._ref);

  final Ref _ref;

  /// Saves a new transaction and returns its id. When the input came from a
  /// reviewed slip ([TransactionInput.scanId] names a queued scan) the slip
  /// queue saves it and confirms the scan; otherwise it is a manual entry.
  Future<String> add(TransactionInput input) async {
    final queue = _ref.read(slipQueueProvider.notifier);
    final scan = _ref.read(slipQueueProvider).scan(input.scanId);
    final String id;
    if (scan != null) {
      id = await queue.saveReviewed(
        scan,
        input.toDraft(source: TransactionSource.ocr),
      );
    } else {
      final tx = await _ref
          .read(createTransactionProvider)
          .call(input.toDraft(source: TransactionSource.manual));
      id = tx.id;
    }
    await reloadTransactions(_ref);
    return id;
  }

  Future<void> update(String id, TransactionInput input) async {
    final old = await _ref.read(transactionRepositoryProvider).findById(id);
    await _ref
        .read(updateTransactionProvider)
        .call(
          id,
          input.toDraft(
            source: old?.source ?? TransactionSource.manual,
            attachmentPath: old?.attachmentPath,
          ),
        );
    await reloadTransactions(_ref);
  }

  Future<void> delete(String id) async {
    await _ref.read(transactionRepositoryProvider).delete(id);
    await reloadTransactions(_ref);
  }
}

final transactionActionsProvider = Provider<TransactionActions>(
  TransactionActions.new,
);
