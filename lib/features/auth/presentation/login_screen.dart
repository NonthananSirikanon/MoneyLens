import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_badges.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../l10n/l10n.dart';
import '../application/session.dart';
import '../domain/auth_models.dart';
import 'auth_widgets.dart';

/// "เริ่มต้นกับ MoneyLens": sign in with a username, register, or use Google. There is no way to skip
/// (sign-in is required).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  var _busy = false;
  AuthFailureKind? _failure;

  Future<void> _google() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _failure = e.kind);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = _failure == null
        ? null
        : authFailureMessage(context, _failure!);
    return AuthPage(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (message != null) ...[
                    MlBanner(
                      tone: MlBannerTone.info,
                      icon: MlIcons.wifiOff,
                      title: message,
                    ),
                    const SizedBox(height: 14),
                  ],
                  const Center(child: Illustration(MlImages.hero, height: 250)),
                  const SizedBox(height: 14),
                  Text(
                    l10n.authLoginTitle,
                    style: MlText.hero.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.authLoginBody,
                    style: MlText.body.copyWith(color: MlColors.textSecondary),
                  ),
                  const Spacer(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        MlIcons.shield,
                        size: 16,
                        color: MlColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.authLocalNote,
                          style: MlText.caption.copyWith(
                            color: MlColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  MlButton(
                    label: l10n.authWithPassword,
                    icon: MlIcons.user,
                    enabled: !_busy,
                    onPressed: () => context.push(AppRoutes.signIn),
                  ),
                  const SizedBox(height: 10),
                  MlButton(
                    label: l10n.authWithGoogle,
                    variant: MlButtonVariant.outline,
                    leading: const GoogleMark(),
                    enabled: !_busy,
                    onPressed: _google,
                  ),
                  const SizedBox(height: 4),
                  AuthSwitchLink(
                    text: l10n.authNoAccount,
                    link: l10n.authRegister,
                    onPressed: () => context.push(AppRoutes.register),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.authTerms,
                    textAlign: TextAlign.center,
                    style: MlText.caption.copyWith(
                      color: MlColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
