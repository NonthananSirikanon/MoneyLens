import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/clock.dart';
import '../../../core/dates/reporting_time_zone.dart';
import '../../../demo/demo_store.dart';
import '../../dashboard/application/home_view_providers.dart';

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

  /// 0 = current month, then the demo's past periods.
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

  /// The period pill cycles through the available months, as in the
  /// prototype (current → previous → a month without data).
  void cyclePeriod() {
    final count = 1 + ref.read(demoStoreProvider).pastPeriods.length;
    state = state.copyWith(periodIndex: (state.periodIndex + 1) % count);
  }

  void resetPeriod() => state = state.copyWith(periodIndex: 0);

  void selectTrend(int index) => state = state.copyWith(trendIndex: index);

  /// Opening Analytics from elsewhere chooses a tab.
  void open(AnalyticsTab tab) => state = state.copyWith(tab: tab);
}

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
  final Map<String, int> source;
  final int transfers;
  final DateTime month;
  if (ui.periodIndex == 0) {
    final totals = ref.watch(monthTotalsProvider);
    source = ui.mode == AnalyticsMode.expense
        ? totals.expenseByCategory
        : totals.incomeByCategory;
    transfers = totals.transfers;
    month = _monthsAgo(now, 0);
  } else {
    final p = s.pastPeriods[ui.periodIndex - 1];
    source = ui.mode == AnalyticsMode.expense
        ? p.expenseByCategory
        : p.incomeByCategory;
    transfers = p.transfers;
    month = _monthsAgo(now, p.monthsAgo);
  }
  final entries =
      source.entries
          .where((e) => e.value > 0 && s.category(e.key) != null)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
  final total = entries.fold(0, (sum, e) => sum + e.value);
  return Breakdown(
    month: month,
    total: total,
    transfers: transfers,
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

/// Six months of income vs expense; the current month is live.
final trendProvider = Provider<List<TrendPoint>>((ref) {
  final s = ref.watch(demoStoreProvider);
  final totals = ref.watch(monthTotalsProvider);
  final now = ref.watch(clockProvider).nowUtc();
  return [
    for (final m in s.trend)
      TrendPoint(
        month: _monthsAgo(now, m.monthsAgo),
        income: m.monthsAgo == 0 ? totals.income : m.income,
        expense: m.monthsAgo == 0 ? totals.expense : m.expense,
      ),
  ];
});
