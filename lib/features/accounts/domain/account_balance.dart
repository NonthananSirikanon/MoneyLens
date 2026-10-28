import '../../../core/money/money.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';
import 'account.dart';

/// Account balances (DATABASE.md §3.1): never stored, always
/// `opening balance + effect of every confirmed transaction`.
///
/// Income adds, expense subtracts, and a transfer subtracts from its source
/// and adds to its destination, so transfers never change the total.
class AccountBalanceCalculator {
  const AccountBalanceCalculator();

  /// Balance of [account] in its own currency. Transactions in another
  /// currency are ignored.
  Money balanceOf(Account account, Iterable<MoneyTransaction> transactions) {
    var balance = Money(account.openingBalanceMinor ?? 0, account.currency);
    for (final tx in transactions) {
      if (tx.amount.currency != account.currency) continue;
      balance += Money(effect(tx, account.id), account.currency);
    }
    return balance;
  }

  /// Balance per account id.
  Map<String, Money> balances(
    Iterable<Account> accounts,
    Iterable<MoneyTransaction> transactions,
  ) {
    final all = transactions.toList();
    return {for (final a in accounts) a.id: balanceOf(a, all)};
  }

  /// The change [tx] makes to [accountId], in minor units.
  int effect(MoneyTransaction tx, String accountId) {
    final amount = tx.amount.minor;
    return switch (tx.type) {
      TransactionType.income => tx.accountId == accountId ? amount : 0,
      TransactionType.expense => tx.accountId == accountId ? -amount : 0,
      TransactionType.transfer =>
        (tx.accountId == accountId ? -amount : 0) +
            (tx.destinationAccountId == accountId ? amount : 0),
    };
  }
}
