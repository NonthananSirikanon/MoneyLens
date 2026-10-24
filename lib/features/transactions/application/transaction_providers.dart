import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates/clock.dart';
import '../../../core/utils/id_generator.dart';
import '../../../infrastructure/database/app_database.dart';
import '../../accounts/application/account_providers.dart';
import '../../categories/application/category_providers.dart';
import '../data/drift_transaction_repository.dart';
import '../domain/transaction.dart';
import '../domain/transaction_repository.dart';
import 'create_transaction.dart';
import 'transaction_draft_checker.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => DriftTransactionRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(clockProvider),
    ref.watch(idGeneratorProvider),
  ),
);

final transactionDraftCheckerProvider = Provider<TransactionDraftChecker>(
  (ref) => TransactionDraftChecker(
    ref.watch(accountRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  ),
);

final createTransactionProvider = Provider<CreateTransaction>(
  (ref) => CreateTransaction(
    ref.watch(transactionDraftCheckerProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);

/// Transaction history, newest first.
final transactionHistoryProvider = StreamProvider<List<MoneyTransaction>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchRecent(limit: 200),
);
