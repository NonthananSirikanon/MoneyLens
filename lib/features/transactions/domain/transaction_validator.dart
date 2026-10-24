import '../../categories/domain/category.dart';
import 'transaction.dart';
import 'transaction_type.dart';

enum TransactionIssue {
  nonPositiveAmount,
  accountNotFound,
  destinationAccountNotFound,
  categoryNotFound,
  currencyMismatch,
  transferMissingDestination,
  transferSameAccount,
  transferHasCategory,
  nonTransferHasDestination,
  categoryKindMismatch,
}

/// Facts about referenced records that the validator needs but cannot load
/// itself. Kept separate so the rules stay pure and unit-testable.
class TransactionReferences {
  const TransactionReferences({
    this.accountCurrencyCode,
    this.destinationCurrencyCode,
    this.categoryKind,
  });

  /// `null` means the referenced account does not exist.
  final String? accountCurrencyCode;
  final String? destinationCurrencyCode;
  final CategoryKind? categoryKind;
}

/// Business rules for a transaction (DATABASE.md §3.3, PROJECT.md TX-05..07).
///
/// The database enforces the structural subset of these with CHECK
/// constraints as a second line of defence.
class TransactionValidator {
  const TransactionValidator();

  List<TransactionIssue> validate(
    TransactionDraft draft,
    TransactionReferences refs,
  ) {
    final issues = <TransactionIssue>[];
    final currencyCode = draft.amount.currency.code;

    if (!draft.amount.isPositive) {
      issues.add(TransactionIssue.nonPositiveAmount);
    }

    if (refs.accountCurrencyCode == null) {
      issues.add(TransactionIssue.accountNotFound);
    } else if (refs.accountCurrencyCode != currencyCode) {
      issues.add(TransactionIssue.currencyMismatch);
    }

    switch (draft.type) {
      case TransactionType.transfer:
        final destinationId = draft.destinationAccountId;
        if (destinationId == null) {
          issues.add(TransactionIssue.transferMissingDestination);
        } else if (destinationId == draft.accountId) {
          issues.add(TransactionIssue.transferSameAccount);
        } else if (refs.destinationCurrencyCode == null) {
          issues.add(TransactionIssue.destinationAccountNotFound);
        } else if (refs.destinationCurrencyCode != currencyCode &&
            !issues.contains(TransactionIssue.currencyMismatch)) {
          issues.add(TransactionIssue.currencyMismatch);
        }
        if (draft.categoryId != null) {
          issues.add(TransactionIssue.transferHasCategory);
        }
      case TransactionType.income || TransactionType.expense:
        if (draft.destinationAccountId != null) {
          issues.add(TransactionIssue.nonTransferHasDestination);
        }
        if (draft.categoryId != null) {
          final kind = refs.categoryKind;
          if (kind == null) {
            issues.add(TransactionIssue.categoryNotFound);
          } else if (!_categoryMatches(kind, draft.type)) {
            issues.add(TransactionIssue.categoryKindMismatch);
          }
        }
    }
    return issues;
  }

  static bool _categoryMatches(CategoryKind kind, TransactionType type) =>
      switch (type) {
        TransactionType.income => kind == CategoryKind.income,
        TransactionType.expense => kind == CategoryKind.expense,
        TransactionType.transfer => false,
      };
}

class InvalidTransactionException implements Exception {
  const InvalidTransactionException(this.issues);

  final List<TransactionIssue> issues;

  @override
  String toString() =>
      'InvalidTransactionException(${issues.map((i) => i.name).join(', ')})';
}
