import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_models.dart';
import 'phone_number.dart';
import 'session.dart';

enum PhoneStep { enterNumber, enterCode }

@immutable
class PhoneSignInState {
  const PhoneSignInState({
    this.step = PhoneStep.enterNumber,
    this.digits = '',
    this.showNumberError = false,
    this.code = '',
    this.busy = false,
    this.wrongTries = 0,
    this.resendSeconds = 0,
    this.lockSeconds = 0,
    this.expired = false,
    this.failure,
  });

  final PhoneStep step;

  /// National digits without the leading 0 (`812345678`).
  final String digits;
  final bool showNumberError;
  final String code;

  /// Sending the code or checking it.
  final bool busy;
  final int wrongTries;
  final int resendSeconds;

  /// Seconds left of the client-side lock after too many wrong codes.
  final int lockSeconds;
  final bool expired;

  /// Last problem to show, cleared by the next edit.
  final AuthFailureKind? failure;

  bool get numberValid => ThaiPhone.isValid(digits);
  bool get locked => lockSeconds > 0;
  bool get codeWrong => failure == AuthFailureKind.invalidCode;

  int get triesLeft => PhoneSignInController.maxTries - wrongTries;

  PhoneSignInState copyWith({
    PhoneStep? step,
    String? digits,
    bool? showNumberError,
    String? code,
    bool? busy,
    int? wrongTries,
    int? resendSeconds,
    int? lockSeconds,
    bool? expired,
    AuthFailureKind? Function()? failure,
  }) => PhoneSignInState(
    step: step ?? this.step,
    digits: digits ?? this.digits,
    showNumberError: showNumberError ?? this.showNumberError,
    code: code ?? this.code,
    busy: busy ?? this.busy,
    wrongTries: wrongTries ?? this.wrongTries,
    resendSeconds: resendSeconds ?? this.resendSeconds,
    lockSeconds: lockSeconds ?? this.lockSeconds,
    expired: expired ?? this.expired,
    failure: failure == null ? this.failure : failure(),
  );
}

/// Phone + one-time-code sign-in. The provider is the real authority on
/// rate limits and expiry; the tries counter and lock here only keep the UI
/// honest and discourage guessing.
class PhoneSignInController extends Notifier<PhoneSignInState> {
  static const maxTries = 5;
  static const resendDelay = 45;
  static const lockDuration = 300;

  Timer? _timer;

  @override
  PhoneSignInState build() {
    ref.onDispose(() => _timer?.cancel());
    return const PhoneSignInState();
  }

  void setNumber(String input) => state = state.copyWith(
    digits: ThaiPhone.normalize(input),
    showNumberError: false,
    failure: () => null,
  );

  Future<void> sendCode() async {
    if (state.busy) return;
    if (!state.numberValid) {
      state = state.copyWith(showNumberError: true);
      return;
    }
    // Still locked from earlier wrong codes: do not hand out fresh tries.
    if (state.locked) {
      state = state.copyWith(step: PhoneStep.enterCode);
      return;
    }
    state = state.copyWith(busy: true, failure: () => null);
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPhoneOtp(ThaiPhone.toE164(state.digits));
    } on AuthFailure catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(busy: false, failure: () => e.kind);
      return;
    }
    if (!ref.mounted) return;
    state = state.copyWith(
      busy: false,
      step: PhoneStep.enterCode,
      code: '',
      wrongTries: 0,
      expired: false,
      resendSeconds: resendDelay,
    );
    _startTimer();
  }

  /// Back to the number field to change it.
  void changeNumber() => state = state.copyWith(
    step: PhoneStep.enterNumber,
    code: '',
    failure: () => null,
  );

  Future<void> setCode(String input) async {
    if (state.busy || state.locked || state.expired) return;
    final code = input.replaceAll(RegExp(r'\D'), '');
    final clipped = code.length > 6 ? code.substring(0, 6) : code;
    state = state.copyWith(
      code: clipped,
      failure: () => clipped.length < 6 ? null : state.failure,
    );
    if (clipped.length == 6) await verify();
  }

  Future<void> verify() async {
    if (state.busy || state.code.length != 6) return;
    state = state.copyWith(busy: true, failure: () => null);
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyPhoneOtp(ThaiPhone.toE164(state.digits), state.code);
      if (!ref.mounted) return;
      // Success: the session stream moves the router on.
      _timer?.cancel();
      state = state.copyWith(busy: false);
    } on AuthFailure catch (e) {
      if (!ref.mounted) return;
      switch (e.kind) {
        case AuthFailureKind.invalidCode:
          final tries = state.wrongTries + 1;
          state = state.copyWith(
            busy: false,
            wrongTries: tries,
            failure: () => e.kind,
            lockSeconds: tries >= maxTries ? lockDuration : state.lockSeconds,
          );
          if (tries >= maxTries) _startTimer();
        case AuthFailureKind.expiredCode:
          state = state.copyWith(busy: false, expired: true, code: '');
        default:
          state = state.copyWith(busy: false, failure: () => e.kind);
      }
    }
  }

  Future<void> resend() async {
    if (state.busy || state.resendSeconds > 0 || state.locked) return;
    state = state.copyWith(busy: true, failure: () => null);
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPhoneOtp(ThaiPhone.toE164(state.digits));
    } on AuthFailure catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(busy: false, failure: () => e.kind);
      return;
    }
    if (!ref.mounted) return;
    state = state.copyWith(
      busy: false,
      code: '',
      wrongTries: 0,
      expired: false,
      resendSeconds: resendDelay,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = state;
      final resend = s.resendSeconds > 0 ? s.resendSeconds - 1 : 0;
      final lock = s.lockSeconds > 0 ? s.lockSeconds - 1 : 0;
      state = s.copyWith(
        resendSeconds: resend,
        lockSeconds: lock,
        // When the lock ends the old code is considered used up.
        expired: s.lockSeconds == 1 ? true : s.expired,
        wrongTries: s.lockSeconds == 1 ? 0 : s.wrongTries,
        failure: () => s.lockSeconds == 1 ? null : s.failure,
      );
      if (resend == 0 && lock == 0) _timer?.cancel();
    });
  }
}

final phoneSignInProvider =
    NotifierProvider.autoDispose<PhoneSignInController, PhoneSignInState>(
      PhoneSignInController.new,
    );
