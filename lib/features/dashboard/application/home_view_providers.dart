import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/clock.dart';
import '../../../core/dates/reporting_time_zone.dart';
import '../../../demo/demo_models.dart';
import '../../../demo/demo_store.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction_type.dart';

/// Income, expense and transfer totals for the current month, in minor
/// units. Transfers are reported separately and never counted as income or
/// expense.
@immutable
class MonthTotals {
  const MonthTotals({
    required this.income,
    required this.expense,
    required this.transfers,
    required this.expenseByCategory,
    required this.incomeByCategory,
  });

  final int income;
  final int expense;
  final int transfers;
  final Map<String, int> expenseByCategory;
  final Map<String, int> incomeByCategory;
}

/// The demo baseline plus every transaction added this session that falls
/// in the current Bangkok month (the prototype's `BASE + sessionTx`).
MonthTotals currentMonthTotals(DemoState s, DateTime nowUtc) {
  final month = ReportingTimeZone.bangkok.monthContaining(nowUtc);
  var income = s.baseline.income;
  var expense = s.baseline.expense;
  var transfers = s.baseline.transfers;
  final byExpense = {...s.baseline.expenseByCategory};
  final byIncome = {...s.baseline.incomeByCategory};
  for (final t in s.transactions) {
    if (s.seedTransactionIds.contains(t.id) || !month.contains(t.occurredAt)) {
      continue;
    }
    final amount = t.amount.minor;
    switch (t.type) {
      case TransactionType.income:
        income += amount;
        byIncome.update(
          t.categoryId!,
          (v) => v + amount,
          ifAbsent: () => amount,
        );
      case TransactionType.expense:
        expense += amount;
        byExpense.update(
          t.categoryId!,
          (v) => v + amount,
          ifAbsent: () => amount,
        );
      case TransactionType.transfer:
        transfers += amount;
    }
  }
  return MonthTotals(
    income: income,
    expense: expense,
    transfers: transfers,
    expenseByCategory: byExpense,
    incomeByCategory: byIncome,
  );
}

final monthTotalsProvider = Provider<MonthTotals>(
  (ref) => currentMonthTotals(
    ref.watch(demoStoreProvider),
    ref.watch(clockProvider).nowUtc(),
  ),
);

/// Number of transactions per category (seed counts plus session entries).
final categoryCountsProvider = Provider<Map<String, int>>((ref) {
  final s = ref.watch(demoStoreProvider);
  final counts = {...s.categorySeedCounts};
  for (final t in s.transactions) {
    if (s.seedTransactionIds.contains(t.id) || t.categoryId == null) continue;
    counts.update(t.categoryId!, (v) => v + 1, ifAbsent: () => 1);
  }
  return counts;
});

/// One row of "หมวดใช้จ่ายสูงสุด".
@immutable
class TopCategory {
  const TopCategory({
    required this.category,
    required this.style,
    required this.amount,
    required this.shareOfTop,
    required this.shareOfTotal,
    required this.count,
  });

  final Category category;
  final CategoryStyle? style;
  final int amount;

  /// Bar length relative to the biggest category (0–1).
  final double shareOfTop;

  /// Share of all expenses this month (0–1).
  final double shareOfTotal;
  final int count;
}

final topCategoriesProvider = Provider<List<TopCategory>>((ref) {
  final s = ref.watch(demoStoreProvider);
  final totals = ref.watch(monthTotalsProvider);
  final counts = ref.watch(categoryCountsProvider);
  final entries =
      totals.expenseByCategory.entries
          .where((e) => e.value > 0 && s.category(e.key) != null)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
  if (entries.isEmpty) return const [];
  final top = entries.first.value;
  final all = entries.fold(0, (sum, e) => sum + e.value);
  return [
    for (final e in entries.take(3))
      TopCategory(
        category: s.category(e.key)!,
        style: s.categoryStyles[e.key],
        amount: e.value,
        shareOfTop: e.value / top,
        shareOfTotal: e.value / all,
        count: counts[e.key] ?? 0,
      ),
  ];
});

/// Spend per day of the current month (index 0 = the 1st), including
/// expenses added this session.
final dailySpendProvider = Provider<List<int>>((ref) {
  final s = ref.watch(demoStoreProvider);
  final now = ref.watch(clockProvider).nowUtc();
  final month = ReportingTimeZone.bangkok.monthContaining(now);
  final days = [...s.dailySpend];
  for (final t in s.transactions) {
    if (s.seedTransactionIds.contains(t.id) ||
        t.type != TransactionType.expense ||
        !month.contains(t.occurredAt)) {
      continue;
    }
    final day = ReportingTimeZone.bangkok.wallClock(t.occurredAt).day - 1;
    if (day >= 0 && day < days.length) days[day] += t.amount.minor;
  }
  return days;
});

/// The selected bar in "ใช้จ่ายรายวัน"; defaults to the biggest day.
class SelectedDayController extends Notifier<int> {
  @override
  int build() {
    final days = ref.read(dailySpendProvider);
    var best = 0;
    for (var i = 1; i < days.length; i++) {
      if (days[i] > days[best]) best = i;
    }
    return best;
  }

  void select(int index) => state = index;
}

final selectedDayProvider = NotifierProvider<SelectedDayController, int>(
  SelectedDayController.new,
);
