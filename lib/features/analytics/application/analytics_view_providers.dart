import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/clock.dart';
import '../../../core/dates/reporting_time_zone.dart';
import '../../../demo/demo_store.dart';
import 'report_calculator.dart';

enum AnalyticsTab { breakdown, trend }

enum AnalyticsMode { expense, income }

@immutable
class AnalyticsUiState {
  const AnalyticsUiState({
    this.tab = AnalyticsTab.breakdown,
    this.periodIndex = 0,
    this.mode = AnalyticsMode.expense,
    this.trendIndex,
  });

  final AnalyticsTab tab;

  /// Months before the current one that the breakdown shows: 0 = this month.
  final int periodIndex;
  final AnalyticsMode mode;

  /// Selected month in the trend chart; null = the latest.
  final int? trendIndex;

  AnalyticsUiState copyWith({
    AnalyticsTab? tab,
    int? periodIndex,
    AnalyticsMode? mode,
    int? trendIndex,
  }) => AnalyticsUiState(
    tab: tab ?? this.tab,
    periodIndex: periodIndex ?? this.periodIndex,
    mode: mode ?? this.mode,
    trendIndex: trendIndex ?? this.trendIndex,
  );
}

class AnalyticsController extends Notifier<AnalyticsUiState> {
  @override
  AnalyticsUiState build() => const AnalyticsUiState();

  void setTab(AnalyticsTab tab) => state = state.copyWith(tab: tab);

  void setMode(AnalyticsMode mode) => state = state.copyWith(mode: mode);

  /// Shows [year]/[month] (Gregorian, 1–12) in the breakdown. Months after
  /// the current one are not allowed and show the current month instead.
  void selectMonth(int year, int month) {
    final now = ReportingTimeZone.bangkok.wallClock(
      ref.read(clockProvider).nowUtc(),
    );
    final ago = (now.year * 12 + now.month) - (year * 12 + month);
    state = state.copyWith(periodIndex: ago < 0 ? 0 : ago);
  }

  void resetPeriod() => state = state.copyWith(periodIndex: 0);

  void selectTrend(int index) => state = state.copyWith(trendIndex: index);

  /// Opening Analytics from elsewhere chooses a tab.
  void open(AnalyticsTab tab) => state = state.copyWith(tab: tab);
}

/// Months shown in the trend chart: the current month and the five before.
const periodCount = 6;

final analyticsProvider =
    NotifierProvider<AnalyticsController, AnalyticsUiState>(
      AnalyticsController.new,
    );

/// One category slice of the donut.
@immutable
class BreakdownSlice {
  const BreakdownSlice({
    required this.name,
    required this.color,
    required this.amount,
    required this.share,
  });

  final String name;
  final Color color;
  final int amount;

  /// 0–1.
  final double share;
}

@immutable
class Breakdown {
  const Breakdown({
    required this.month,
    required this.slices,
    required this.total,
    required this.transfers,
  });

  /// Wall-clock first day of the month shown.
  final DateTime month;
  final List<BreakdownSlice> slices;
  final int total;
  final int transfers;

  bool get isEmpty => slices.isEmpty;
}

DateTime _monthsAgo(DateTime nowUtc, int monthsAgo) {
  final w = ReportingTimeZone.bangkok.wallClock(nowUtc);
  return DateTime.utc(w.year, w.month - monthsAgo);
}

final breakdownProvider = Provider<Breakdown>((ref) {
  final s = ref.watch(demoStoreProvider);
  final ui = ref.watch(analyticsProvider);
  final now = ref.watch(clockProvider).nowUtc();
  final tz = ReportingTimeZone.bangkok;
  final month = _monthsAgo(now, ui.periodIndex);
  final totals = const ReportCalculator().totals(
    s.transactions,
    tz.month(month.year, month.month),
  );
  final source = ui.mode == AnalyticsMode.expense
      ? totals.expenseByCategory
      : totals.incomeByCategory;
  final entries =
      source.entries
          .where((e) => e.value > 0 && s.category(e.key) != null)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
  final total = entries.fold(0, (sum, e) => sum + e.value);
  return Breakdown(
    month: month,
    total: total,
    transfers: totals.transfers,
    slices: [
      for (final e in entries)
        BreakdownSlice(
          name: s.category(e.key)!.name,
          color: s.categoryStyles[e.key]?.chart ?? const Color(0xFFC9C8C2),
          amount: e.value,
          share: e.value / total,
        ),
    ],
  );
});

@immutable
class TrendPoint {
  const TrendPoint({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final int income;
  final int expense;

  int get net => income - expense;
}

/// Six months of income vs expense, oldest first.
final trendProvider = Provider<List<TrendPoint>>((ref) {
  final s = ref.watch(demoStoreProvider);
  final now = ref.watch(clockProvider).nowUtc();
  final tz = ReportingTimeZone.bangkok;
  final months = [
    for (var i = periodCount - 1; i >= 0; i--) _monthsAgo(now, i),
  ];
  final totals = const ReportCalculator().trend(s.transactions, [
    for (final m in months) tz.month(m.year, m.month),
  ]);
  return [
    for (final (i, m) in months.indexed)
      TrendPoint(
        month: m,
        income: totals[i].income,
        expense: totals[i].expense,
      ),
  ];
});
