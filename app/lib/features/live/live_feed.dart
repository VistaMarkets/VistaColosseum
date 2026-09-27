import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../design_system/design_system.dart';

/// Simulated live values for the demo: a few headline figures drift a
/// little every few seconds so the rolling digits have something to show.
/// Nothing here is market data. Off under `flutter test`, so tests stay
/// deterministic and leave no timers running.
class LiveFeed {
  LiveFeed._();

  static final _values = <String, ValueNotifier<double>>{};
  static final _steps = <String, double>{};
  static Timer? _timer;
  static final _random = math.Random(7);

  static bool get enabled => !Platform.environment.containsKey('FLUTTER_TEST');

  /// The live value for [key], starting at [base]. Each tick it moves by up
  /// to [step] either way.
  static ValueListenable<double> watch(String key, double base, double step) {
    _steps[key] = step;
    final v = _values.putIfAbsent(key, () => ValueNotifier(base));
    if (enabled) {
      _timer ??= Timer.periodic(const Duration(seconds: 3), (_) => _tick());
    }
    return v;
  }

  static void _tick() {
    for (final MapEntry(:key, :value) in _values.entries) {
      final step = _steps[key] ?? 0;
      // Mostly small moves, occasionally none.
      final move = (_random.nextDouble() * 2 - 1) * step;
      if (move.abs() < step * 0.1) continue;
      value.value += move;
    }
  }
}

/// Formats a dollar figure with thousands separators, e.g. $12,486 or
/// $67,412.50.
String formatUsd(double v, {int decimals = 0}) {
  final fixed = v.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final sign = v < 0 ? '−' : '';
  return '$sign\$$whole${parts.length > 1 ? '.${parts[1]}' : ''}';
}

/// Parses a dollar figure like "$2,968.40" or "−$13".
double parseUsd(String s) {
  final v = double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  return s.contains('−') || s.contains('-') ? -v : v;
}

/// A live dollar figure that rolls its digits as the feed moves it.
class LiveUsd extends StatelessWidget {
  const LiveUsd({
    super.key,
    required this.feedKey,
    required this.base,
    required this.step,
    required this.style,
    this.decimals = 0,
  });

  final String feedKey;
  final double base;
  final double step;
  final TextStyle style;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: LiveFeed.watch(feedKey, base, step),
      builder: (context, v, _) =>
          VistaRollingNumber(formatUsd(v, decimals: decimals), style: style),
    );
  }
}
