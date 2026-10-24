import 'package:drift/drift.dart';

import '../../../infrastructure/database/app_database.dart';
import '../domain/category.dart';
import '../domain/category_repository.dart';

class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._db);

  final AppDatabase _db;

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
  Future<Category?> findById(String id) async {
    final row = await (_db.select(
      _db.categories,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
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
