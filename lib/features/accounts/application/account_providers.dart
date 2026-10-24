import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/clock.dart';
import '../../../core/utils/id_generator.dart';
import '../../../infrastructure/database/app_database.dart';
import '../data/drift_account_repository.dart';
import '../domain/account.dart';
import '../domain/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => DriftAccountRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  ),
);

final activeAccountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountRepositoryProvider).watchActive(),
);
