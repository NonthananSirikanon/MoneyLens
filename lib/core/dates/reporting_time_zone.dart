import 'date_range.dart';

/// Reporting time zone for Thailand (`Asia/Bangkok`).
///
/// Bangkok has been a fixed UTC+7 with no daylight saving time since 1920,
/// so a fixed offset is exact and avoids bundling a tz database. Replace
/// this with a real tz lookup if user-selectable time zones are added.
class ReportingTimeZone {
  const ReportingTimeZone._(this.id, this.offset);

  static const bangkok = ReportingTimeZone._(
    'Asia/Bangkok',
    Duration(hours: 7),
  );

  final String id;
  final Duration offset;

  /// Wall-clock fields for [instant] in this zone. The returned value is
  /// flagged UTC only so Dart does not apply the device zone; treat its
  /// fields as local wall-clock time, not as an instant.
  DateTime wallClock(DateTime instant) => instant.toUtc().add(offset);

  /// The UTC instant for a wall-clock time in this zone, e.g. a slip's
  /// printed date that carries no zone information.
  DateTime toUtc(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
    int second = 0,
  ]) => DateTime.utc(year, month, day, hour, minute, second).subtract(offset);

  /// The calendar month in this zone that contains [instant].
  DateRange monthContaining(DateTime instant) {
    final local = wallClock(instant);
    return month(local.year, local.month);
  }

  DateRange month(int year, int month) =>
      DateRange(toUtc(year, month, 1), toUtc(year, month + 1, 1));
}
