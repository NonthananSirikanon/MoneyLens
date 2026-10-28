import 'package:flutter/widgets.dart';

import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/dates/reporting_time_zone.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../demo/demo_models.dart';
import '../../../l10n/formatting.dart';
import '../../../l10n/l10n.dart';
import '../application/import_view_providers.dart';
import '../domain/scan_status.dart';

/// Pill colours and icon per status (`.pill--*`).
({Color bg, Color fg, Color? iconColor, IconData icon}) scanStatusStyle(
  ScanStatus status,
) => switch (status) {
  ScanStatus.queued => (
    bg: MlColors.soft,
    fg: MlColors.textSecondary,
    iconColor: null,
    icon: MlIcons.clock,
  ),
  ScanStatus.processing => (
    bg: MlColors.transferSoft,
    fg: MlColors.transfer,
    iconColor: null,
    icon: MlIcons.loader,
  ),
  ScanStatus.needsReview => (
    bg: MlColors.warningSoft,
    fg: MlColors.warningPillText,
    iconColor: MlColors.warning,
    icon: MlIcons.circleAlert,
  ),
  ScanStatus.duplicate => (
    bg: MlColors.errorSoft,
    fg: MlColors.amountExpense,
    iconColor: null,
    icon: MlIcons.copy,
  ),
  ScanStatus.failed => (
    bg: MlColors.errorSoft,
    fg: MlColors.amountExpense,
    iconColor: null,
    icon: MlIcons.circleX,
  ),
  ScanStatus.confirmed => (
    bg: MlColors.successSoft,
    fg: MlColors.amountIncome,
    iconColor: null,
    icon: MlIcons.circleCheck,
  ),
  ScanStatus.discarded => (
    bg: MlColors.soft,
    fg: MlColors.textTertiary,
    iconColor: null,
    icon: MlIcons.trash2,
  ),
};

String scanStatusLabel(BuildContext context, ScanStatus status) {
  final l10n = context.l10n;
  return switch (status) {
    ScanStatus.queued => l10n.scanStatusQueued,
    ScanStatus.processing => l10n.scanStatusProcessing,
    ScanStatus.needsReview => l10n.scanStatusNeedsReview,
    ScanStatus.duplicate => l10n.scanStatusDuplicate,
    ScanStatus.failed => l10n.scanStatusFailed,
    ScanStatus.confirmed => l10n.scanStatusConfirmed,
    ScanStatus.discarded => l10n.scanStatusDiscarded,
  };
}

String scanSourceLabel(BuildContext context, ImportSource source) {
  final l10n = context.l10n;
  return switch (source) {
    ImportSource.camera => l10n.scanSourceCamera,
    ImportSource.gallery => l10n.scanSourceGallery,
    ImportSource.shareSheet => l10n.scanSourceShareSheet,
    ImportSource.discovery => l10n.scanSourceDiscovery,
  };
}

/// Queue title: the reading once available, otherwise the file name.
String scanTitle(BuildContext context, ScanView v) {
  final d = v.details;
  final r = d?.reading;
  return switch (d?.titleKind) {
    ScanTitleKind.reading when r != null => '${r.merchant} · ฿${r.amountText}',
    ScanTitleKind.discardedDuplicate when r != null =>
      context.l10n.queueDuplicateTitle(r.amountText),
    _ => d?.fileName ?? '',
  };
}

/// One entry in the slip queue (`.scan-tile`).
class ScanTile extends StatelessWidget {
  const ScanTile({super.key, required this.view, required this.onAction});

  final ScanView view;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = view.scan.status;
    final style = scanStatusStyle(status);
    final action = switch (status) {
      ScanStatus.needsReview => l10n.queueActionReview,
      ScanStatus.duplicate => l10n.queueActionCompare,
      ScanStatus.failed => l10n.queueActionRetry,
      _ => null,
    };
    final at = ReportingTimeZone.bangkok.wallClock(view.scan.createdAt);
    return Opacity(
      opacity: status == ScanStatus.discarded ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: MlColors.surface,
          borderRadius: BorderRadius.circular(MlRadius.xl),
          border: Border.all(color: MlColors.border),
        ),
        child: Row(
          children: [
            SlipImage(
              width: 44,
              height: 58,
              degraded: status == ScanStatus.failed,
            ),
            const SizedBox(width: MlSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scanTitle(context, view),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MlText.small.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${scanSourceLabel(context, view.scan.source)} · ${context.dateFormat.dayMonthTime(at)}',
                    style: MlText.caption.copyWith(
                      color: MlColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  MlPill(
                    label: scanStatusLabel(context, status),
                    icon: style.icon,
                    background: style.bg,
                    foreground: style.fg,
                    iconColor: style.iconColor,
                  ),
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: MlSpace.xs),
              MlButton(
                label: action,
                height: 36,
                expand: false,
                horizontalPadding: 14,
                fontWeight: FontWeight.w600,
                variant: status == ScanStatus.needsReview
                    ? MlButtonVariant.primary
                    : MlButtonVariant.secondary,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
