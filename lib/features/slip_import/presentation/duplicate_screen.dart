import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/dates/reporting_time_zone.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../app/app_store.dart';
import '../../../l10n/formatting.dart';
import '../../../l10n/l10n.dart';
import '../../transactions/application/entry_form.dart';
import '../application/import_view_providers.dart';
import 'scan_photo.dart';

/// "อาจเป็นรายการซ้ำ": the new slip side by side with the saved match.
class DuplicateScreen extends ConsumerWidget {
  const DuplicateScreen({super.key, required this.scanId});

  final String scanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = ref.watch(scanViewProvider(scanId));
    final reading = view?.details?.reading;
    final original = ref.watch(
      appStoreProvider.select(
        (s) => s.transaction(view?.details?.duplicateOfTransactionId),
      ),
    );
    if (view == null || reading == null) {
      return const ColoredBox(color: MlColors.bgApp);
    }
    final fmt = context.dateFormat;
    final readAt = ReportingTimeZone.bangkok.wallClock(reading.occurredAt);
    final ref8 = reading.providerReference ?? '—';

    final columns = [
      (
        l10n.duplicateNew,
        MlColors.amountExpense,
        true,
        [
          (l10n.duplicateMerchant, reading.merchant, false),
          (l10n.duplicateAmount, '฿${reading.amountText}', true),
          (l10n.detailDate, fmt.dayMonthTime(readAt), true),
          (l10n.duplicateReference, ref8, true),
        ],
      ),
      if (original != null)
        (
          l10n.duplicateSaved,
          MlColors.textSecondary,
          false,
          [
            (l10n.duplicateMerchant, original.merchant ?? '', false),
            (l10n.duplicateAmount, context.baht(original.amount.minor), true),
            (
              l10n.detailDate,
              fmt.dayMonthTime(
                ReportingTimeZone.bangkok.wallClock(original.occurredAt),
              ),
              true,
            ),
            (l10n.duplicateReference, ref8, true),
          ],
        ),
    ];

    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            Transform.translate(
              offset: const Offset(-8, 0),
              child: MlAppBar(
                title: l10n.duplicateTitle,
                onLeading: () => context.pop(),
              ),
            ),
            const SizedBox(height: 4),
            MlBanner(
              tone: MlBannerTone.error,
              icon: MlIcons.copy,
              iconSize: 19,
              title: l10n.duplicateBannerTitle,
              body: l10n.duplicateBannerBody,
            ),
            const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, (head, headColor, isNew, kv))
                      in columns.indexed) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(MlSpace.sm),
                        decoration: BoxDecoration(
                          color: MlColors.surface,
                          borderRadius: BorderRadius.circular(MlRadius.lg),
                          border: Border.all(
                            color: isNew ? MlColors.error : MlColors.border,
                            width: isNew ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              head,
                              style: MlText.label.copyWith(
                                fontWeight: FontWeight.w600,
                                color: headColor,
                              ),
                            ),
                            const SizedBox(height: MlSpace.xs),
                            ScanPhoto(
                              attachmentPath: view.scan.attachmentPath,
                              height: 96,
                              radius: 10,
                            ),
                            for (final (k, v, hot) in kv) ...[
                              const SizedBox(height: MlSpace.xs),
                              Text(
                                k,
                                style: MlText.micro.copyWith(
                                  color: MlColors.textSecondary,
                                ),
                              ),
                              Text(
                                v,
                                style: MlText.meta.copyWith(
                                  color: hot
                                      ? MlColors.amountExpense
                                      : MlColors.textPrimary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: MlSpace.sm),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '● ${l10n.duplicateMatch}',
                    style: const TextStyle(
                      color: MlColors.amountExpense,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' — ${l10n.duplicateMatchHint}'),
                ],
              ),
              style: MlText.caption.copyWith(color: MlColors.textSecondary),
            ),
            const SizedBox(height: 20),
            MlButton(
              label: l10n.duplicateDiscard,
              onPressed: () {
                ref.read(appStoreProvider.notifier).discardScan(scanId);
                context.pop();
                showMlToast(l10n.toastDuplicateDiscarded);
              },
            ),
            const SizedBox(height: MlSpace.xs),
            MlButton(
              label: l10n.duplicateKeep,
              variant: MlButtonVariant.outline,
              height: 52,
              onPressed: () async {
                try {
                  // Real slips are read after all and sent to review.
                  await ref
                      .read(appStoreProvider.notifier)
                      .keepDuplicate(scanId);
                } on Object {
                  if (context.mounted) showMlToast(l10n.failureGeneric);
                  return;
                }
                if (!context.mounted) return;
                context.pushReplacement(
                  AppRoutes.entry,
                  extra: ScanEntryArgs(scanId),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
