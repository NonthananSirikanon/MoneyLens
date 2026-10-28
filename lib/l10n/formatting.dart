import 'package:flutter/widgets.dart';

import '../app/theme/text_styles.dart';
import '../core/dates/thai_date_format.dart';
import '../core/money/currency.dart';
import '../core/money/money.dart';
import '../core/money/money_formatter.dart';
import '../features/transactions/domain/transaction_type.dart';
import 'l10n.dart';

/// Locale-aware formatters for widgets.
extension FormattingContext on BuildContext {
  MoneyFormatter get moneyFormat => MoneyFormatter(localeTag);

  AppDateFormat get dateFormat => AppDateFormat(localeTag);

  /// `฿1,234.50` from minor units.
  String baht(int minor) => moneyFormat.format(Money(minor, Currency.thb));

  /// `฿1,235` from minor units.
  String bahtCompact(int minor) =>
      moneyFormat.compact(Money(minor, Currency.thb));

  /// Signed amount as shown in lists: `-฿80.00`, `+฿25,000.00`, `฿2,000.00`.
  String signedAmount(TransactionType type, Money amount) {
    final text = moneyFormat.format(amount);
    return switch (type) {
      TransactionType.expense => '-$text',
      TransactionType.income => '+$text',
      TransactionType.transfer => text,
    };
  }

  String typeLabel(TransactionType type) => switch (type) {
    TransactionType.expense => l10n.typeExpense,
    TransactionType.income => l10n.typeIncome,
    TransactionType.transfer => l10n.typeTransfer,
  };
}

extension TransactionTypeTone on TransactionType {
  AmountTone get tone => switch (this) {
    TransactionType.expense => AmountTone.expense,
    TransactionType.income => AmountTone.income,
    TransactionType.transfer => AmountTone.transfer,
  };
}
