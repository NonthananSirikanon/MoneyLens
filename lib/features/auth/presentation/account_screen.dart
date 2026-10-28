import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_overlays.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../l10n/formatting.dart';
import '../../../l10n/l10n.dart';
import '../application/session.dart';
import '../domain/auth_models.dart';
import 'auth_widgets.dart';

/// Display name for a signed-in user: the username or Google name, otherwise
/// the email.
String accountName(AppUser? user, {required String fallback}) {
  if (user == null) return fallback;
  return user.displayName ?? user.username ?? user.email ?? fallback;
}

/// "บัญชีของฉัน": sign-in method, birth date, sign out.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showMlConfirmDialog(
      context,
      title: l10n.signOutTitle,
      body: l10n.signOutBody,
      confirmLabel: l10n.accountSignOut,
    );
    if (!ok || !context.mounted) return;
    await ref.read(sessionProvider.notifier).signOut();
    showMlToast(l10n.toastSignedOut);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(sessionProvider);
    final user = session.user;
    final name = accountName(user, fallback: l10n.profileFallbackName);
    final isPassword = user?.method == SignInMethod.password;
    final birth = session.birthDate;
    final fmt = context.dateFormat;

    return AuthPage(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: ListView(
        children: [
          Transform.translate(
            offset: const Offset(-8, 0),
            child: MlAppBar(
              title: l10n.accountTitle,
              onLeading: () => context.pop(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: MlColors.balance,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    name.characters.firstOrNull ?? '',
                    style: MlText.h1.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: MlText.h3.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  isPassword ? l10n.accountViaPassword : l10n.accountViaGoogle,
                  style: MlText.caption.copyWith(color: MlColors.textSecondary),
                ),
              ],
            ),
          ),
          MlListGroup(
            children: [
              MlListRow(
                icon: isPassword ? MlIcons.user : MlIcons.mail,
                label: isPassword ? l10n.accountUsername : l10n.accountEmail,
                value: isPassword
                    ? (user?.username ?? '')
                    : (user?.email ?? ''),
                chevron: false,
                onPressed: null,
              ),
              MlListRow(
                icon: MlIcons.calendar,
                label: l10n.accountBirth,
                value: birth == null ? '—' : fmt.dayMonthYear(birth),
                onPressed: () => context.push('${AppRoutes.birth}?edit=1'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MlListGroup(
            children: [
              MlListRow(
                icon: MlIcons.logOut,
                label: l10n.accountSignOut,
                sub: l10n.accountSignOutSub,
                danger: true,
                chevron: false,
                onPressed: () => _signOut(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
