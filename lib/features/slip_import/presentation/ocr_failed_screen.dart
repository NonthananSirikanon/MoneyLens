import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../demo/demo_store.dart';
import '../../../l10n/l10n.dart';
import 'import_flows.dart';
import 'scan_photo.dart';
import '../application/import_view_providers.dart';
import '../../../l10n/failure_messages.dart';

/// "อ่านสลิปไม่สำเร็จ": tips plus retry, manual entry or delete.
class OcrFailedScreen extends ConsumerWidget {
  const OcrFailedScreen({super.key, required this.scanId});

  final String scanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final store = ref.read(appStoreProvider.notifier);
    final scan = ref.watch(scanViewProvider(scanId))?.scan;
    final tips = [
      (MlIcons.sun, MlColors.warning, l10n.ocrTipLight),
      (MlIcons.scanLine, MlColors.success, l10n.ocrTipVisible),
      (MlIcons.smartphone, MlColors.transfer, l10n.ocrTipScreenshot),
    ];
    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 20, 0),
              sliver: SliverToBoxAdapter(
                child: MlAppBar(
                  title: l10n.ocrFailedTitle,
                  onLeading: () => context.pop(),
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ScanPhoto(
                        attachmentPath: scan?.attachmentPath,
                        width: 110,
                        height: 146,
                        radius: 14,
                        degraded: true,
                        border: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.ocrFailedHeading,
                      textAlign: TextAlign.center,
                      style: MlText.h2.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    if (scan?.failureCode case final code?) ...[
                      Text(
                        l10n.failureMessage(code),
                        textAlign: TextAlign.center,
                        style: MlText.small.copyWith(
                          color: MlColors.amountExpense,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      l10n.ocrFailedBody,
                      textAlign: TextAlign.center,
                      style: MlText.small.copyWith(
                        color: MlColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    MlCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.ocrTipsTitle,
                            style: MlText.small.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          for (final (icon, color, text) in tips) ...[
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(icon, size: 17, color: color),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(text, style: MlText.small),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 20),
                    MlButton(
                      label: l10n.ocrRetry,
                      icon: MlIcons.refreshCw,
                      onPressed: () {
                        store.retryFailed(scanId);
                        context.pushReplacement(AppRoutes.processing(scanId));
                      },
                    ),
                    const SizedBox(height: MlSpace.xs),
                    MlButton(
                      label: l10n.ocrManual,
                      variant: MlButtonVariant.outline,
                      height: 52,
                      onPressed: () {
                        store.discardScan(scanId);
                        ImportFlows.startManual(context, replace: true);
                      },
                    ),
                    const SizedBox(height: MlSpace.xs),
                    MlButton(
                      label: l10n.ocrDelete,
                      variant: MlButtonVariant.destructiveGhost,
                      height: 44,
                      fontWeight: FontWeight.w600,
                      onPressed: () {
                        store.removeScan(scanId);
                        context.pop();
                        showMlToast(l10n.toastSlipDeleted);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
