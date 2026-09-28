import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vista_colosseum/charting/charting.dart';

void main() {
  group('roundTicks', () {
    test('BTC range lands on hundreds', () {
      final (ticks, step) = roundTicks(66946, 67615);
      expect(step, 100);
      expect(ticks, [67000, 67100, 67200, 67300, 67400, 67500, 67600]);
    });

    test('uses 2.5 steps and stays within the limit', () {
      final (ticks, step) = roundTicks(0, 0.001, maxTicks: 5);
      expect(step, closeTo(0.00025, 1e-12));
      expect(ticks.length, 5);
      expect(decimalsFor(step), 5);
      expect(roundTicks(0, 1000, maxTicks: 4).$1.length, lessThanOrEqualTo(4));
    });

    test('empty range gives no ticks', () {
      expect(roundTicks(5, 5).$1, isEmpty);
    });
  });

  test('PriceScale maps both ways and fits with headroom', () {
    final t = DateTime(2026);
    final scale = PriceScale.fit([Candle(t, 100, 110, 90, 105)]);
    expect(scale.max, greaterThan(110));
    expect(scale.min, lessThan(90));
    const plot = Rect.fromLTWH(0, 20, 100, 200);
    expect(scale.priceAt(scale.yFor(97, plot), plot), closeTo(97, 1e-9));
    expect(scale.yFor(scale.min, plot), plot.bottom);
  });

  test('groupDigits', () {
    expect(groupDigits(67412, 0), '67,412');
    expect(groupDigits(1234567.891, 2), '1,234,567.89');
    expect(groupDigits(214.9, 2), '214.90');
  });

  test('timeMarks picks clock boundaries far enough apart', () {
    final start = DateTime(2026, 9, 26, 5);
    final times = [
      for (var i = 0; i < 40; i++) start.add(Duration(minutes: 15 * i)),
    ];
    // 8.45pt candles: 1h would be 34pt apart, so labels go every 2h.
    final marks = timeMarks(times, 8.45);
    expect(
      [for (final i in marks) timeLabel(times[i], const Duration(minutes: 15))],
      ['06:00', '08:00', '10:00', '12:00', '14:00'],
    );
  });

  test('sampleCandles is repeatable, ends on the price and is well formed', () {
    List<Candle> make() => sampleCandles(
      key: 'SOL/1h',
      last: 214.9,
      period: const Duration(hours: 1),
      end: DateTime(2026, 9, 26, 14),
    );
    final a = make();
    expect(a.length, 40);
    expect(a.last.close, closeTo(214.9, 1e-9));
    expect(a.last.time, DateTime(2026, 9, 26, 14));
    expect([for (final c in a) c.close], [for (final c in make()) c.close]);
    for (final c in a) {
      expect(c.high, greaterThanOrEqualTo(c.open > c.close ? c.open : c.close));
      expect(c.low, lessThanOrEqualTo(c.open < c.close ? c.open : c.close));
    }
  });

  test('LiveCandles trades into the last candle, then rolls the window', () {
    final t = DateTime(2026, 9, 26, 14);
    final price = ValueNotifier<double>(101);
    final live = LiveCandles(
      seed: [Candle(t, 99, 100, 98, 100), Candle(t, 100, 100, 100, 100)],
      period: const Duration(minutes: 15),
      price: price,
      updatesPerCandle: 2,
    );
    // Anchored to the live price on start.
    expect(live.candles.last.close, 101);
    expect(live.candles.last.high, 101);

    price.value = 97;
    expect(live.candles.last.low, 97);
    expect(live.candles.length, 2);

    price.value = 99;
    expect(live.candles.length, 2, reason: 'window keeps its length');
    expect(live.candles.last.open, 99);
    expect(live.candles.last.time, t.add(const Duration(minutes: 15)));
    expect(live.candles.first.close, 99);
    expect(live.revision, 2);
    live.dispose();
  });
}
