import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final demoScenarioProvider = Provider<DemoScenario>(
  (ref) => DemoScenario.fromName(const String.fromEnvironment('ML_SCENARIO')),
);
