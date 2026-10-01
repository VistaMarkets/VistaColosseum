import 'package:flutter/material.dart';

import '../../charting/charting.dart';
import '../live/market_prices.dart';
import 'trade_mock.dart';

/// An asset's live price chart (Figma "TradeChart"). BTC on 15m starts from
/// the design's candles; other assets and intervals start from generated
/// history ending at the quoted price. Either way the newest candle follows
/// the same simulated feed as the price in the header.
class CandleChart extends StatefulWidget {
  const CandleChart({
    super.key,
    required this.ticker,
    required this.price,
    required this.interval,
    this.mode = PlotMode.candles,
  });

  final String ticker;

  /// Quoted price, the base for the live feed.
  final double price;

  /// Index into [TradeMock.intervals].
  final int interval;
  final PlotMode mode;

  @override
  State<CandleChart> createState() => _CandleChartState();
}

class _CandleChartState extends State<CandleChart> {
  late LiveCandles _live = _build();

  LiveCandles _build() {
    final period = TradeMock.periods[widget.interval];
    final end = TradeMock.chartEnd;
    final seed =
        widget.ticker == 'BTC' && widget.interval == TradeMock.defaultInterval
        ? [
            for (var i = 0; i < TradeMock.btc15m.length; i++)
              Candle(
                end.subtract(period * (TradeMock.btc15m.length - 1 - i)),
                TradeMock.btc15m[i].$1,
                TradeMock.btc15m[i].$2,
                TradeMock.btc15m[i].$3,
                TradeMock.btc15m[i].$4,
              ),
          ]
        : sampleCandles(
            key: '${widget.ticker}/${TradeMock.intervals[widget.interval]}',
            last: widget.price,
            period: period,
            // Align the newest candle to the interval, e.g. midnight for 1D.
            end: alignToPeriod(end, period),
          );
    return LiveCandles(
      seed: seed,
      period: period,
      // The market's one live price, shared with every other screen.
      price: MarketPrices.of(widget.ticker),
    );
  }

  @override
  void didUpdateWidget(CandleChart old) {
    super.didUpdateWidget(old);
    if (old.ticker != widget.ticker || old.interval != widget.interval) {
      _live.dispose();
      _live = _build();
    }
  }

  @override
  void dispose() {
    _live.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _live,
      builder: (context, _) => PriceChart(
        candles: _live.candles,
        revision: _live.revision,
        period: _live.period,
        mode: widget.mode,
      ),
    );
  }
}
