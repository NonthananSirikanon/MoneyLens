import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/features/categories/domain/category.dart';
import 'package:moneylens/features/transactions/domain/transaction.dart';
import 'package:moneylens/features/transactions/domain/transaction_type.dart';
import 'package:moneylens/features/transactions/domain/transaction_validator.dart';

import '../support/test_support.dart';

void main() {
  const validator = TransactionValidator();
  final at = DateTime.utc(2026, 10, 1);

  TransactionDraft draft({
    TransactionType type = TransactionType.expense,
    int minor = 1000,
    String accountId = 'a',
    String? destinationAccountId,
    String? categoryId,
  }) => TransactionDraft(
    type: type,
    amount: thb(minor),
    accountId: accountId,
    destinationAccountId: destinationAccountId,
    categoryId: categoryId,
    occurredAt: at,
  );

  const thbAccounts = TransactionReferences(
    accountCurrencyCode: 'THB',
    destinationCurrencyCode: 'THB',
  );

  test('accepts a valid expense with a matching category', () {
    final issues = validator.validate(
      draft(categoryId: 'food'),
      const TransactionReferences(
        accountCurrencyCode: 'THB',
        categoryKind: CategoryKind.expense,
      ),
    );
    expect(issues, isEmpty);
  });

  test('rejects zero and negative amounts', () {
    for (final minor in [0, -1]) {
      expect(
        validator.validate(draft(minor: minor), thbAccounts),
        contains(TransactionIssue.nonPositiveAmount),
      );
    }
  });

  test('rejects a missing account', () {
    expect(
      validator.validate(draft(), const TransactionReferences()),
      contains(TransactionIssue.accountNotFound),
    );
  });

  group('transfer rules (PROJECT.md TX-07)', () {
    test('accepts distinct source and destination', () {
      expect(
        validator.validate(
          draft(type: TransactionType.transfer, destinationAccountId: 'b'),
          thbAccounts,
        ),
        isEmpty,
      );
    });

    test('requires a destination', () {
      expect(
        validator.validate(draft(type: TransactionType.transfer), thbAccounts),
        [TransactionIssue.transferMissingDestination],
      );
    });

    test('rejects the same account on both sides', () {
      expect(
        validator.validate(
          draft(type: TransactionType.transfer, destinationAccountId: 'a'),
          thbAccounts,
        ),
        [TransactionIssue.transferSameAccount],
      );
    });

    test('rejects a category, so a transfer cannot pose as income/expense', () {
      expect(
        validator.validate(
          draft(
            type: TransactionType.transfer,
            destinationAccountId: 'b',
            categoryId: 'food',
          ),
          thbAccounts,
        ),
        [TransactionIssue.transferHasCategory],
      );
    });

    test('rejects an unknown destination account', () {
      expect(
        validator.validate(
          draft(type: TransactionType.transfer, destinationAccountId: 'b'),
          const TransactionReferences(accountCurrencyCode: 'THB'),
        ),
        [TransactionIssue.destinationAccountNotFound],
      );
    });
  });

  test('income/expense must not have a destination account', () {
    expect(
      validator.validate(
        draft(type: TransactionType.income, destinationAccountId: 'b'),
        thbAccounts,
      ),
      [TransactionIssue.nonTransferHasDestination],
    );
  });

  test('category kind must match the transaction type', () {
    expect(
      validator.validate(
        draft(type: TransactionType.income, categoryId: 'food'),
        const TransactionReferences(
          accountCurrencyCode: 'THB',
          categoryKind: CategoryKind.expense,
        ),
      ),
      [TransactionIssue.categoryKindMismatch],
    );
  });

  test('account currency must match the amount currency', () {
    expect(
      validator.validate(
        draft(),
        const TransactionReferences(accountCurrencyCode: 'USD'),
      ),
      [TransactionIssue.currencyMismatch],
    );
  });
}
