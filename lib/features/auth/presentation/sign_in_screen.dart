import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../l10n/l10n.dart';
import '../application/session.dart';
import '../domain/auth_models.dart';
import 'auth_widgets.dart';

/// "เข้าสู่ระบบ": username and password.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;
  var _submitted = false;
  AuthFailureKind? _failure;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _submitted = true;
      _failure = null;
    });
    if (_username.text.trim().isEmpty || _password.text.isEmpty) return;
    setState(() => _busy = true);
    try {
      // On success the session changes and the router leaves this screen.
      await ref
          .read(authRepositoryProvider)
          .signInWithPassword(_username.text, _password.text);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _failure = e.kind);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = _failure == null
        ? null
        : authFailureMessage(context, _failure!);
    return AuthPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Transform.translate(
            offset: const Offset(-8, 0),
            child: MlAppBar(
              title: l10n.authSignIn,
              onLeading: () => context.pop(),
            ),
          ),
          const SizedBox(height: 4),
          AuthHeading(
            title: l10n.authSignInHeading,
            body: Text(
              l10n.authSignInBody,
              style: MlText.small.copyWith(color: MlColors.textSecondary),
            ),
          ),
          const SizedBox(height: 20),
          AuthTextField(
            controller: _username,
            label: l10n.authUsername,
            autofocus: true,
            autofillHints: const [AutofillHints.username],
            textInputAction: TextInputAction.next,
            error: _submitted && _username.text.trim().isEmpty
                ? l10n.authUsernameEmpty
                : null,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: _password,
            label: l10n.authPassword,
            secret: true,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            error: _submitted && _password.text.isEmpty
                ? l10n.authPasswordEmpty
                : failure,
          ),
          const Spacer(),
          MlButton(label: l10n.authSignIn, enabled: !_busy, onPressed: _submit),
          const SizedBox(height: 6),
          AuthSwitchLink(
            text: l10n.authNoAccount,
            link: l10n.authRegister,
            onPressed: () => context.pushReplacement(AppRoutes.register),
          ),
        ],
      ),
    );
  }
}
