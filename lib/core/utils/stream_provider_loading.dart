import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Completes once [provider] has a value from its current subscription.
///
/// A provider nobody listens to is paused and never emits, so this listens
/// while it waits.
Future<void> firstValueOf<T>(Ref ref, StreamProvider<T> provider) async {
  final subscription = ref.listen(provider, (_, _) {});
  try {
    await ref.read(provider.future);
  } finally {
    subscription.close();
  }
}

/// Throws the provider's value away, subscribes again and completes once the
/// fresh value has arrived.
///
/// Replacing the subscription means a slower, older read can never overwrite
/// newer data.
Future<void> reloadStream<T>(Ref ref, StreamProvider<T> provider) {
  ref.invalidate(provider);
  return firstValueOf(ref, provider);
}
