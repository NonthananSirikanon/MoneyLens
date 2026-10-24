import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/clock.dart';
import '../../../core/dates/date_range.dart';
import '../../../core/dates/reporting_time_zone.dart';
import '../../transactions/application/transaction_providers.dart';
import '../../transactions/domain/transaction.dart';
import 'summary_calculator.dart';

/// The reporting period shown on the dashboard. Defaults to the current
/// month in Asia/Bangkok. A period picker (AN-03) can update this later.
final dashboardPeriodProvider = Provider<DateRange>(
  (ref) => ReportingTimeZone.bangkok.monthContaining(
    ref.watch(clockProvider).nowUtc(),
  ),
);

final dashboardSummaryProvider = StreamProvider<PeriodSummary>((ref) {
  final range = ref.watch(dashboardPeriodProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .watchInRange(range)
      .map((txs) => const SummaryCalculator().summarize(txs, range));
});

final recentTransactionsProvider = StreamProvider<List<MoneyTransaction>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchRecent(limit: 5),
);
