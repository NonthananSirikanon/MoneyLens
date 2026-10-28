import 'package:flutter/widgets.dart';

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

/// The user-facing message for a sign-in problem, or null when nothing needs
/// to be said (the user cancelled).
String? authFailureMessage(BuildContext context, AuthFailureKind kind) {
  final l10n = context.l10n;
  return switch (kind) {
    AuthFailureKind.cancelled => null,
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
