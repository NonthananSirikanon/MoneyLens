import 'package:flutter/widgets.dart';

import '../../../app/theme/icons.dart';
import '../../../app/app_state.dart';
import '../../../l10n/l10n.dart';
import '../domain/account.dart';

IconData accountIcon(AccountKind kind) => switch (kind) {
  AccountKind.bank => MlIcons.landmark,
  AccountKind.ewallet => MlIcons.smartphone,
  AccountKind.cash => MlIcons.wallet,
  AccountKind.other => MlIcons.wallet,
};

/// "ออมทรัพย์ •••• 1234", "•••• 9012" or "กระเป๋าสตางค์". Only the masked
/// last four digits are ever shown.
String accountSubtitle(
  BuildContext context,
  AccountKind kind,
  AccountDetails? details,
) {
  final l10n = context.l10n;
  final mask = details?.mask ?? '';
  return switch (kind) {
    AccountKind.bank =>
      mask.isEmpty ? l10n.accountSavings : '${l10n.accountSavings} $mask',
    AccountKind.cash => mask.isEmpty ? l10n.accountWallet : mask,
    AccountKind.ewallet ||
    AccountKind.other => mask.isEmpty ? l10n.accountKindWallet : mask,
  };
}
