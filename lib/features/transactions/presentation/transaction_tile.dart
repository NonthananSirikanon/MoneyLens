import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../l10n/formatting.dart';
import '../../../l10n/l10n.dart';
import '../application/transaction_view_providers.dart';

/// Icon and tint for a transaction: its category, or the transfer arrows.
(IconData, Color) transactionAvatar(TransactionView v) => v.isTransfer
    ? (MlIcons.arrowLeftRight, MlColors.transferSoft)
    : (MlIconKeys.of(v.category?.iconKey), v.categoryTint ?? MlColors.soft);

/// "อาหารและเครื่องดื่ม · KBank" or "KBank → TrueMoney".
String transactionSubtitle(BuildContext context, TransactionView v) {
  final from = v.accountDetails?.shortName ?? v.account?.name ?? '';
  if (v.isTransfer) {
    final to = v.destinationDetails?.shortName ?? v.destination?.name ?? '';
    return '$from → $to';
  }
  final category = v.category?.name ?? context.l10n.uncategorized;
  return '$category · $from';
}

/// A transaction row as used on Home, the Transactions list and search.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.view,
    required this.onPressed,
  });

  final TransactionView view;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = transactionAvatar(view);
    final amount = context.signedAmount(view.type, view.transaction.amount);
    final subtitle = transactionSubtitle(context, view);
    return FTappable(
      semanticsLabel: '${view.title}, $subtitle, $amount',
      onPress: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: MlSpace.sm),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: MlColors.border)),
        ),
        child: Row(
          children: [
            TintIcon(icon: icon, tint: tint),
            const SizedBox(width: MlSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    view.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MlText.title,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MlText.caption.copyWith(
                      color: MlColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: MlSpace.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: MlText.amtM.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: view.type.tone.color,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  context.dateFormat.time(view.wallClock),
                  style: MlText.caption.copyWith(color: MlColors.textTertiary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
