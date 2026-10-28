import '../../../core/money/currency.dart';
import 'account.dart';

abstract interface class AccountRepository {
  /// Accounts available for new entries (not archived).
  Stream<List<Account>> watchActive();

  /// One-shot read of the accounts available for new entries.
  Future<List<Account>> findActive();

  Future<Account?> findById(String id);

  Future<Account> create({
    required String name,
    required AccountKind kind,
    required Currency currency,
    int? openingBalanceMinor,
    String? lastFour,
  });
}
