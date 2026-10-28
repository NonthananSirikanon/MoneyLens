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
import '../../sync/application/sync_controller.dart';
import '../application/account_deletion.dart';
import '../application/session.dart';
import '../domain/auth_models.dart';
import 'auth_widgets.dart';

/// Display name for a signed-in user: the Google name, otherwise the email.
String accountName(AppUser? user, {required String fallback}) {
  if (user == null) return fallback;
  return user.displayName ?? user.email ?? fallback;
}

/// "บัญชีของฉัน": sign-in method, birth date, sign out.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  var _deleting = false;

  /// Two confirmations, then the server and the device are cleared. Nothing is
  /// deleted unless the server confirms, so being offline only shows a message.
  Future<void> _deleteAccount() async {
    if (_deleting) return;
    final l10n = context.l10n;
    final first = await showMlConfirmDialog(
      context,
      title: l10n.deleteAccountTitle,
      body: l10n.deleteAccountBody,
      confirmLabel: l10n.deleteAccountAction,
    );
    if (!first || !mounted) return;
    final second = await showMlConfirmDialog(
      context,
      title: l10n.deleteAccountAgainTitle,
      body: l10n.deleteAccountAgainBody,
      confirmLabel: l10n.deleteAccountAgainAction,
    );
    if (!second || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(accountDeletionProvider).run();
      // The session is gone, so the router moves to the sign-in screen.
      showMlToast(l10n.toastAccountDeleted);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      showMlToast(
        e.kind == AuthFailureKind.network
            ? l10n.accountDeleteNeedsInternet
            : (authFailureMessage(context, e.kind) ?? l10n.authErrUnknown),
      );
    } on Object {
      // Anything unexpected must not look like "nothing happened".
      if (!mounted) return;
      showMlToast(l10n.authErrUnknown);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(sessionProvider);
    final user = session.user;
    final name = accountName(user, fallback: l10n.profileFallbackName);
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
                  l10n.accountViaGoogle,
                  style: MlText.caption.copyWith(color: MlColors.textSecondary),
                ),
              ],
            ),
          ),
          MlListGroup(
            children: [
              MlListRow(
                icon: MlIcons.mail,
                label: l10n.accountEmail,
                value: user?.email ?? '',
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
          const _SyncRow(),
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
              MlListRow(
                icon: MlIcons.trash2,
                label: _deleting ? l10n.accountDeleting : l10n.accountDelete,
                sub: l10n.accountDeleteSub,
                danger: true,
                chevron: false,
                onPressed: _deleting ? null : _deleteAccount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sync status with a "sync now" tap. Hidden when sync is not running (no
/// server configured).
class _SyncRow extends ConsumerWidget {
  const _SyncRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sync = ref.watch(syncControllerProvider);
    if (sync.phase == SyncPhase.disabled) return const SizedBox.shrink();

    String two(int n) => n.toString().padLeft(2, '0');
    final last = sync.lastSyncedAt?.toLocal();
    final text = switch (sync.phase) {
      SyncPhase.syncing => l10n.syncRunning,
      SyncPhase.offline => l10n.syncOffline,
      SyncPhase.failed => l10n.syncFailed,
      _ when sync.pending > 0 => l10n.syncPending(sync.pending),
      _ when last != null => l10n.syncDone(
        '${two(last.hour)}:${two(last.minute)}',
      ),
      _ => l10n.syncNever,
    };
    return MlListGroup(
      children: [
        MlListRow(
          icon: MlIcons.refreshCw,
          label: l10n.syncTitle,
          sub: text,
          chevron: false,
          onPressed: sync.phase == SyncPhase.syncing
              ? null
              : () => ref.read(syncControllerProvider.notifier).syncNow(),
        ),
      ],
    );
  }
}
