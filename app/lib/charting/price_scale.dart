import 'dart:math' as math;
import 'dart:ui';

import 'candle.dart';

/// Maps prices to heights inside a plot rectangle and back.
///
/// Anything drawn over a chart (grid, labels, the last-price line) goes
/// through the same scale as the candles, so it lands where they say it is.
class PriceScale {
  const PriceScale(this.min, this.max);

  /// Fits [candles] with a fraction of their range left empty above
  /// ([headroom]) and below ([footroom]).
  factory PriceScale.fit(
    Iterable<Candle> candles, {
    double headroom = 0.045,
    double footroom = 0.02,
  }) {
    var (lo, hi) = priceRange(candles);
    if (!lo.isFinite) return const PriceScale(0, 1);
    if (hi - lo < 1e-9) {
      // A flat series still needs a range to draw into.
      final pad = math.max(lo.abs() * 0.001, 1e-6);
      lo -= pad;
      hi += pad;
    }
    final span = hi - lo;
    return PriceScale(lo - span * footroom, hi + span * headroom);
  }

  final double min;
  final double max;

  double yFor(double price, Rect plot) =>
      plot.bottom - (price - min) / (max - min) * plot.height;

  double priceAt(double y, Rect plot) =>
      min + (plot.bottom - y) / plot.height * (max - min);
}

/// Gridline prices: multiples of a 1, 2, 2.5 or 5 step (times a power of
/// ten) inside [min]..[max], using the finest step that yields no more than
/// [maxTicks] lines. Returns the prices and the step.
(List<double>, double) roundTicks(double min, double max, {int maxTicks = 7}) {
  if (!(max > min) || maxTicks < 1) return (const [], 0);
  // Counting in whole steps keeps float drift out of the labels.
  int first(double step) => (min / step - 1e-9).ceil();
  int last(double step) => (max / step + 1e-9).floor();

  final raw = (max - min) / maxTicks;
  var e = (math.log(raw) / math.ln10).floor();
  for (; ; e++) {
    for (final m in const [1.0, 2.0, 2.5, 5.0]) {
      final step = m * math.pow(10, e);
      final lo = first(step);
      final hi = last(step);
      if (hi - lo + 1 <= maxTicks) {
        return ([for (var i = lo; i <= hi; i++) i * step], step);
      }
    }
  }
}

/// Decimal places needed to write multiples of [step] exactly.
int decimalsFor(double step) {
  for (var d = 0; d < 8; d++) {
    final scaled = step * math.pow(10, d);
    if ((scaled - scaled.roundToDouble()).abs() < 1e-6) return d;
  }
  return 8;
}

/// [value] with thousands separators and [decimals] places, no currency
/// sign: 67412.5 → "67,412.50".
String groupDigits(double value, int decimals) {
  final fixed = value.abs().toStringAsFixed(decimals);
  final dot = fixed.indexOf('.');
  final whole = dot < 0 ? fixed : fixed.substring(0, dot);
  final buf = StringBuffer(value < 0 ? '−' : '');
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
    buf.write(whole[i]);
  }
  if (dot >= 0) buf.write(fixed.substring(dot));
  return buf.toString();
}
