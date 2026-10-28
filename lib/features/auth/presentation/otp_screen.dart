import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';

import '../../../app/theme/icons.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_fields.dart';
import '../../../core/widgets/ml_surfaces.dart';
import '../../../l10n/l10n.dart';
import '../application/phone_number.dart';
import '../application/phone_sign_in.dart';
import 'auth_widgets.dart';

/// "กรอกรหัส 6 หลัก". On success the session changes and the router moves
/// on to the birth-date screen.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = ref.watch(phoneSignInProvider);
    final c = ref.read(phoneSignInProvider.notifier);

    // Keep the invisible field in step with the state (cleared after an
    // expired code or a resend).
    if (_controller.text != s.code) {
      _controller.value = TextEditingValue(
        text: s.code,
        selection: TextSelection.collapsed(offset: s.code.length),
      );
    }

    final masked =
        '+66 ${s.digits.length >= 9 ? '${s.digits.substring(0, 2)} ••• ${s.digits.substring(5)}' : ThaiPhone.format(s.digits)}';
    final disabled = s.locked || s.expired;
    final failure = s.failure == null || s.codeWrong
        ? null
        : authFailureMessage(context, s.failure!);

    return AuthPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Transform.translate(
            offset: const Offset(-8, 0),
            child: MlAppBar(
              title: l10n.authOtpTitle,
              onLeading: () {
                c.changeNumber();
                context.pop();
              },
            ),
          ),
          const SizedBox(height: 4),
          AuthHeading(
            title: l10n.authOtpHeading,
            body: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: l10n.authOtpSentTo(masked)),
                  const TextSpan(text: ' · '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: FTappable(
                      semanticsLabel: l10n.authChangeNumber,
                      onPress: () {
                        c.changeNumber();
                        context.pop();
                      },
                      child: Text(
                        l10n.authChangeNumber,
                        style: MlText.smallM.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              style: MlText.small.copyWith(color: MlColors.textSecondary),
            ),
          ),
          const SizedBox(height: 20),
          OtpBoxes(
            code: s.code,
            error: s.codeWrong,
            disabled: disabled,
            input: Semantics(
              label: l10n.authOtpField,
              textField: true,
              child: _CodeField(
                controller: _controller,
                focus: _focus,
                onChanged: c.setCode,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (s.codeWrong)
            AuthError(l10n.authOtpWrong(s.triesLeft < 0 ? 0 : s.triesLeft)),
          if (failure != null) AuthError(failure),
          if (s.busy)
            Row(
              children: [
                const Icon(
                  MlIcons.loader,
                  size: 15,
                  color: MlColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.authVerifying,
                  style: MlText.meta.copyWith(
                    fontWeight: FontWeight.w400,
                    color: MlColors.textSecondary,
                  ),
                ),
              ],
            ),
          if (s.locked)
            MlBanner(
              tone: MlBannerTone.error,
              icon: MlIcons.circleAlert,
              title: l10n.authOtpLocked(clock(s.lockSeconds)),
            ),
          if (s.expired && !s.locked)
            MlBanner(
              tone: MlBannerTone.warning,
              icon: MlIcons.clock,
              title: l10n.authOtpExpiredTitle,
              body: l10n.authOtpExpiredBody,
            ),
          const SizedBox(height: 8),
          if (!s.expired && !s.locked)
            Center(
              child: s.resendSeconds > 0
                  ? Text(
                      l10n.authResendIn(clock(s.resendSeconds)),
                      style: MlText.meta.copyWith(
                        fontWeight: FontWeight.w400,
                        color: MlColors.textSecondary,
                      ),
                    )
                  : FTappable(
                      semanticsLabel: l10n.authResend,
                      onPress: c.resend,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          l10n.authResend,
                          style: MlText.smallM.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
            ),
          const Spacer(),
          if (s.expired && !s.locked)
            MlButton(
              label: l10n.authNewCode,
              icon: MlIcons.refreshCw,
              enabled: !s.busy,
              onPressed: c.resend,
            )
          else
            MlButton(
              label: l10n.authConfirm,
              enabled:
                  s.code.length == 6 && !s.codeWrong && !disabled && !s.busy,
              onPressed: c.verify,
            ),
        ],
      ),
    );
  }
}

/// The invisible numeric field behind the boxes.
class _CodeField extends StatelessWidget {
  const _CodeField({
    required this.controller,
    required this.focus,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => MlInput(
    controller: controller,
    focusNode: focus,
    autofocus: true,
    keyboardType: TextInputType.number,
    autofillHints: const [AutofillHints.oneTimeCode],
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(6),
    ],
    onChanged: onChanged,
    style: const TextStyle(fontSize: 1, color: Color(0x00000000)),
  );
}
