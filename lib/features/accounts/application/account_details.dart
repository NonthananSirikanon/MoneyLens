import 'package:flutter/widgets.dart';

import '../domain/account.dart';

/// Side data for an [Account]: the short label used in rows, the masked
/// last four digits (never the full number) and the icon tint.
@immutable
class AccountDetails {
  const AccountDetails({
    required this.shortName,
    this.last4,
    required this.tint,
  });

  final String shortName;
  final String? last4;
  final Color tint;

  /// Derives display details from a stored account: the first word of the
  /// name as the short label, and a tint by kind.
  factory AccountDetails.of(Account a) => AccountDetails(
    shortName: a.name.trim().split(RegExp(r'\s+')).first,
    last4: a.lastFour,
    tint: switch (a.kind) {
      AccountKind.bank => const Color(0xFFE3EFE7),
      AccountKind.ewallet => const Color(0xFFF7EDD6),
      AccountKind.cash => const Color(0xFFE6EBDF),
      AccountKind.other => const Color(0xFFF0F0EC),
    },
  );

  /// `•••• 1234`, or empty when no digits were given.
  String get mask => last4 == null || last4!.isEmpty ? '' : '•••• $last4';
}
