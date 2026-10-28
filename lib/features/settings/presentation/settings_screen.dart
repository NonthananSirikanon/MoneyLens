import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_preferences.dart';
import '../../../app/router.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../demo/demo_seed.dart';
import '../../../demo/demo_store.dart';
import '../../../l10n/l10n.dart';

/// App version shown in Settings (pubspec `version`).
const appVersion = '0.1.0';

/// "ตั้งค่า" tab.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(appPreferencesProvider);
    final prefsController = ref.read(appPreferencesProvider.notifier);
    final accounts = ref.watch(
      demoStoreProvider.select((s) => s.accounts.length),
    );
    final scans = ref.watch(demoStoreProvider.select((s) => s.scans.length));
    final theme = switch (prefs.theme) {
      ThemePreference.light => l10n.themeLight,
      ThemePreference.dark => l10n.themeDark,
      ThemePreference.system => l10n.themeSystem,
    };

    return ColoredBox(
      color: MlColors.bgApp,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, MlSpace.navClearance),
          children: [
            MlLargeTitle(l10n.settingsTitle),
            // The profile card has no action in the prototype.
            MlCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: MlColors.balance,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      demoProfileFullName.characters.first,
                      style: MlText.h2.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          demoProfileFullName,
                          style: MlText.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l10n.settingsProfile,
                          style: MlText.meta.copyWith(
                            fontWeight: FontWeight.w400,
                            color: MlColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            MlGroupTitle(l10n.settingsGroupFinance),
            MlListGroup(
              children: [
                MlListRow(
                  icon: MlIcons.shapes,
                  label: l10n.categoriesTitle,
                  onPressed: () => context.push(AppRoutes.categories),
                ),
                MlListRow(
                  icon: MlIcons.wallet,
                  label: l10n.accountsTitle,
                  value: '$accounts',
                  onPressed: () => context.push(AppRoutes.accounts),
                ),
                MlListRow(
                  icon: MlIcons.receipt,
                  label: l10n.settingsImportedSlips,
                  value: '$scans',
                  onPressed: () => context.push(AppRoutes.queue),
                ),
              ],
            ),
            MlGroupTitle(l10n.settingsGroupDisplay),
            MlListGroup(
              children: [
                MlListRow(
                  icon: MlIcons.sun,
                  label: l10n.settingsTheme,
                  value: theme,
                  onPressed: prefsController.cycleTheme,
                ),
                MlListRow(
                  icon: MlIcons.languages,
                  label: l10n.settingsLanguage,
                  value: l10n.languageName,
                  onPressed: prefsController.toggleLanguage,
                ),
                MlListRow(
                  icon: MlIcons.coins,
                  label: l10n.settingsCurrency,
                  value: 'THB',
                  onPressed: () => showMlToast(l10n.toastCurrencyOnly),
                ),
              ],
            ),
            MlGroupTitle(l10n.settingsGroupData),
            MlListGroup(
              children: [
                MlListRow(
                  icon: MlIcons.hardDrive,
                  label: l10n.settingsDataExport,
                  badge: MlTag(l10n.p1Tag, tone: MlTagTone.p1),
                  onPressed: () => context.push(AppRoutes.dataSettings),
                ),
                MlListRow(
                  icon: MlIcons.shield,
                  label: l10n.settingsPrivacy,
                  onPressed: () => context.push(AppRoutes.securitySettings),
                ),
                MlListRow(
                  icon: MlIcons.bell,
                  label: l10n.settingsNotifications,
                  toggle: prefs.notifications,
                  onPressed: prefsController.toggleNotifications,
                ),
                MlListRow(
                  icon: MlIcons.info,
                  label: l10n.settingsAbout,
                  value: appVersion,
                  onPressed: () {
                    prefsController.restartOnboarding();
                    context.go(AppRoutes.onboarding);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              l10n.settingsVersion(appVersion),
              textAlign: TextAlign.center,
              style: MlText.caption.copyWith(color: MlColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
