import 'dart:math' as math;

import 'candle.dart';

/// A made-up but repeatable candle history that ends exactly on [last].
///
/// Closes follow a random walk of normally distributed log returns, built
/// backwards from [last] so the chart always agrees with the quoted price.
/// Volatility grows with the square root of [period], so a daily chart
/// moves more per candle than a 1m one. The same [key] always produces the
/// same history. Simulated; not market data.
List<Candle> sampleCandles({
  required String key,
  required double last,
  required Duration period,
  required DateTime end,
  int count = 40,
  double volatilityPer15m = 0.0012,
}) {
  final rng = math.Random(
    key.codeUnits.fold<int>(17, (h, c) => (h * 31 + c) & 0x7fffffff),
  );
  double gaussian() {
    // Box–Muller.
    final u = 1 - rng.nextDouble();
    final v = rng.nextDouble();
    return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
  }

  final sigma = volatilityPer15m * math.sqrt(period.inMinutes / 15);
  final closes = List<double>.filled(count, last);
  for (var i = count - 1; i > 0; i--) {
    closes[i - 1] = closes[i] / math.exp(gaussian() * sigma);
  }
  final firstOpen = closes.first / math.exp(gaussian() * sigma);

  return [
    for (var i = 0; i < count; i++)
      () {
        final open = i == 0 ? firstOpen : closes[i - 1];
        final close = closes[i];
        final top = math.max(open, close);
        final bottom = math.min(open, close);
        return Candle(
          end.subtract(period * (count - 1 - i)),
          open,
          top * (1 + gaussian().abs() * sigma * 0.5),
          bottom * (1 - gaussian().abs() * sigma * 0.5),
          close,
        );
      }(),
  ];
}
