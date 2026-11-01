import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/application/account_providers.dart';
import '../../accounts/domain/account.dart';
import '../../accounts/domain/account_balance.dart';
import '../../accounts/application/account_details.dart';
import '../../categories/application/category_providers.dart';
import '../../categories/domain/category.dart';
import '../../categories/application/category_style.dart';
import '../../transactions/application/transaction_providers.dart';
import '../../transactions/domain/transaction.dart';

/// A read-only view of the ledger as the database streams last reported it:
/// transactions (newest first), active accounts and active categories, with
/// the lookups and balances screens need.
///
/// It holds no state of its own: it is rebuilt from the stream providers, so
/// a write that reloads them (see `reloadTransactions`) is visible here as
/// soon as the reload returns.
class Ledger {
  Ledger({
    this.transactions = const [],
    this.accounts = const [],
    this.categories = const [],
  });

  /// Newest first.
  final List<MoneyTransaction> transactions;
  final List<Account> accounts;
  final List<Category> categories;

  /// Row labels and tints for [accounts], by account id.
  late final Map<String, AccountDetails> accountDetails = {
    for (final a in accounts) a.id: AccountDetails.of(a),
  };

  /// Icon tints and chart colours for [categories], by category id.
  late final Map<String, CategoryStyle> categoryStyles = {
    for (final c in categories) c.id: CategoryStyle.of(c),
  };

  static const _balances = AccountBalanceCalculator();

  Account? account(String? id) {
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Category? category(String? id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  MoneyTransaction? transaction(String? id) {
    for (final t in transactions) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Opening balance plus the effect of every transaction (minor units).
  /// Transfers only move money between the two accounts.
  int balanceOf(String accountId) {
    var balance = account(accountId)?.openingBalanceMinor ?? 0;
    for (final t in transactions) {
      balance += _balances.effect(t, accountId);
    }
    return balance;
  }

  int get totalBalance => accounts.fold(0, (sum, a) => sum + balanceOf(a.id));
}

/// The ledger the streams last delivered; empty until they first emit (app
/// startup waits for that, so screens never see the empty state by mistake).
final ledgerProvider = Provider<Ledger>(
  (ref) => Ledger(
    transactions: ref.watch(allTransactionsProvider).value ?? const [],
    accounts: ref.watch(activeAccountsProvider).value ?? const [],
    categories: ref.watch(activeCategoriesProvider).value ?? const [],
  ),
);
