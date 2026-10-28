import '../domain/transaction.dart';
import '../domain/transaction_repository.dart';
import 'transaction_draft_checker.dart';

/// Editing a transaction: validate with the same rules as creation, then
/// persist. Source, scan link and attachment are kept by the repository.
class UpdateTransaction {
  const UpdateTransaction(this._checker, this._repository);

  final TransactionDraftChecker _checker;
  final TransactionRepository _repository;

  Future<MoneyTransaction> call(String id, TransactionDraft draft) async {
    await _checker.ensureValid(draft);
    return _repository.update(id, draft);
  }
}
