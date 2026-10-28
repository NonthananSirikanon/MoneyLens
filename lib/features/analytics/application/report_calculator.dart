import '../../../core/dates/date_range.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';

/// Totals in minor units for one period. Transfers are reported on their
/// own and never counted as income or expense (DATABASE.md §7).
class PeriodTotals {
  const PeriodTotals({
    required this.income,
    required this.expense,
    required this.transfers,
    required this.expenseByCategory,
    required this.incomeByCategory,
  });

  final int income;
  final int expense;
  final int transfers;

  /// Category id → minor units. Uncategorised entries are omitted.
  final Map<String, int> expenseByCategory;
  final Map<String, int> incomeByCategory;

  int get net => income - expense;
}

/// Category breakdowns and month-by-month trends, computed from confirmed
/// transactions only. Single-currency (THB) for the MVP.
class ReportCalculator {
  const ReportCalculator();

  PeriodTotals totals(
    Iterable<MoneyTransaction> transactions,
    DateRange range,
  ) {
    var income = 0;
    var expense = 0;
    var transfers = 0;
    final byExpense = <String, int>{};
    final byIncome = <String, int>{};
    for (final tx in transactions) {
      if (!range.contains(tx.occurredAt)) continue;
      final amount = tx.amount.minor;
      switch (tx.type) {
        case TransactionType.income:
          income += amount;
          final id = tx.categoryId;
          if (id != null) {
            byIncome.update(id, (v) => v + amount, ifAbsent: () => amount);
          }
        case TransactionType.expense:
          expense += amount;
          final id = tx.categoryId;
          if (id != null) {
            byExpense.update(id, (v) => v + amount, ifAbsent: () => amount);
          }
        case TransactionType.transfer:
          transfers += amount;
      }
    }
    return PeriodTotals(
      income: income,
      expense: expense,
      transfers: transfers,
      expenseByCategory: byExpense,
      incomeByCategory: byIncome,
    );
  }

  /// One [PeriodTotals] per range, in the order given (e.g. the last six
  /// months, oldest first).
  List<PeriodTotals> trend(
    Iterable<MoneyTransaction> transactions,
    List<DateRange> ranges,
  ) {
    final all = transactions.toList();
    return [for (final r in ranges) totals(all, r)];
  }

  /// Expense per day within [range], indexed from the range start, in
  /// [dayCount] buckets, using [dayOf] to convert an instant to a day offset.
  List<int> dailyExpense(
    Iterable<MoneyTransaction> transactions,
    DateRange range, {
    required int dayCount,
    required int Function(DateTime instant) dayOf,
  }) {
    final days = List<int>.filled(dayCount, 0);
    for (final tx in transactions) {
      if (tx.type != TransactionType.expense ||
          !range.contains(tx.occurredAt)) {
        continue;
      }
      final i = dayOf(tx.occurredAt);
      if (i >= 0 && i < dayCount) days[i] += tx.amount.minor;
    }
    return days;
  }
}
