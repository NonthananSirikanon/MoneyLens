/// Whether the app starts with the prototype's sample data: sample accounts
/// and transactions in the database, and the simulated slip queue, camera
/// and gallery. Off by default, so a normal run starts empty and only real
/// data is shown. Enable with
/// `flutter run --dart-define=ML_SAMPLE_DATA=true`.
///
/// Only `main` reads this, to decide whether to pass `demoOverrides()`; no
/// other code branches on it.
const sampleDataEnabled = bool.fromEnvironment('ML_SAMPLE_DATA');
