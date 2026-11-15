import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moneylens/core/dates/thai_date_format.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('th');
    await initializeDateFormatting('en');
  });

  // 2 Nov 2026 is a Monday.
  final monday = DateTime.utc(2026, 11, 2, 9, 15);

  test('weekdayDayMonth uses the short Thai weekday and no year', () {
    const fmt = AppDateFormat('th');
    expect(fmt.weekdayDayMonth(monday), 'จันทร์ 2 พ.ย.');
    expect(fmt.weekdayDayMonth(DateTime.utc(2026, 11, 8)), 'อาทิตย์ 8 พ.ย.');
    expect(fmt.weekdayDayMonth(DateTime.utc(2026, 11, 7)), 'เสาร์ 7 พ.ย.');
  });

  test('weekdayDayMonth in English', () {
    const fmt = AppDateFormat('en');
    expect(fmt.weekdayDayMonth(monday), 'Mon 2 Nov');
    expect(fmt.weekdayDayMonth(DateTime.utc(2026, 11, 8)), 'Sun 8 Nov');
  });
}
