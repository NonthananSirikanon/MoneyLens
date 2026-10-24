import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/dates/reporting_time_zone.dart';
import '../../../core/money/money_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/transaction.dart';
import '../domain/transaction_type.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final MoneyTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final scheme = Theme.of(context).colorScheme;
    final tx = transaction;

    final (icon, color, sign, label) = switch (tx.type) {
      TransactionType.income => (
        Icons.south_west,
        scheme.incomeColor,
        '+',
        l10n.transactionTypeIncome,
      ),
      TransactionType.expense => (
        Icons.north_east,
        scheme.expenseColor,
        '-',
        l10n.transactionTypeExpense,
      ),
      TransactionType.transfer => (
        Icons.swap_horiz,
        scheme.onSurfaceVariant,
        '',
        l10n.transactionTypeTransfer,
      ),
    };
    final when = ReportingTimeZone.bangkok.wallClock(tx.occurredAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(
        tx.merchant ?? label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(DateFormat.yMMMd(locale).add_Hm().format(when)),
      trailing: Text(
        '$sign${MoneyFormatter(locale).format(tx.amount)}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
      ),
    );
  }
}
