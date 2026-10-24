/// A half-open UTC instant range `[startUtc, endUtc)`.
///
/// Every report, filter and export uses this one boundary rule
/// (DATABASE.md §5).
class DateRange {
  DateRange(this.startUtc, this.endUtc)
    : assert(startUtc.isUtc && endUtc.isUtc, 'DateRange bounds must be UTC'),
      assert(!endUtc.isBefore(startUtc), 'end must not precede start');

  final DateTime startUtc;
  final DateTime endUtc;

  bool contains(DateTime instant) {
    final utc = instant.toUtc();
    return !utc.isBefore(startUtc) && utc.isBefore(endUtc);
  }

  @override
  bool operator ==(Object other) =>
      other is DateRange &&
      other.startUtc == startUtc &&
      other.endUtc == endUtc;

  @override
  int get hashCode => Object.hash(startUtc, endUtc);
}
