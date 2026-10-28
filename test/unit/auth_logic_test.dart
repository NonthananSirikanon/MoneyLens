import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/app/auth_redirect.dart';
import 'package:moneylens/features/auth/application/birth_date.dart';
import 'package:moneylens/features/auth/application/credentials.dart';
import 'package:moneylens/features/auth/application/session.dart';
import 'package:moneylens/features/auth/data/fake_auth_repository.dart';
import 'package:moneylens/features/auth/domain/auth_models.dart';

void main() {
  group('Username', () {
    test('is lower-cased and trimmed', () {
      expect(Username.normalize('  SomChai_01 '), 'somchai_01');
    });

    test('accepts 3-20 letters, digits and underscores', () {
      for (final ok in ['abc', 'somchai_01', 'a' * 20, 'ABC']) {
        expect(Username.validate(ok), isNull, reason: ok);
      }
    });

    test('says what is wrong', () {
      expect(Username.validate('  '), UsernameProblem.empty);
      expect(Username.validate('ab'), UsernameProblem.length);
      expect(Username.validate('a' * 21), UsernameProblem.length);
      for (final bad in ['som chai', 'สมชาย', 'a.b.c', 'a@b']) {
        expect(Username.validate(bad), UsernameProblem.characters, reason: bad);
      }
    });

    test('maps to an internal email and back', () {
      expect(Username.authEmail(' SomChai '), 'somchai@users.moneylens.app');
      expect(Username.fromAuthEmail('somchai@users.moneylens.app'), 'somchai');
      expect(Username.fromAuthEmail('a@gmail.com'), isNull);
      expect(Username.fromAuthEmail(null), isNull);
    });
  });

  group('PasswordRules', () {
    test('needs 8 characters and a matching confirmation', () {
      expect(PasswordRules.validate('1234567'), PasswordProblem.tooShort);
      expect(PasswordRules.validate('12345678'), isNull);
      expect(
        PasswordRules.validate('12345678', confirm: '12345679'),
        PasswordProblem.mismatch,
      );
      expect(PasswordRules.validate('12345678', confirm: '12345678'), isNull);
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
      for (final p in ['/login', '/signin', '/register', '/onboarding']) {
        expect(go(p, SessionStatus.signedOut), isNull, reason: p);
      }
    });

    test('signed in without a birth date: only the birth screen', () {
      expect(go('/home', SessionStatus.needsBirthDate), '/birth');
      expect(go('/birth', SessionStatus.needsBirthDate), isNull);
    });

    test('ready: leaves the sign-in screens, edit stays open', () {
      expect(go('/login', SessionStatus.ready), '/home');
      expect(go('/register', SessionStatus.ready, done: false), '/permissions');
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
          method: SignInMethod.password,
          username: 'somchai',
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
          method: SignInMethod.password,
          username: 'somchai',
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
            method: SignInMethod.password,
            username: 'somchai',
          ),
        );
        final c = container(repo);
        await c.read(sessionProvider.notifier).initialized;
        expect(c.read(sessionProvider).status, SessionStatus.ready);
      },
    );

    test('registering moves a signed-out session along', () async {
      final repo = FakeAuthRepository();
      final c = container(repo);
      final session = c.read(sessionProvider.notifier);
      await session.initialized;
      await repo.signUp('Somchai', 'password1');
      await pumpEventQueue();
      expect(c.read(sessionProvider).status, SessionStatus.needsBirthDate);
      expect(c.read(sessionProvider).user?.username, 'somchai');
    });
  });

  group('FakeAuthRepository', () {
    test('a name can only be registered once, in any letter case', () async {
      final repo = FakeAuthRepository();
      await repo.signUp('somchai', 'password1');
      await repo.signOut();
      await expectLater(
        repo.signUp('SomChai', 'other-password'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.kind,
            'kind',
            AuthFailureKind.usernameTaken,
          ),
        ),
      );
    });

    test('sign-in needs the right name and password', () async {
      final repo = FakeAuthRepository(accounts: {'somchai': 'password1'});
      for (final (name, pass) in [
        ('somchai', 'wrong-pass'),
        ('nobody', 'password1'),
      ]) {
        await expectLater(
          repo.signInWithPassword(name, pass),
          throwsA(
            isA<AuthFailure>().having(
              (e) => e.kind,
              'kind',
              AuthFailureKind.invalidCredentials,
            ),
          ),
        );
        expect(repo.currentUser, isNull);
      }
      await repo.signInWithPassword(' SomChai ', 'password1');
      expect(repo.currentUser?.username, 'somchai');
    });
  });
}

class _ProfileFails extends FakeAuthRepository {
  _ProfileFails({super.signedIn});

  @override
  Future<DateTime?> fetchBirthDate() async =>
      throw const AuthFailure(AuthFailureKind.network);
}
