import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../l10n/l10n.dart';
import '../application/credentials.dart';
import '../application/session.dart';
import '../domain/auth_models.dart';
import 'auth_widgets.dart';

/// "ลงทะเบียน": choose a username and password, then continue to the
/// birth-date step like any other new sign-in.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _busy = false;
  var _submitted = false;
  AuthFailureKind? _failure;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  UsernameProblem? get _usernameProblem => Username.validate(_username.text);

  PasswordProblem? get _passwordProblem =>
      PasswordRules.validate(_password.text, confirm: _confirm.text);

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _submitted = true;
      _failure = null;
    });
    if (_usernameProblem != null || _passwordProblem != null) return;
    setState(() => _busy = true);
    try {
      // On success the session changes and the router moves on.
      await ref
          .read(authRepositoryProvider)
          .signUp(_username.text, _password.text);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _failure = e.kind);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final usernameError = _submitted
        ? switch (_usernameProblem) {
            UsernameProblem.empty => l10n.authUsernameEmpty,
            UsernameProblem.length => l10n.authUsernameLength,
            UsernameProblem.characters => l10n.authUsernameChars,
            null => null,
          }
        : null;
    final problem = _passwordProblem;
    final failure = _failure == null
        ? null
        : authFailureMessage(context, _failure!);
    final takenOrName = _failure == AuthFailureKind.usernameTaken
        ? failure
        : usernameError;
    final passwordError = _submitted && problem == PasswordProblem.tooShort
        ? l10n.authPasswordShort
        : (_failure == AuthFailureKind.weakPassword ? failure : null);
    final confirmError = _submitted && problem == PasswordProblem.mismatch
        ? l10n.authPasswordMismatch
        : null;
    final otherFailure =
        _failure == AuthFailureKind.usernameTaken ||
            _failure == AuthFailureKind.weakPassword
        ? null
        : failure;
    return AuthPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Transform.translate(
            offset: const Offset(-8, 0),
            child: MlAppBar(
              title: l10n.authRegister,
              onLeading: () => context.pop(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 4),
                AuthHeading(
                  title: l10n.authRegisterHeading,
                  body: Text(
                    l10n.authRegisterBody,
                    style: MlText.small.copyWith(color: MlColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _username,
                  label: l10n.authUsername,
                  hint: l10n.authUsernameHint,
                  error: takenOrName,
                  autofocus: true,
                  autofillHints: const [AutofillHints.newUsername],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _password,
                  label: l10n.authPassword,
                  hint: l10n.authPasswordHint,
                  error: passwordError,
                  secret: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _confirm,
                  label: l10n.authPasswordConfirm,
                  error: confirmError,
                  secret: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                if (otherFailure != null) ...[
                  MlBanner(
                    tone: MlBannerTone.info,
                    icon: MlIcons.wifiOff,
                    title: otherFailure,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      MlIcons.shield,
                      size: 16,
                      color: MlColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.authNoRecovery,
                        style: MlText.caption.copyWith(
                          color: MlColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MlButton(
            label: l10n.authRegister,
            enabled: !_busy,
            onPressed: _submit,
          ),
          const SizedBox(height: 6),
          AuthSwitchLink(
            text: l10n.authHaveAccount,
            link: l10n.authSignIn,
            onPressed: () => context.pushReplacement(AppRoutes.signIn),
          ),
        ],
      ),
    );
  }
}
