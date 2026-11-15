/// Part of the day the Home greeting speaks to, on the Bangkok wall clock.
enum GreetingBand {
  morning,
  afternoon,
  evening,
  night;

  /// Band for [wallClock] (fields already in Asia/Bangkok): morning from
  /// 05:00, afternoon from 12:00, evening from 17:00, night from 20:00
  /// through 04:59.
  static GreetingBand at(DateTime wallClock) => switch (wallClock.hour) {
    >= 5 && < 12 => morning,
    >= 12 && < 17 => afternoon,
    >= 17 && < 20 => evening,
    _ => night,
  };

  /// Time left until the band changes, for scheduling a refresh.
  static Duration untilNextChange(DateTime wallClock) {
    const starts = [5, 12, 17, 20];
    final next = starts
        .map(
          (h) =>
              DateTime.utc(wallClock.year, wallClock.month, wallClock.day, h),
        )
        .firstWhere(
          (t) => t.isAfter(wallClock),
          orElse: () => DateTime.utc(
            wallClock.year,
            wallClock.month,
            wallClock.day + 1,
            starts.first,
          ),
        );
    return next.difference(wallClock);
  }
}
