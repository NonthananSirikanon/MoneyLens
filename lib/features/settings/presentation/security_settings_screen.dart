import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_preferences.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../l10n/l10n.dart';

/// "ความเป็นส่วนตัว". Face ID and the permission rows are SIMULATED: they
/// change in-memory preferences only (no biometric or permission plugin).
class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(appPreferencesProvider);
    final controller = ref.read(appPreferencesProvider.notifier);

    void togglePermission() {
      final granted = prefs.permissionsGranted;
      controller.setPermissionsGranted(!granted);
      showMlToast(
        granted ? l10n.toastPermissionRevoked : l10n.toastPermissionGranted,
      );
    }

    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Transform.translate(
              offset: const Offset(-8, 0),
              child: MlAppBar(
                title: l10n.securityTitle,
                onLeading: () => context.pop(),
              ),
            ),
            MlGroupTitle(l10n.securityGroupAccess, top: 12),
            MlListGroup(
              children: [
                MlListRow(
                  icon: MlIcons.scanFace,
                  label: l10n.securityFaceId,
                  sub: l10n.securityFaceIdSub,
                  badge: MlTag(l10n.p1Tag, tone: MlTagTone.p1),
                  toggle: prefs.faceId,
                  onPressed: controller.toggleFaceId,
                ),
                MlListRow(
                  icon: MlIcons.eyeOff,
                  label: l10n.securityHideBalances,
                  toggle: prefs.hideBalances,
                  onPressed: controller.toggleHideBalances,
                ),
              ],
            ),
            MlGroupTitle(l10n.securityGroupPermissions),
            MlListGroup(
              children: [
                MlListRow(
                  icon: MlIcons.camera,
                  label: l10n.securityCamera,
                  value: prefs.permissionsGranted
                      ? l10n.permissionAllowed
                      : l10n.permissionDenied,
                  onPressed: togglePermission,
                ),
                MlListRow(
                  icon: MlIcons.image,
                  label: l10n.securityPhotos,
                  value: prefs.permissionsGranted
                      ? l10n.permissionLimited
                      : l10n.permissionDenied,
                  onPressed: togglePermission,
                ),
              ],
            ),
            const SizedBox(height: MlSpace.md),
            MlBanner(
              tone: MlBannerTone.success,
              icon: MlIcons.shieldCheck,
              iconSize: 15,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              body: l10n.securityLocalNote,
            ),
          ],
        ),
      ),
    );
  }
}
