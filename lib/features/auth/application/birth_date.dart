/// Why a birth date was rejected. Mapped to messages in the UI.
enum BirthDateError {
  /// Day, month or year is missing.
  incomplete,

  /// The year is not four digits (Buddhist Era, ≥ 2400).
  yearFormat,

  /// The combination does not exist, e.g. 31 February.
  noSuchDate,

  /// After today.
  future,
}

class BirthDateResult {
  const BirthDateResult.ok(DateTime this.date, int this.age)
    : error = null,
      badDay = false,
      badMonth = false,
      badYear = false;

  const BirthDateResult.error(
    BirthDateError this.error, {
    this.badDay = false,
    this.badMonth = false,
    this.badYear = false,
  }) : date = null,
       age = null;

  final BirthDateError? error;
  final DateTime? date;
  final int? age;

  /// Which fields to outline in the error colour.
  final bool badDay;
  final bool badMonth;
  final bool badYear;

  bool get isValid => error == null;
}

/// Validates the day / month / year (พ.ศ.) fields. Only "a real date that is
/// not in the future"; there is deliberately no minimum age.
abstract final class BirthDateValidator {
  static BirthDateResult validate({
    required String day,
    required int? month,
    required String yearBuddhist,
    required DateTime today,
  }) {
    final hasDay = day.isNotEmpty;
    final hasYear = yearBuddhist.isNotEmpty;
    if (!hasDay || month == null || !hasYear) {
      return BirthDateResult.error(
        BirthDateError.incomplete,
        badDay: !hasDay,
        badMonth: month == null,
        badYear: !hasYear,
      );
    }
    final y = int.tryParse(yearBuddhist);
    if (yearBuddhist.length != 4 || y == null || y < 2400) {
      return const BirthDateResult.error(
        BirthDateError.yearFormat,
        badYear: true,
      );
    }
    final d = int.tryParse(day);
    final gregorian = y - 543;
    // month is 1-12 here; DateTime normalises overflow, so compare back.
    final date = d == null ? null : DateTime.utc(gregorian, month, d);
    if (d == null ||
        d < 1 ||
        date!.year != gregorian ||
        date.month != month ||
        date.day != d) {
      return const BirthDateResult.error(
        BirthDateError.noSuchDate,
        badDay: true,
        badMonth: true,
      );
    }
    final t = DateTime.utc(today.year, today.month, today.day);
    if (date.isAfter(t)) {
      return const BirthDateResult.error(
        BirthDateError.future,
        badDay: true,
        badMonth: true,
        badYear: true,
      );
    }
    var age = t.year - date.year;
    if (t.month < date.month || (t.month == date.month && t.day < date.day)) {
      age--;
    }
    return BirthDateResult.ok(date, age);
  }
}
