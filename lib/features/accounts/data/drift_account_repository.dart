import 'package:drift/drift.dart';

import '../../../core/dates/clock.dart';
import '../../../core/money/currency.dart';
import '../../../core/utils/id_generator.dart';
import '../../../infrastructure/database/app_database.dart';
import '../domain/account.dart';
import '../domain/account_repository.dart';

class DriftAccountRepository implements AccountRepository {
  DriftAccountRepository(this._db, this._clock, this._ids);

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  @override
  Stream<List<Account>> watchActive() {
    final query = _db.select(_db.accounts)
      ..where((a) => a.isArchived.equals(false))
      ..orderBy([(a) => OrderingTerm.asc(a.name)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<List<Account>> findActive() async {
    final rows =
        await (_db.select(_db.accounts)
              ..where((a) => a.isArchived.equals(false))
              ..orderBy([(a) => OrderingTerm.asc(a.name)]))
            .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<Account?> findById(String id) async {
    final row = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<Account> create({
    required String name,
    required AccountKind kind,
    required Currency currency,
    int? openingBalanceMinor,
    String? lastFour,
  }) async {
    final now = _clock.nowUtc();
    final row = await _db
        .into(_db.accounts)
        .insertReturning(
          AccountsCompanion.insert(
            id: _ids.newId(),
            name: name,
            kind: kind.dbValue,
            currencyCode: currency.code,
            openingBalanceMinor: Value(openingBalanceMinor),
            lastFour: Value(lastFour),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return _toDomain(row);
  }

  static Account _toDomain(AccountRow row) => Account(
    id: row.id,
    name: row.name,
    kind: AccountKind.fromDb(row.kind),
    currency:
        Currency.tryFromCode(row.currencyCode) ??
        (throw StateError('Stored account uses unsupported currency')),
    openingBalanceMinor: row.openingBalanceMinor,
    lastFour: row.lastFour,
    isArchived: row.isArchived,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
  );
}
