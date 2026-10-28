import 'category.dart';

abstract interface class CategoryRepository {
  /// Non-archived categories, optionally limited to one [kind].
  Stream<List<Category>> watchActive({CategoryKind? kind});

  /// One-shot read of non-archived categories.
  Future<List<Category>> findActive();

  Future<Category?> findById(String id);

  /// Creates a user category. [iconKey] is an app-owned identifier.
  Future<Category> create({
    required String name,
    required CategoryKind kind,
    String? iconKey,
    int? colorValue,
  });
}
