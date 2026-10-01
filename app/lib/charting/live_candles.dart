import 'package:flutter/foundation.dart';

import 'candle.dart';

/// A candle series that follows a live price.
///
/// Every price update trades into the newest candle, so the figure printed
/// above a chart and the chart's last candle are the same number. After
/// [updatesPerCandle] updates the candle closes and a new one opens at that
/// price, one [period] later; the oldest drops off so the window keeps its
/// length. Time is compressed (a 15m candle closes after a few updates) so
/// the demo visibly moves.
class LiveCandles extends ChangeNotifier {
  LiveCandles({
    required List<Candle> seed,
    required this.period,
    required ValueListenable<double> price,
    this.updatesPerCandle = 5,
  }) : assert(seed.isNotEmpty),
       _price = price,
       _window = seed.length,
       _candles = [...seed] {
    // Start the forming candle at the live price, not the seed's close.
    _candles.last = _candles.last.trade(price.value);
    _price.addListener(_onPrice);
  }

  final Duration period;
  final int updatesPerCandle;
  final ValueListenable<double> _price;
  final int _window;
  final List<Candle> _candles;
  int _updates = 0;

  /// Bumped on every change, for painters to compare against.
  int revision = 0;

  List<Candle> get candles => List.unmodifiable(_candles);

  void _onPrice() {
    final p = _price.value;
    _candles.last = _candles.last.trade(p);
    if (++_updates >= updatesPerCandle) {
      _updates = 0;
      _candles.add(Candle(_candles.last.time.add(period), p, p, p, p));
      if (_candles.length > _window) _candles.removeAt(0);
    }
    revision++;
    notifyListeners();
  }

  @override
  void dispose() {
    _price.removeListener(_onPrice);
    super.dispose();
  }
}
