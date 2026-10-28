import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/clock.dart';
import '../../../core/utils/id_generator.dart';
import '../../../infrastructure/database/app_database.dart';
import '../../../core/money/money.dart';
import '../../transactions/application/transaction_providers.dart';
import '../data/drift_account_repository.dart';
import '../domain/account_balance.dart';
import '../domain/account.dart';
import '../domain/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => DriftAccountRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  ),
);

final activeAccountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountRepositoryProvider).watchActive(),
);

/// Balance per active account id, recomputed whenever accounts or
/// transactions change.
final accountBalancesProvider = Provider<AsyncValue<Map<String, Money>>>((ref) {
  final accounts = ref.watch(activeAccountsProvider);
  final transactions = ref.watch(allTransactionsProvider);
  if (accounts.hasError) {
    return AsyncError(accounts.error!, accounts.stackTrace!);
  }
  if (transactions.hasError) {
    return AsyncError(transactions.error!, transactions.stackTrace!);
  }
  final a = accounts.value;
  final t = transactions.value;
  if (a == null || t == null) return const AsyncLoading();
  return AsyncData(const AccountBalanceCalculator().balances(a, t));
});
