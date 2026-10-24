import '../../../core/dates/date_range.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_type.dart';

class PeriodSummary {
  const PeriodSummary({
    required this.range,
    required this.income,
    required this.expense,
    required this.transferCount,
  });

  final DateRange range;
  final Money income;
  final Money expense;

  /// Shown separately; transfers never change [income] or [expense].
  final int transferCount;

  /// Income minus expense, excluding transfers (DATABASE.md §7).
  Money get net => income - expense;
}

/// The single place dashboard totals are computed, so screens cannot drift
/// apart (ARCHITECTURE.md §8).
class SummaryCalculator {
  const SummaryCalculator();

  PeriodSummary summarize(
    Iterable<MoneyTransaction> transactions,
    DateRange range, {
    Currency currency = Currency.thb,
  }) {
    var income = Money.zero(currency);
    var expense = Money.zero(currency);
    var transfers = 0;

    for (final tx in transactions) {
      if (!range.contains(tx.occurredAt) || tx.amount.currency != currency) {
        continue;
      }
      switch (tx.type) {
        case TransactionType.income:
          income += tx.amount;
        case TransactionType.expense:
          expense += tx.amount;
        case TransactionType.transfer:
          transfers++;
      }
    }
    return PeriodSummary(
      range: range,
      income: income,
      expense: expense,
      transferCount: transfers,
    );
  }
}
