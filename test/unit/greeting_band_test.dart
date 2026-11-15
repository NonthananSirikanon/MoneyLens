import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/core/dates/reporting_time_zone.dart';
import 'package:moneylens/features/dashboard/domain/greeting_band.dart';

void main() {
  GreetingBand at(int h, int m) => GreetingBand.at(
    ReportingTimeZone.bangkok.wallClock(
      ReportingTimeZone.bangkok.toUtc(2026, 11, 7, h, m),
    ),
  );

  test('band boundaries on the Bangkok wall clock', () {
    expect(at(4, 59), GreetingBand.night);
    expect(at(5, 0), GreetingBand.morning);
    expect(at(11, 59), GreetingBand.morning);
    expect(at(12, 0), GreetingBand.afternoon);
    expect(at(16, 59), GreetingBand.afternoon);
    expect(at(17, 0), GreetingBand.evening);
    expect(at(19, 59), GreetingBand.evening);
    expect(at(20, 0), GreetingBand.night);
    expect(at(0, 30), GreetingBand.night);
    expect(at(23, 59), GreetingBand.night);
  });

  test('untilNextChange lands exactly on the next boundary', () {
    DateTime wall(int h, int m, [int s = 0]) =>
        DateTime.utc(2026, 11, 7, h, m, s);
    expect(
      GreetingBand.untilNextChange(wall(4, 59)),
      const Duration(minutes: 1),
    );
    expect(GreetingBand.untilNextChange(wall(5, 0)), const Duration(hours: 7));
    expect(
      GreetingBand.untilNextChange(wall(19, 59, 30)),
      const Duration(seconds: 30),
    );
    // After 20:00 the next change is 05:00 the following day.
    expect(GreetingBand.untilNextChange(wall(23, 0)), const Duration(hours: 6));
    expect(
      GreetingBand.untilNextChange(wall(0, 30)),
      const Duration(hours: 4, minutes: 30),
    );
  });
}
