import '../../../core/money/currency.dart';

enum AccountKind {
  cash('cash'),
  bank('bank'),
  ewallet('ewallet'),
  other('other');

  const AccountKind(this.dbValue);

  final String dbValue;

  static AccountKind fromDb(String value) =>
      values.firstWhere((k) => k.dbValue == value);
}

/// A wallet, cash pocket, bank account or e-wallet the user tracks.
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.kind,
    required this.currency,
    this.openingBalanceMinor,
    this.lastFour,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final AccountKind kind;
  final Currency currency;

  /// Optional. Balance semantics are still an open decision
  /// (DATABASE.md §11.2), so nothing computes balances from this yet.
  final int? openingBalanceMinor;

  /// Last four digits only; the full number is never stored.
  final String? lastFour;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
}
