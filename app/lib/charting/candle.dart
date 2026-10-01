import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// One trading period in absolute prices, stamped with the time it opened.
@immutable
class Candle {
  const Candle(this.time, this.open, this.high, this.low, this.close);

  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  bool get rising => close >= open;

  /// This candle after a trade at [price]: the close moves and the range
  /// widens if the price breaks out of it.
  Candle trade(double price) =>
      Candle(time, open, math.max(high, price), math.min(low, price), price);
}

/// Lowest low and highest high across [candles].
(double, double) priceRange(Iterable<Candle> candles) {
  var lo = double.infinity;
  var hi = double.negativeInfinity;
  for (final c in candles) {
    lo = math.min(lo, c.low);
    hi = math.max(hi, c.high);
  }
  return (lo, hi);
}
