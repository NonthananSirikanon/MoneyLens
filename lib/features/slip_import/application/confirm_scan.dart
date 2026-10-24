import '../../transactions/application/transaction_draft_checker.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_repository.dart';

/// The user confirms a reviewed scan as a transaction.
///
/// Uses the same validation as manual entry. Idempotent: confirming the
/// same scan twice returns the existing transaction (PROJECT.md PR-05).
class ConfirmScan {
  const ConfirmScan(this._checker, this._transactions);

  final TransactionDraftChecker _checker;
  final TransactionRepository _transactions;

  Future<ConfirmResult> call({
    required String scanId,
    required TransactionDraft reviewedDraft,
  }) async {
    await _checker.ensureValid(reviewedDraft);
    return _transactions.confirmFromScan(
      scanRecordId: scanId,
      draft: reviewedDraft,
    );
  }
}
