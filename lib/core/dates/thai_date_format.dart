import 'package:intl/intl.dart';

/// Display formatting for wall-clock dates (see `ReportingTimeZone.wallClock`).
///
/// Thai output uses the Buddhist Era year (+543) and abbreviated month names,
/// e.g. `24 ต.ค. 2569`; other locales use `24 Oct 2026`.
class AppDateFormat {
  const AppDateFormat(this.locale);

  final String locale;

  bool get _thai => locale.startsWith('th');

  int _year(DateTime d) => _thai ? d.year + 543 : d.year;

  String _month(DateTime d) => DateFormat.MMM(locale).format(d);

  static const _thaiWeekdays = [
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  ];

  // intl's abbreviated Thai weekdays are single letters ("จ."), too terse.
  String _weekday(DateTime d) =>
      _thai ? _thaiWeekdays[d.weekday - 1] : DateFormat.E(locale).format(d);

  /// `24 ต.ค. 2569`
  String dayMonthYear(DateTime d) => '${d.day} ${_month(d)} ${_year(d)}';

  /// `24 ต.ค.`
  String dayMonth(DateTime d) => '${d.day} ${_month(d)}';

  /// `จันทร์ 2 พ.ย.` / `Mon 2 Nov` (no year).
  String weekdayDayMonth(DateTime d) => '${_weekday(d)} ${dayMonth(d)}';

  /// `ต.ค. 2569`
  String monthYear(DateTime d) => '${_month(d)} ${_year(d)}';

  /// `ต.ค.`
  String monthShort(DateTime d) => _month(d);

  /// `24 ต.ค. 10:24`
  String dayMonthTime(DateTime d) => '${dayMonth(d)} ${time(d)}';

  /// `09:15` (24-hour, as on Thai bank slips).
  String time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
