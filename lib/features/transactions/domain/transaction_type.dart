enum TransactionType {
  income('income'),
  expense('expense'),

  /// Money moved between the user's own accounts. Never counted as income
  /// or expense (PROJECT.md TX-06).
  transfer('transfer');

  const TransactionType(this.dbValue);

  final String dbValue;

  static TransactionType fromDb(String value) =>
      values.firstWhere((t) => t.dbValue == value);
}

/// How a confirmed transaction entered the ledger. Extend only through
/// this enum (DATABASE.md §3.3).
enum TransactionSource {
  manual('manual'),
  ocr('ocr'),
  import('import'),
  recurring('recurring');

  const TransactionSource(this.dbValue);

  final String dbValue;

  static TransactionSource fromDb(String value) =>
      values.firstWhere((s) => s.dbValue == value);
}
