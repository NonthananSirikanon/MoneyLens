import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the app starts with the prototype's sample data: sample accounts
/// and transactions in the database, and the simulated slip queue, camera
/// and gallery. Off by default, so a normal run starts empty and only real
/// data is shown. Enable with
/// `flutter run --dart-define=ML_SAMPLE_DATA=true`.
final sampleDataEnabledProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment('ML_SAMPLE_DATA'),
);
