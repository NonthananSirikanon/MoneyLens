import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/currency.dart';
import '../domain/account.dart';
import 'account_providers.dart';

/// Creates accounts. The new account is visible in [activeAccountsProvider]
/// when the call returns.
class AccountActions {
  const AccountActions(this._ref);

  final Ref _ref;

  Future<void> add({
    required String name,
    required AccountKind kind,
    String? last4,
    required int openingBalanceMinor,
  }) async {
    await _ref
        .read(accountRepositoryProvider)
        .create(
          name: name,
          kind: kind,
          currency: Currency.thb,
          openingBalanceMinor: openingBalanceMinor,
          lastFour: last4,
        );
    await reloadAccounts(_ref);
  }
}

final accountActionsProvider = Provider<AccountActions>(AccountActions.new);
