import '../../../core/dates/date_range.dart';
import '../../../core/dates/reporting_time_zone.dart';

/// Which transactions an export covers. Month and year boundaries follow
/// Asia/Bangkok, like every report (DATABASE.md §5).
enum ExportPeriod {
  thisMonth,
  last3Months,
  thisYear,
  all;

  /// The half-open range for [now], or null for [all].
  DateRange? rangeAt(DateTime now) {
    const zone = ReportingTimeZone.bangkok;
    final local = zone.wallClock(now);
    return switch (this) {
      thisMonth => zone.month(local.year, local.month),
      // This month and the two before it. Month 0 or -1 roll back into the
      // previous year.
      last3Months => DateRange(
        zone.month(local.year, local.month - 2).startUtc,
        zone.month(local.year, local.month).endUtc,
      ),
      thisYear => DateRange(
        zone.toUtc(local.year, 1, 1),
        zone.toUtc(local.year + 1, 1, 1),
      ),
      all => null,
    };
  }

  bool includes(DateTime instant, DateTime now) =>
      rangeAt(now)?.contains(instant) ?? true;
}
