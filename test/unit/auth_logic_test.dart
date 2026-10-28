import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneylens/app/auth_redirect.dart';
import 'package:moneylens/features/auth/application/birth_date.dart';
import 'package:moneylens/features/auth/application/local_data_eraser.dart';
import 'package:moneylens/features/auth/application/session.dart';
import 'package:moneylens/features/auth/data/fake_auth_repository.dart';
import 'package:moneylens/features/auth/domain/auth_models.dart';
import 'package:moneylens/infrastructure/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

import '../support/test_support.dart';

void main() {
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
      for (final p in ['/login', '/onboarding']) {
        expect(go(p, SessionStatus.signedOut), isNull, reason: p);
      }
    });

    test('signed in without a birth date: only the birth screen', () {
      expect(go('/home', SessionStatus.needsBirthDate), '/birth');
      expect(go('/birth', SessionStatus.needsBirthDate), isNull);
    });

    test('ready: leaves the sign-in screens, edit stays open', () {
      expect(go('/login', SessionStatus.ready), '/home');
      expect(go('/login', SessionStatus.ready, done: false), '/permissions');
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
          method: SignInMethod.google,
          email: 'a@b.c',
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
          method: SignInMethod.google,
          email: 'a@b.c',
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
            method: SignInMethod.google,
            email: 'a@b.c',
          ),
        );
        final c = container(repo);
        await c.read(sessionProvider.notifier).initialized;
        expect(c.read(sessionProvider).status, SessionStatus.ready);
      },
    );

    test('signing in with Google moves a signed-out session along', () async {
      final repo = FakeAuthRepository();
      final c = container(repo);
      final session = c.read(sessionProvider.notifier);
      await session.initialized;
      await repo.signInWithGoogle();
      await pumpEventQueue();
      expect(c.read(sessionProvider).status, SessionStatus.needsBirthDate);
    });
  });
  group('SessionController.deleteAccount', () {
    const user = AppUser(id: 'u1', method: SignInMethod.google, email: 'a@b.c');

    Future<({ProviderContainer c, AppDatabase db, RecordingEraser eraser})>
    setUpDeletion(FakeAuthRepository repo) async {
      final db = openTestDatabase();
      final eraser = RecordingEraser();
      final c = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          appDatabaseProvider.overrideWithValue(db),
          localDataEraserProvider.overrideWithValue(eraser),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await c.read(sessionProvider.notifier).initialized;
      return (c: c, db: db, eraser: eraser);
    }

    Future<void> addSlip(AppDatabase db, String id, String path) => db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            type: 'expense',
            amountMinor: 100,
            currencyCode: 'THB',
            accountId: 'default-cash',
            occurredAt: DateTime.utc(2026, 10, 1),
            source: 'manual',
            createdAt: DateTime.utc(2026, 10, 1),
            updatedAt: DateTime.utc(2026, 10, 1),
            attachmentPath: Value(path),
          ),
        );

    test('deletes the account, then erases the device', () async {
      final repo = FakeAuthRepository(
        signedIn: user,
        birthDate: DateTime.utc(1997, 3, 14),
      );
      final t = await setUpDeletion(repo);
      await addSlip(t.db, 'tx-1', 'slips/a.jpg');
      await addSlip(t.db, 'tx-2', 'assets/images/receipt.png');

      await t.c.read(sessionProvider.notifier).deleteAccount();

      expect(repo.accountDeleted, isTrue);
      expect(t.c.read(sessionProvider).status, SessionStatus.signedOut);
      expect(t.eraser.erased.single.userId, 'u1');
      // Only real files; the bundled sample image is never a file to erase.
      expect(t.eraser.erased.single.slipPaths, ['slips/a.jpg']);
    });

    test('offline: nothing is deleted anywhere', () async {
      final repo = FakeAuthRepository(
        signedIn: user,
        birthDate: DateTime.utc(1997, 3, 14),
        failure: AuthFailureKind.network,
      );
      final t = await setUpDeletion(repo);
      await addSlip(t.db, 'tx-1', 'slips/a.jpg');

      await expectLater(
        t.c.read(sessionProvider.notifier).deleteAccount(),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.kind,
            'kind',
            AuthFailureKind.network,
          ),
        ),
      );
      expect(repo.accountDeleted, isFalse);
      expect(t.c.read(sessionProvider).status, SessionStatus.ready);
      expect(t.eraser.erased, isEmpty);
    });
  });
}

class _ProfileFails extends FakeAuthRepository {
  _ProfileFails({super.signedIn});

  @override
  Future<DateTime?> fetchBirthDate() async =>
      throw const AuthFailure(AuthFailureKind.network);
}
