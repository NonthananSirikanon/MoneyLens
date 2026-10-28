import 'package:flutter/services.dart' show TextInputAction, TextInputType;
import 'package:flutter/widgets.dart';

import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/icons.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_fields.dart';
import '../../../l10n/l10n.dart';
import '../domain/auth_models.dart';

/// Page frame shared by the sign-in screens: app background, safe area and
/// the 20px gutter.
class AuthPage extends StatelessWidget {
  const AuthPage({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: MlColors.bgApp,
    child: SafeArea(
      child: Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: child,
      ),
    ),
  );
}

/// Large title + supporting line.
class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, this.body});

  final String title;
  final Widget? body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text(
          title,
          style: MlText.h1.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      if (body != null) ...[const SizedBox(height: 8), body!],
    ],
  );
}

/// The user-facing message for a sign-in problem, or null when nothing needs
/// to be said (the user cancelled).
String? authFailureMessage(BuildContext context, AuthFailureKind kind) {
  final l10n = context.l10n;
  return switch (kind) {
    AuthFailureKind.cancelled => null,
    AuthFailureKind.invalidCredentials => l10n.authErrInvalidCredentials,
    AuthFailureKind.usernameTaken => l10n.authErrUsernameTaken,
    AuthFailureKind.weakPassword => l10n.authErrWeakPassword,
    AuthFailureKind.tooManyRequests => l10n.authErrTooMany,
    AuthFailureKind.network => l10n.authErrNetwork,
    AuthFailureKind.unknown => l10n.authErrUnknown,
  };
}

/// Red help line used under auth fields.
class AuthError extends StatelessWidget {
  const AuthError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      MlHelpLine(text: text, tone: MlHelpTone.error);
}

/// The G mark on the Google button: a plain letter, not the brand artwork.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: MlColors.surface,
      border: Border.all(color: MlColors.border),
    ),
    child: Text(
      'G',
      style: MlText.amtS.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
    ),
  );
}

/// A labelled single-line field for the username / password forms. With
/// [secret] it hides the text and shows an eye button to reveal it.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.error,
    this.secret = false,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;

  /// Neutral help under the field, replaced by [error] when there is one.
  final String? hint;
  final String? error;
  final bool secret;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  var _revealed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasError = widget.error != null;
    return MlField(
      label: widget.label,
      help: widget.error ?? widget.hint,
      helpTone: hasError ? MlHelpTone.error : MlHelpTone.neutral,
      child: MlFieldBox(
        height: 52,
        state: hasError ? MlFieldState.error : MlFieldState.normal,
        padding: const EdgeInsets.only(left: 16, right: 6),
        child: Row(
          children: [
            Expanded(
              child: MlInput(
                controller: widget.controller,
                semanticLabel: widget.label,
                autofocus: widget.autofocus,
                obscureText: widget.secret && !_revealed,
                autofillHints: widget.autofillHints,
                textInputAction: widget.textInputAction,
                onSubmitted: widget.onSubmitted,
                onChanged: widget.onChanged,
                keyboardType: widget.secret
                    ? TextInputType.visiblePassword
                    : TextInputType.text,
                style: MlText.body,
              ),
            ),
            if (widget.secret)
              MlIconButton(
                icon: _revealed ? MlIcons.eyeOff : MlIcons.eye,
                semanticLabel: _revealed
                    ? l10n.authHidePassword
                    : l10n.authShowPassword,
                size: 40,
                iconSize: 18,
                onPressed: () => setState(() => _revealed = !_revealed),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Don't have an account? Register": a line of text with a link. Wraps
/// instead of overflowing on narrow screens and long translations.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.text,
    required this.link,
    required this.onPressed,
  });

  final String text;
  final String link;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 4,
    children: [
      Text(text, style: MlText.small.copyWith(color: MlColors.textSecondary)),
      MlTextLink(label: link, onPressed: onPressed),
    ],
  );
}
