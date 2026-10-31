import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/reporting_time_zone.dart';
import '../../../app/app_state.dart';
import '../../../demo/demo_scenario.dart';
import '../../../app/app_store.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../domain/transaction.dart';
import '../domain/transaction_type.dart';

/// Everything a row, the detail screen or a dialog needs about one
/// transaction, resolved against the current categories and accounts.
@immutable
class TransactionView {
  const TransactionView({
    required this.transaction,
    required this.category,
    required this.categoryTint,
    required this.account,
    required this.accountDetails,
    required this.destination,
    required this.destinationDetails,
    required this.wallClock,
  });

  final MoneyTransaction transaction;
  final Category? category;
  final Color? categoryTint;
  final Account? account;
  final AccountDetails? accountDetails;
  final Account? destination;
  final AccountDetails? destinationDetails;

  /// `occurredAt` as Bangkok wall-clock time.
  final DateTime wallClock;

  String get id => transaction.id;
  TransactionType get type => transaction.type;
  bool get isTransfer => type == TransactionType.transfer;
  bool get hasSlip => transaction.attachmentPath != null;
  String get title => transaction.merchant ?? '';
}

/// Resolves [t] against [state].
TransactionView transactionViewOf(AppState state, MoneyTransaction t) =>
    TransactionView(
      transaction: t,
      category: state.category(t.categoryId),
      categoryTint: state.categoryStyles[t.categoryId]?.tint,
      account: state.account(t.accountId),
      accountDetails: state.accountDetails[t.accountId],
      destination: state.account(t.destinationAccountId),
      destinationDetails: state.accountDetails[t.destinationAccountId],
      wallClock: ReportingTimeZone.bangkok.wallClock(t.occurredAt),
    );

/// Transactions grouped by Bangkok calendar day, newest day first.
@immutable
class TransactionDayGroup {
  const TransactionDayGroup({
    required this.day,
    required this.rows,
    required this.expenseMinor,
  });

  /// Wall-clock date (time fields zero).
  final DateTime day;
  final List<TransactionView> rows;

  /// Sum of expenses that day; transfers and income are excluded.
  final int expenseMinor;
}

/// Search text, type tab and category filter on the Transactions tab.
@immutable
class TransactionFilter {
  const TransactionFilter({this.query = '', this.type, this.categoryId});

  final String query;

  /// Null means "all".
  final TransactionType? type;
  final String? categoryId;

  bool get isActive =>
      query.trim().isNotEmpty || type != null || categoryId != null;
}

class TransactionFilterController extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => const TransactionFilter();

  void setQuery(String query) => state = TransactionFilter(
    query: query,
    type: state.type,
    categoryId: state.categoryId,
  );

  /// Picking "transfer" clears the category filter (transfers have none).
  void setType(TransactionType? type) => state = TransactionFilter(
    query: state.query,
    type: type,
    categoryId: type == TransactionType.transfer ? null : state.categoryId,
  );

  /// A category implies its type; clearing it leaves expense/income tabs as
  /// they are but drops a transfer tab, matching the prototype.
  void setCategory(Category? category) => state = TransactionFilter(
    query: state.query,
    type: category == null
        ? (state.type == TransactionType.transfer ? null : state.type)
        : (category.kind == CategoryKind.income
              ? TransactionType.income
              : TransactionType.expense),
    categoryId: category?.id,
  );

  /// Opened from the Categories screen: show only that category.
  void showCategory(Category category) => state = TransactionFilter(
    type: category.kind == CategoryKind.income
        ? TransactionType.income
        : TransactionType.expense,
    categoryId: category.id,
  );
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterController, TransactionFilter>(
      TransactionFilterController.new,
    );

enum TransactionLoadStatus { loading, ready, error }

/// Simulated first load of the transaction list (700ms skeleton), and the
/// DB_READ_FAILED error when the `dbError` demo scenario is active.
class TransactionLoadController extends Notifier<TransactionLoadStatus> {
  Timer? _timer;
  var _retried = false;

  static const loadDelay = Duration(milliseconds: 700);

  @override
  TransactionLoadStatus build() {
    ref.onDispose(() => _timer?.cancel());
    _schedule();
    return TransactionLoadStatus.loading;
  }

  void retry() {
    _retried = true;
    state = TransactionLoadStatus.loading;
    _schedule();
  }

  void _schedule() {
    final scenario = ref.read(demoScenarioProvider);
    if (scenario == DemoScenario.loading) return;
    _timer?.cancel();
    _timer = Timer(loadDelay, () {
      state = scenario == DemoScenario.dbError && !_retried
          ? TransactionLoadStatus.error
          : TransactionLoadStatus.ready;
    });
  }
}

final transactionLoadProvider =
    NotifierProvider<TransactionLoadController, TransactionLoadStatus>(
      TransactionLoadController.new,
    );

/// The filtered list, grouped by day.
final transactionGroupsProvider = Provider<List<TransactionDayGroup>>((ref) {
  final state = ref.watch(appStoreProvider);
  final filter = ref.watch(transactionFilterProvider);
  final q = filter.query.trim().toLowerCase();

  final groups = <DateTime, List<TransactionView>>{};
  for (final t in state.transactions) {
    if (filter.type != null && t.type != filter.type) continue;
    if (filter.categoryId != null && t.categoryId != filter.categoryId) {
      continue;
    }
    if (q.isNotEmpty &&
        !(t.merchant ?? '').toLowerCase().contains(q) &&
        !(t.note ?? '').toLowerCase().contains(q)) {
      continue;
    }
    final view = transactionViewOf(state, t);
    final w = view.wallClock;
    groups
        .putIfAbsent(DateTime.utc(w.year, w.month, w.day), () => [])
        .add(view);
  }
  final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final day in days)
      TransactionDayGroup(
        day: day,
        rows: groups[day]!,
        expenseMinor: groups[day]!
            .where((v) => v.type == TransactionType.expense)
            .fold(0, (sum, v) => sum + v.transaction.amount.minor),
      ),
  ];
});

/// One transaction by id, or null once deleted.
final transactionViewProvider = Provider.family<TransactionView?, String>((
  ref,
  id,
) {
  final state = ref.watch(appStoreProvider);
  final t = state.transaction(id);
  return t == null ? null : transactionViewOf(state, t);
});

/// The four most recent transactions for Home.
final recentTransactionViewsProvider = Provider<List<TransactionView>>((ref) {
  final state = ref.watch(appStoreProvider);
  return [
    for (final t in state.transactions.take(4)) transactionViewOf(state, t),
  ];
});

/// Whether any transaction exists at all (distinguishes "empty" from "no
/// matches").
final hasTransactionsProvider = Provider<bool>(
  (ref) => ref.watch(appStoreProvider).transactions.isNotEmpty,
);
