import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_preferences.dart';
import '../../../app/router.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../l10n/l10n.dart';
import 'import_flows.dart';

enum DeniedKind { camera, photos }

/// Shown when camera or photo access was declined. "เปิดการตั้งค่า" is
/// SIMULATED: it grants the mock permission instead of opening the OS
/// settings app.
class DeniedScreen extends ConsumerWidget {
  const DeniedScreen({super.key, required this.kind});

  final DeniedKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final camera = kind == DeniedKind.camera;
    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 24, 0),
              sliver: SliverToBoxAdapter(
                child: MlAppBar(
                  title: camera ? l10n.addOptionCamera : l10n.addOptionGallery,
                  onLeading: () => context.pop(),
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Illustration(
                        MlImages.denied,
                        width: 240,
                        height: 180,
                      ),
                    ),
                    const SizedBox(height: MlSpace.xs),
                    const Center(
                      child: TintIcon(
                        icon: MlIcons.lock,
                        tint: MlColors.soft,
                        size: 44,
                        iconSize: 19,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      camera ? l10n.deniedCameraTitle : l10n.deniedPhotosTitle,
                      textAlign: TextAlign.center,
                      style: MlText.h2.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.deniedBody,
                      textAlign: TextAlign.center,
                      style: MlText.small.copyWith(
                        color: MlColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    MlButton(
                      label: l10n.deniedOpenSettings,
                      onPressed: () {
                        ref
                            .read(appPreferencesProvider.notifier)
                            .setPermissionsGranted(true);
                        showMlToast(l10n.toastPermissionOpened);
                        context.pop();
                      },
                    ),
                    const SizedBox(height: MlSpace.xs),
                    MlButton(
                      label: camera
                          ? l10n.deniedAltGallery
                          : l10n.deniedAltCamera,
                      variant: MlButtonVariant.outline,
                      height: 52,
                      onPressed: () => camera
                          ? ImportFlows.startGallery(
                              context,
                              ref,
                              replace: true,
                            )
                          : context.pushReplacement(AppRoutes.camera),
                    ),
                    const SizedBox(height: MlSpace.xs),
                    MlButton(
                      label: l10n.addOptionManual,
                      variant: MlButtonVariant.ghost,
                      height: 44,
                      onPressed: () =>
                          ImportFlows.startManual(context, replace: true),
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
