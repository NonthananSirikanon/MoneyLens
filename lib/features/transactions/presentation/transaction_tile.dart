import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/dates/clock.dart';
import '../../../core/dates/reporting_time_zone.dart';
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

/// What the small line under the amount shows.
enum TileTrailing {
  /// Clock time, `09:15`. For lists already grouped under a day header.
  time,

  /// `วันนี้`, `เมื่อวาน`, or weekday and date (`จันทร์ 2 พ.ย.`). No clock time.
  dateWeekday,
}

/// A transaction row as used on Home, the Transactions list and search.
class TransactionTile extends ConsumerWidget {
  const TransactionTile({
    super.key,
    required this.view,
    required this.onPressed,
    this.trailing = TileTrailing.time,
  });

  final TransactionView view;
  final VoidCallback onPressed;
  final TileTrailing trailing;

  String _trailingText(BuildContext context, WidgetRef ref) {
    if (trailing == TileTrailing.time) {
      return context.dateFormat.time(view.wallClock);
    }
    final now = ReportingTimeZone.bangkok.wallClock(
      ref.watch(clockProvider).nowUtc(),
    );
    final today = DateTime.utc(now.year, now.month, now.day);
    final day = DateTime.utc(
      view.wallClock.year,
      view.wallClock.month,
      view.wallClock.day,
    );
    return switch (today.difference(day).inDays) {
      0 => context.l10n.today,
      1 => context.l10n.yesterday,
      _ => context.dateFormat.weekdayDayMonth(view.wallClock),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, tint) = transactionAvatar(view);
    final amount = context.signedAmount(view.type, view.transaction.amount);
    final subtitle = transactionSubtitle(context, view);
    final trailingText = _trailingText(context, ref);
    final dateFirst = trailing == TileTrailing.dateWeekday;
    final trailingLine = Padding(
      padding: EdgeInsets.only(bottom: dateFirst ? 1 : 0),
      child: Text(
        trailingText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: MlText.caption.copyWith(color: MlColors.textTertiary),
      ),
    );
    return FTappable(
      semanticsLabel: trailing == TileTrailing.time
          ? '${view.title}, $subtitle, $amount'
          : '${view.title}, $subtitle, $trailingText, $amount',
      onPress: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: MlSpace.sm),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: MlColors.border)),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final rowWidth = box.maxWidth;
            return Row(
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
                // Capped so a long date at large text scale ellipsizes instead of
                // squeezing the title out of the row.
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: rowWidth * 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // The dashboard variant puts the day above the amount.
                      if (dateFirst) trailingLine,
                      Text(
                        amount,
                        style: MlText.amtM.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: view.type.tone.color,
                        ),
                      ),
                      if (!dateFirst) ...[
                        const SizedBox(height: 1),
                        trailingLine,
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
