import 'package:flutter_riverpod/misc.dart' show Override;

import '../features/dashboard/application/home_view_providers.dart';
import '../features/transactions/application/transaction_view_providers.dart';

/// Demo states that the prototype exposes as preview props rather than
/// through visible UI. Choose one at launch with
/// `flutter run --dart-define=ML_SCENARIO=offline` (or `dbError`, `loading`), so no debug-only controls are added to the design.
enum DemoScenario {
  normal,

  /// Shows the offline banner on Home and a wifi-off state.
  offline,

  /// The transaction list fails to load (DB_READ_FAILED) until retried.
  dbError,

  /// The transaction list stays on its skeleton.
  loading;

  static DemoScenario fromName(String name) => values.firstWhere(
    (s) => s.name == name,
    orElse: () => DemoScenario.normal,
  );
}

/// Applies the `ML_SCENARIO` preview state to the screens that can show it.
/// With no scenario this changes nothing.
List<Override> scenarioOverrides() {
  final scenario = DemoScenario.fromName(
    const String.fromEnvironment('ML_SCENARIO'),
  );
  return [
    if (scenario == DemoScenario.offline)
      offlineBannerProvider.overrideWithValue(true),
    if (scenario == DemoScenario.loading)
      transactionLoadFaultProvider.overrideWithValue(
        TransactionLoadFault.staysLoading,
      ),
    if (scenario == DemoScenario.dbError)
      transactionLoadFaultProvider.overrideWithValue(
        TransactionLoadFault.failsFirstLoad,
      ),
  ];
}
