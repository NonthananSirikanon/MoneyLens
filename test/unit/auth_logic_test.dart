import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/app/auth_redirect.dart';
import 'package:moneylens/features/auth/application/birth_date.dart';
import 'package:moneylens/features/auth/application/phone_number.dart';
import 'package:moneylens/features/auth/application/phone_sign_in.dart';
import 'package:moneylens/features/auth/application/session.dart';
import 'package:moneylens/features/auth/data/fake_auth_repository.dart';
import 'package:moneylens/features/auth/domain/auth_models.dart';

void main() {
  group('ThaiPhone', () {
    test('drops the leading 0, non-digits and extra digits', () {
      expect(ThaiPhone.normalize('081 234 5678'), '812345678');
      expect(ThaiPhone.normalize('0812345678999'), '812345678');
      expect(
        ThaiPhone.normalize('+66 81-234'),
        '6681234',
      ); // the +66 is typed digits
    });

    test('accepts nine digits starting with 6, 8 or 9 only', () {
      for (final ok in ['612345678', '812345678', '912345678']) {
        expect(ThaiPhone.isValid(ok), isTrue, reason: ok);
      }
      for (final bad in ['', '81234567', '712345678', '8123456789']) {
        expect(ThaiPhone.isValid(bad), isFalse, reason: bad);
      }
    });

    test('formats while typing and builds E.164', () {
      expect(ThaiPhone.format('8'), '8');
      expect(ThaiPhone.format('812'), '81 2');
      expect(ThaiPhone.format('812345678'), '81 234 5678');
      expect(ThaiPhone.toE164('812345678'), '+66812345678');
      const f = ThaiPhoneFormatter();
      final v = f.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '0812345678'),
      );
      expect(v.text, '81 234 5678');
    });

    test('masks an E.164 number for display', () {
      const u = AppUser(
        id: 'x',
        method: SignInMethod.phone,
        phone: '+66812345678',
      );
      expect(u.maskedPhone, '81 ••• 5678');
    });
  });

  group('BirthDateValidator', () {
    final today = DateTime(2026, 10, 24);
    BirthDateResult run(String d, int? m, String y) =>
        BirthDateValidator.validate(
          day: d,
          month: m,
          yearBuddhist: y,
          today: today,
        );

    test('accepts a real date and computes the age', () {
      final r = run('14', 3, '2540');
      expect(r.isValid, isTrue);
      expect(r.date, DateTime.utc(1997, 3, 14));
      expect(r.age, 29);
    });

    test('age counts the birthday only once it has passed', () {
      expect(run('24', 10, '2540').age, 29); // birthday today
      expect(run('25', 10, '2540').age, 28); // tomorrow
    });

    test('no minimum age: born today is fine', () {
      expect(run('24', 10, '2569').age, 0);
    });

    test('rejects missing fields and flags which ones', () {
      final r = run('', null, '2540');
      expect(r.error, BirthDateError.incomplete);
      expect(r.badDay, isTrue);
      expect(r.badMonth, isTrue);
      expect(r.badYear, isFalse);
    });

    test('rejects a year that is not four Buddhist digits', () {
      expect(run('1', 1, '97').error, BirthDateError.yearFormat);
      expect(run('1', 1, '1997').error, BirthDateError.yearFormat); // not B.E.
    });

    test('rejects dates that do not exist', () {
      expect(run('31', 2, '2540').error, BirthDateError.noSuchDate);
      expect(run('0', 2, '2540').error, BirthDateError.noSuchDate);
      expect(run('29', 2, '2544').error, BirthDateError.noSuchDate); // 2001
      expect(run('29', 2, '2544').badDay, isTrue);
    });

    test('leap years use the Gregorian year (B.E. - 543)', () {
      expect(run('29', 2, '2543').isValid, isTrue); // 2000
      expect(run('29', 2, '2544').isValid, isFalse); // 2001
    });

    test('rejects a date after today', () {
      expect(run('25', 10, '2569').error, BirthDateError.future);
      expect(run('1', 1, '2570').error, BirthDateError.future);
    });
  });

  group('authRedirect', () {
    String? go(String path, SessionStatus s, {bool done = true}) =>
        authRedirect(uri: Uri.parse(path), status: s, onboardingDone: done);

    test('signed out: only onboarding and sign-in', () {
      expect(go('/home', SessionStatus.signedOut), '/login');
      expect(go('/home', SessionStatus.signedOut, done: false), '/onboarding');
      for (final p in ['/login', '/phone', '/otp', '/onboarding']) {
        expect(go(p, SessionStatus.signedOut), isNull, reason: p);
      }
    });

    test('signed in without a birth date: only the birth screen', () {
      expect(go('/home', SessionStatus.needsBirthDate), '/birth');
      expect(go('/birth', SessionStatus.needsBirthDate), isNull);
    });

    test('ready: leaves the sign-in screens, edit stays open', () {
      expect(go('/login', SessionStatus.ready), '/home');
      expect(go('/otp', SessionStatus.ready, done: false), '/permissions');
      expect(go('/birth', SessionStatus.ready), '/home');
      expect(go('/birth?edit=1', SessionStatus.ready), isNull);
      expect(go('/home', SessionStatus.ready), isNull);
      expect(go('/onboarding', SessionStatus.ready), isNull); // replay
    });

    test('while loading nothing moves', () {
      expect(go('/home', SessionStatus.loading), isNull);
    });
  });

  group('SessionController', () {
    ProviderContainer container(FakeAuthRepository repo) {
      final c = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('signed out at start', () async {
      final c = container(FakeAuthRepository());
      await c.read(sessionProvider.notifier).initialized;
      expect(c.read(sessionProvider).status, SessionStatus.signedOut);
    });

    test('a returning user with a birth date is ready', () async {
      final repo = FakeAuthRepository(
        signedIn: const AppUser(
          id: 'u',
          method: SignInMethod.phone,
          phone: '+66812345678',
        ),
        birthDate: DateTime.utc(1997, 3, 14),
      );
      final c = container(repo);
      await c.read(sessionProvider.notifier).initialized;
      expect(c.read(sessionProvider).status, SessionStatus.ready);
      expect(c.read(sessionProvider).birthDate, DateTime.utc(1997, 3, 14));
    });

    test('a user without a birth date must give one, then is ready', () async {
      final repo = FakeAuthRepository(
        signedIn: const AppUser(
          id: 'u',
          method: SignInMethod.google,
          email: 'a@b.c',
        ),
      );
      final c = container(repo);
      final session = c.read(sessionProvider.notifier);
      await session.initialized;
      expect(c.read(sessionProvider).status, SessionStatus.needsBirthDate);

      await session.saveBirthDate(DateTime(1990, 5, 6));
      expect(c.read(sessionProvider).status, SessionStatus.ready);
      expect(repo.birthDate, DateTime.utc(1990, 5, 6));
    });

    test('signing out clears the session and the saved profile', () async {
      final repo = FakeAuthRepository(
        signedIn: const AppUser(
          id: 'u',
          method: SignInMethod.phone,
          phone: '+66812345678',
        ),
        birthDate: DateTime.utc(1997, 3, 14),
      );
      final c = container(repo);
      final session = c.read(sessionProvider.notifier);
      await session.initialized;
      await session.signOut();
      expect(c.read(sessionProvider).status, SessionStatus.signedOut);
      expect(c.read(sessionProvider).user, isNull);
    });

    test(
      'an offline profile check does not lock a returning user out',
      () async {
        final repo = _ProfileFails(
          signedIn: const AppUser(
            id: 'u',
            method: SignInMethod.phone,
            phone: '+66812345678',
          ),
        );
        final c = container(repo);
        await c.read(sessionProvider.notifier).initialized;
        expect(c.read(sessionProvider).status, SessionStatus.ready);
      },
    );

    test('signing in with the code moves a signed-out session along', () async {
      final repo = FakeAuthRepository();
      final c = container(repo);
      final session = c.read(sessionProvider.notifier);
      await session.initialized;
      await repo.verifyPhoneOtp('+66812345678', FakeAuthRepository.validCode);
      await pumpEventQueue();
      expect(c.read(sessionProvider).status, SessionStatus.needsBirthDate);
    });
  });

  group('PhoneSignInController', () {
    ProviderContainer container([FakeAuthRepository? repo]) {
      final c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            repo ?? FakeAuthRepository(),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.listen(phoneSignInProvider, (_, _) {});
      return c;
    }

    PhoneSignInController ctl(ProviderContainer c) =>
        c.read(phoneSignInProvider.notifier);
    PhoneSignInState st(ProviderContainer c) => c.read(phoneSignInProvider);

    test('an invalid number is not sent and shows its error', () async {
      final repo = FakeAuthRepository();
      final c = container(repo);
      ctl(c).setNumber('8123');
      await ctl(c).sendCode();
      expect(st(c).showNumberError, isTrue);
      expect(st(c).step, PhoneStep.enterNumber);
      expect(repo.sentTo, isEmpty);
    });

    test('a valid number sends E.164 and starts the resend timer', () async {
      final repo = FakeAuthRepository();
      final c = container(repo);
      ctl(c).setNumber('0812345678');
      await ctl(c).sendCode();
      expect(repo.sentTo, ['+66812345678']);
      expect(st(c).step, PhoneStep.enterCode);
      expect(st(c).resendSeconds, 45);
    });

    test('a wrong code counts down the tries, then locks', () async {
      final c = container();
      ctl(c).setNumber('812345678');
      await ctl(c).sendCode();
      for (var i = 1; i <= 4; i++) {
        await ctl(c).setCode('00000$i');
        expect(st(c).codeWrong, isTrue);
        expect(st(c).triesLeft, 5 - i);
        await ctl(c).setCode('0000'); // editing clears the error
        expect(st(c).codeWrong, isFalse);
      }
      await ctl(c).setCode('000009');
      expect(st(c).locked, isTrue);
      // While locked, a correct code is not even tried.
      await ctl(c).setCode(FakeAuthRepository.validCode);
      expect(st(c).code, '000009');
    });

    test('the lock does not reset by sending the code again', () async {
      final c = container();
      ctl(c).setNumber('812345678');
      await ctl(c).sendCode();
      for (var i = 0; i < 5; i++) {
        await ctl(c).setCode('00000$i');
        await ctl(c).setCode('0');
      }
      expect(st(c).locked, isTrue);
      await ctl(c).sendCode();
      expect(st(c).locked, isTrue);
      expect(st(c).wrongTries, 5);
    });

    test('the right code signs in', () async {
      final repo = FakeAuthRepository();
      final c = container(repo);
      ctl(c).setNumber('812345678');
      await ctl(c).sendCode();
      await ctl(c).setCode(FakeAuthRepository.validCode);
      expect(repo.currentUser?.phone, '+66812345678');
    });

    test(
      'rate limiting and offline show a failure, not a new screen',
      () async {
        final repo = FakeAuthRepository(
          sendFailure: AuthFailureKind.tooManyRequests,
        );
        final c = container(repo);
        ctl(c).setNumber('812345678');
        await ctl(c).sendCode();
        expect(st(c).failure, AuthFailureKind.tooManyRequests);
        expect(st(c).step, PhoneStep.enterNumber);
      },
    );

    test('resend is blocked until the countdown ends', () {
      fakeAsync((async) {
        final repo = FakeAuthRepository();
        final c = container(repo);
        ctl(c).setNumber('812345678');
        ctl(c).sendCode();
        async.flushMicrotasks();
        ctl(c).resend();
        async.flushMicrotasks();
        expect(repo.sentTo.length, 1);

        async.elapse(const Duration(seconds: 45));
        expect(st(c).resendSeconds, 0);
        ctl(c).resend();
        async.flushMicrotasks();
        expect(repo.sentTo.length, 2);
        expect(st(c).resendSeconds, 45);
      });
    });
  });
}

class _ProfileFails extends FakeAuthRepository {
  _ProfileFails({super.signedIn});

  @override
  Future<DateTime?> fetchBirthDate() async =>
      throw const AuthFailure(AuthFailureKind.network);
}
