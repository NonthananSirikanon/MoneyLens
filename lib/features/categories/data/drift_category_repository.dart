import 'package:drift/drift.dart';

import '../../../core/dates/clock.dart';
import '../../../core/utils/id_generator.dart';
import '../../../infrastructure/database/app_database.dart';
import '../domain/category.dart';
import '../domain/category_repository.dart';

class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._db, this._clock, this._ids);

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  @override
  Stream<List<Category>> watchActive({CategoryKind? kind}) {
    final query = _db.select(_db.categories)
      ..where((c) {
        final active = c.isArchived.equals(false);
        return kind == null ? active : active & c.kind.equals(kind.dbValue);
      })
      ..orderBy([(c) => OrderingTerm.asc(c.name)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<List<Category>> findActive() async {
    final rows =
        await (_db.select(_db.categories)
              ..where((c) => c.isArchived.equals(false))
              ..orderBy([(c) => OrderingTerm.asc(c.name)]))
            .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<Category?> findById(String id) async {
    final row = await (_db.select(
      _db.categories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<Category> create({
    required String name,
    required CategoryKind kind,
    String? iconKey,
    int? colorValue,
  }) async {
    final now = _clock.nowUtc();
    final row = await _db
        .into(_db.categories)
        .insertReturning(
          CategoriesCompanion.insert(
            id: _ids.newId(),
            name: name,
            kind: kind.dbValue,
            iconKey: Value(iconKey),
            colorValue: Value(colorValue),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return _toDomain(row);
  }

  static Category _toDomain(CategoryRow row) => Category(
    id: row.id,
    name: row.name,
    kind: CategoryKind.fromDb(row.kind),
    iconKey: row.iconKey,
    colorValue: row.colorValue,
    isDefault: row.isDefault,
    isArchived: row.isArchived,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
  );
}
