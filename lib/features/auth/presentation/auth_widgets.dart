import 'package:flutter/widgets.dart';

import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
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

/// Six boxes showing a code. The real input is an invisible text field laid
/// over them, so the keyboard, one-time-code autofill and paste all work.
class OtpBoxes extends StatelessWidget {
  const OtpBoxes({
    super.key,
    required this.code,
    required this.input,
    this.error = false,
    this.disabled = false,
    this.focused = true,
  });

  final String code;

  /// The invisible field (an [MlInput] with zero opacity is added around it
  /// here).
  final Widget input;
  final bool error;
  final bool disabled;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final boxes = [
      for (var i = 0; i < 6; i++)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
            child: _box(i),
          ),
        ),
    ];
    return Stack(
      children: [
        Row(children: boxes),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: IgnorePointer(ignoring: disabled, child: input),
          ),
        ),
      ],
    );
  }

  Widget _box(int i) {
    final ch = i < code.length ? code[i] : '';
    final on = focused && !disabled && !error && i == code.length;
    final border = error
        ? Border.all(color: MlColors.error, width: 1.5)
        : on
        ? Border.all(color: MlColors.borderStrong, width: 1.5)
        : Border.all(color: MlColors.border);
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: disabled ? MlColors.soft : MlColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: Text(
        disabled ? '' : ch,
        style: MlText.amtL.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: error ? MlColors.amountExpense : MlColors.textPrimary,
        ),
      ),
    );
  }
}

/// The user-facing message for a sign-in problem, or null when nothing needs
/// to be said (the user cancelled).
String? authFailureMessage(BuildContext context, AuthFailureKind kind) {
  final l10n = context.l10n;
  return switch (kind) {
    AuthFailureKind.cancelled => null,
    AuthFailureKind.tooManyRequests => l10n.authErrTooMany,
    AuthFailureKind.network => l10n.authErrNetwork,
    AuthFailureKind.invalidCode ||
    AuthFailureKind.expiredCode ||
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

/// `mm:ss` for countdowns.
String clock(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

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

/// Shown icon for the sign-in method rows.
IconData methodIcon(SignInMethod m) =>
    m == SignInMethod.phone ? MlIcons.smartphone : MlIcons.mail;
