import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/clock.dart';
import '../../../core/utils/id_generator.dart';
import '../../../infrastructure/database/app_database.dart';
import '../data/drift_category_repository.dart';
import '../domain/category.dart';
import '../domain/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => DriftCategoryRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  ),
);

final activeCategoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchActive(),
);
