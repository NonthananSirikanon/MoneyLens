import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../l10n/l10n.dart';
import '../../transactions/application/entry_form.dart';
import '../application/import_view_providers.dart';
import '../domain/scan_status.dart';

/// "กำลังอ่านสลิป": five pipeline steps driven by the (simulated) OCR
/// progress. Opens the review form when the read finishes; leaving early
/// keeps the slip in the queue.
class ProcessingScreen extends ConsumerWidget {
  const ProcessingScreen({super.key, required this.scanId});

  final String scanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pct = ref.watch(ocrProgressProvider(scanId));

    ref.listen(scanViewProvider(scanId), (prev, next) {
      if (prev?.scan.status != ScanStatus.needsReview &&
          next?.scan.status == ScanStatus.needsReview) {
        context.pushReplacement(AppRoutes.entry, extra: ScanEntryArgs(scanId));
      }
    });

    final steps = [
      (l10n.processingStepFile, 15.0),
      (l10n.processingStepRecord, 30.0),
      (l10n.processingStepOcr, 65.0),
      (l10n.processingStepExtract, 85.0),
      (l10n.processingStepDuplicate, 100.0),
    ];

    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MlAppBar(
                title: l10n.processingTitle,
                leading: MlAppBarLeading.close,
                onLeading: () => context.pop(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        Center(
                          child: SizedBox(
                            width: 150,
                            height: 200,
                            child: Stack(
                              children: [
                                const SlipImage(
                                  width: 150,
                                  height: 200,
                                  radius: MlRadius.xl,
                                  border: true,
                                ),
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 60),
                                  left: 0,
                                  right: 0,
                                  top: 200 * (pct.clamp(0, 97) / 100),
                                  child: Container(
                                    height: 3,
                                    decoration: const BoxDecoration(
                                      color: MlColors.sage,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xCCA8B89A),
                                          blurRadius: 14,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Semantics(
                          liveRegion: true,
                          value: '${pct.round()}%',
                          child: MlStepList(
                            steps: [
                              for (var i = 0; i < steps.length; i++)
                                (
                                  steps[i].$1,
                                  pct >= steps[i].$2
                                      ? MlStepState.done
                                      : pct >= (i == 0 ? 0 : steps[i - 1].$2)
                                      ? MlStepState.now
                                      : MlStepState.todo,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        MlProgressBar(value: pct / 100, animate: false),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  children: [
                    MlBanner(
                      tone: MlBannerTone.info,
                      icon: MlIcons.info,
                      iconSize: 17,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      body: l10n.processingLeaveNote,
                    ),
                    const SizedBox(height: 10),
                    MlButton(
                      label: l10n.processingGoQueue,
                      variant: MlButtonVariant.outline,
                      height: 52,
                      onPressed: () => context.pushReplacement(AppRoutes.queue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
