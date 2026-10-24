import '../domain/transaction.dart';
import '../domain/transaction_repository.dart';
import 'transaction_draft_checker.dart';

/// Manual entry (PROJECT.md TX-01): validate the draft, then persist it.
class CreateTransaction {
  const CreateTransaction(this._checker, this._repository);

  final TransactionDraftChecker _checker;
  final TransactionRepository _repository;

  Future<MoneyTransaction> call(TransactionDraft draft) async {
    await _checker.ensureValid(draft);
    return _repository.create(draft);
  }
}
