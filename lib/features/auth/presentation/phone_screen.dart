import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/text_styles.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/ml_button.dart';
import '../../../core/widgets/ml_controls.dart';
import '../../../core/widgets/ml_fields.dart';
import '../../../l10n/l10n.dart';
import '../application/phone_number.dart';
import '../application/phone_sign_in.dart';
import 'auth_widgets.dart';

/// "กรอกเบอร์โทร": Thai mobile number, then the code is sent.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = ref.watch(phoneSignInProvider);
    final c = ref.read(phoneSignInProvider.notifier);

    // The code was sent: move to the next screen.
    ref.listen(phoneSignInProvider.select((s) => s.step), (prev, next) {
      if (prev == PhoneStep.enterNumber && next == PhoneStep.enterCode) {
        context.push(AppRoutes.otp);
      }
    });

    final showError = s.showNumberError && !s.numberValid;
    final failure = s.failure == null
        ? null
        : authFailureMessage(context, s.failure!);
    return AuthPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Transform.translate(
            offset: const Offset(-8, 0),
            child: MlAppBar(
              title: l10n.authPhoneTitle,
              onLeading: () => context.pop(),
            ),
          ),
          const SizedBox(height: 4),
          AuthHeading(
            title: l10n.authPhoneHeading,
            body: Text(
              l10n.authPhoneBody,
              style: MlText.small.copyWith(color: MlColors.textSecondary),
            ),
          ),
          const SizedBox(height: 20),
          MlField(
            label: l10n.authPhoneLabel,
            help: showError
                ? l10n.authPhoneError
                : (failure ?? l10n.authPhoneHint),
            helpTone: showError || failure != null
                ? MlHelpTone.error
                : MlHelpTone.neutral,
            child: MlFieldBox(
              height: 52,
              focused: !showError,
              state: showError ? MlFieldState.error : MlFieldState.normal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.only(right: 12),
                    margin: const EdgeInsets.only(right: 12),
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: MlColors.border)),
                    ),
                    child: Text(
                      'TH +66',
                      style: MlText.amtM.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: MlInput(
                      controller: _controller,
                      placeholder: '81 234 5678',
                      semanticLabel: l10n.authPhoneLabel,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [
                        AutofillHints.telephoneNumberNational,
                      ],
                      inputFormatters: const [ThaiPhoneFormatter()],
                      onChanged: c.setNumber,
                      style: MlText.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          MlButton(
            label: l10n.authSendCode,
            enabled: !s.busy,
            dimmed: !s.numberValid,
            onPressed: c.sendCode,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.authPhonePrivacy,
            textAlign: TextAlign.center,
            style: MlText.caption.copyWith(color: MlColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
