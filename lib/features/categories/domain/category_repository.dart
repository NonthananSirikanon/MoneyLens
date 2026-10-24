import 'category.dart';

abstract interface class CategoryRepository {
  /// Non-archived categories, optionally limited to one [kind].
  Stream<List<Category>> watchActive({CategoryKind? kind});

  Future<Category?> findById(String id);
}
