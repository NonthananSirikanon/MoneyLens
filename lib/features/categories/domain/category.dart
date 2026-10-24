/// Whether a category classifies income or expenses. Transfers never use a
/// category to masquerade as income or expense (DATABASE.md §3.2).
enum CategoryKind {
  income('income'),
  expense('expense');

  const CategoryKind(this.dbValue);

  final String dbValue;

  static CategoryKind fromDb(String value) =>
      values.firstWhere((k) => k.dbValue == value);
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    this.iconKey,
    this.colorValue,
    required this.isDefault,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final CategoryKind kind;

  /// App-owned icon identifier, never executable content.
  final String? iconKey;
  final int? colorValue;
  final bool isDefault;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
}
