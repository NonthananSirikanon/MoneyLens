import 'dart:ui' show Color;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/category.dart';
import 'category_providers.dart';

/// Creates categories. The new category is visible in
/// [activeCategoriesProvider] when the call returns.
class CategoryActions {
  const CategoryActions(this._ref);

  final Ref _ref;

  Future<void> add({
    required String name,
    required CategoryKind kind,
    required String iconKey,
    required Color accent,
  }) async {
    await _ref
        .read(categoryRepositoryProvider)
        .create(
          name: name,
          kind: kind,
          iconKey: iconKey,
          colorValue: accent.toARGB32(),
        );
    await reloadCategories(_ref);
  }
}

final categoryActionsProvider = Provider<CategoryActions>(CategoryActions.new);
