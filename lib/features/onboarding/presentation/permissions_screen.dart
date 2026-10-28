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
import '../../../core/widgets/ml_overlays.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../l10n/l10n.dart';

/// "ให้ MoneyLens อ่านสลิปได้". Permission is SIMULATED: "allow" records it
/// as granted, "later" as denied so the denied screens can be tried.
class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  void _finish(BuildContext context, WidgetRef ref, {required bool granted}) {
    ref
        .read(appPreferencesProvider.notifier)
        .finishOnboarding(permissionsGranted: granted);
    context.go(AppRoutes.home);
    if (granted) showMlToast(context.l10n.toastPermissionGranted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rows = [
      (MlIcons.camera, l10n.permissionCamera, l10n.permissionCameraBody, false),
      (MlIcons.image, l10n.permissionPhotos, l10n.permissionPhotosBody, false),
      (MlIcons.sparkles, l10n.permissionAuto, l10n.permissionAutoBody, true),
    ];
    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 52,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Illustration(MlImages.permission, height: 200),
                    const SizedBox(height: 20),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.permissionTitle,
                        style: MlText.h1.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.permissionBody,
                      style: MlText.small.copyWith(
                        color: MlColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    MlListGroup(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final (icon, title, body, soon) in rows)
                          Opacity(
                            opacity: soon ? 0.6 : 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  TintIcon(
                                    icon: icon,
                                    tint: MlColors.soft,
                                    size: 40,
                                    iconSize: 19,
                                    radius: MlRadius.md,
                                  ),
                                  const SizedBox(width: MlSpace.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(title, style: MlText.title),
                                        Text(
                                          body,
                                          style: MlText.caption.copyWith(
                                            color: MlColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (soon)
                                    MlTag(
                                      l10n.testingTag,
                                      tone: MlTagTone.warning,
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(height: 20),
                    MlButton(
                      label: l10n.permissionAllow,
                      fontWeight: FontWeight.w700,
                      onPressed: () => _finish(context, ref, granted: true),
                    ),
                    const SizedBox(height: 6),
                    MlButton(
                      label: l10n.permissionLater,
                      variant: MlButtonVariant.ghost,
                      height: 48,
                      onPressed: () => _finish(context, ref, granted: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
