import '../../accounts/domain/account_repository.dart';
import '../../categories/domain/category_repository.dart';
import '../domain/transaction.dart';
import '../domain/transaction_validator.dart';

/// Loads the records a draft references and validates it against the
/// business rules. Shared by manual entry and scan confirmation so both
/// paths enforce identical rules.
class TransactionDraftChecker {
  const TransactionDraftChecker(this._accounts, this._categories);

  static const _validator = TransactionValidator();

  final AccountRepository _accounts;
  final CategoryRepository _categories;

  /// Throws [InvalidTransactionException] when the draft breaks a rule.
  Future<void> ensureValid(TransactionDraft draft) async {
    final account = await _accounts.findById(draft.accountId);
    final destinationId = draft.destinationAccountId;
    final destination = destinationId == null
        ? null
        : await _accounts.findById(destinationId);
    final categoryId = draft.categoryId;
    final category = categoryId == null
        ? null
        : await _categories.findById(categoryId);

    final issues = _validator.validate(
      draft,
      TransactionReferences(
        accountCurrencyCode: account?.currency.code,
        destinationCurrencyCode: destination?.currency.code,
        categoryKind: category?.kind,
      ),
    );
    if (issues.isNotEmpty) throw InvalidTransactionException(issues);
  }
}
