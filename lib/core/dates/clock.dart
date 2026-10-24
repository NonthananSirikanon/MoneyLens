import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source of the current instant, injectable so date rules are testable.
abstract interface class Clock {
  DateTime nowUtc();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

final clockProvider = Provider<Clock>((ref) => const SystemClock());
