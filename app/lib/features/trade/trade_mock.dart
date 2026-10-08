import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../charting/charting.dart';

import '../../design_system/design_system.dart';

/// Header quote for an asset's trade page.
class AssetQuote {
  const AssetQuote({
    required this.ticker,
    required this.name,
    required this.leverage,
    required this.price,
    required this.changeUsd,
    required this.changePct,
  });

  final String ticker;
  final String name;
  final String leverage;
  final String price;
  final String changeUsd;
  final double changePct;

  bool get up => changePct >= 0;
  Color get color => up ? VistaColors.long : VistaColors.short;
  String get pctLabel =>
      '${up ? '+' : '−'}${changePct.abs().toStringAsFixed(2)}%';
}

/// A caller's post on an asset (Callers panel): why they traded, and their
/// order. Levels are ratios of the market's price, so every asset's page
/// shows levels in its own prices.
class CallerPost {
  const CallerPost({
    required this.handle,
    required this.age,
    required this.side,
    required this.leverage,
    required this.entryRatio,
    required this.size,
    required this.takeProfit,
    required this.stopLoss,
    required this.message,
    this.following = true,
    this.exitRatio,
  });

  final String handle;

  /// Whether the user follows this caller (the "Following" filter).
  final bool following;
  final String age;
  final TradeSide side;
  final int leverage;

  /// Entry as a share of the market's session price.
  final double entryRatio;

  /// Position size in dollars.
  final double size;

  /// Exits as shares of the entry.
  final double takeProfit;
  final double stopLoss;
  final String message;

  /// Where they closed, as a share of the entry; null while still open.
  /// Call cards show the exit and its P/L only once there is one.
  final double? exitRatio;
  bool get exited => exitRatio != null;

  /// P/L in % at [price] (live), or at the exit once closed.
  double pnlPct(double entry, double price) {
    final at = exitRatio == null ? price : entry * exitRatio!;
    return (at - entry) /
        entry *
        leverage *
        (side == TradeSide.long ? 1 : -1) *
        100;
  }
}

/// Mock content from Figma 206:110 and 214:110 / 214:428 / 214:746
/// ("Trade — BTC"). The chart and panels are the BTC sample for every
/// asset; the header uses each asset's own quote. Simulated.
abstract final class TradeMock {
  static const quotes = {
    'BTC': AssetQuote(
      ticker: 'BTC',
      name: 'Bitcoin',
      leverage: '20x',
      price: r'$67,412.00',
      changeUsd: r'+$798',
      changePct: 1.2,
    ),
    'ETH': AssetQuote(
      ticker: 'ETH',
      name: 'Ethereum',
      leverage: '50x',
      price: r'$2,968.40',
      changeUsd: r'−$12',
      changePct: -0.4,
    ),
    'SOL': AssetQuote(
      ticker: 'SOL',
      name: 'Solana',
      leverage: '20x',
      price: r'$214.90',
      changeUsd: r'+$7.87',
      changePct: 3.8,
    ),
    'ARB': AssetQuote(
      ticker: 'ARB',
      name: 'Arbitrum',
      leverage: '10x',
      price: r'$1.04',
      changeUsd: r'+$0.01',
      changePct: 0.9,
    ),
    'AVAX': AssetQuote(
      ticker: 'AVAX',
      name: 'Avalanche',
      leverage: '10x',
      price: r'$38.20',
      changeUsd: r'−$0.42',
      changePct: -1.1,
    ),
  };

  static const intervals = ['1m', '5m', '15m', '1h', '4h', '1D'];
  static const defaultInterval = 2; // 15m

  /// Candle length for each entry in [intervals].
  static const periods = [
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(hours: 1),
    Duration(hours: 4),
    Duration(days: 1),
  ];

  /// Open time of the newest sample candle.
  static final chartEnd = DateTime(2026, 9, 26, 14, 45);

  /// BTC 15m as drawn in Figma 206:110, read off the design as prices
  /// (open, high, low, close), oldest first. Other assets and intervals
  /// use generated history.
  static const btc15m = [
    (67171.77, 67236.03, 67070.83, 67091.02),
    (67091.01, 67141.92, 67004.56, 67041.74),
    (67041.74, 67094.23, 66957.54, 67010.23),
    (67008.60, 67058.44, 66965.86, 67010.66),
    (67010.66, 67068.95, 66984.55, 67052.05),
    (67052.05, 67125.88, 67048.29, 67077.16),
    (67077.16, 67131.34, 67012.79, 67098.68),
    (67098.68, 67147.25, 67062.87, 67138.67),
    (67138.67, 67244.03, 67093.74, 67195.97),
    (67195.98, 67265.23, 67132.59, 67201.58),
    (67201.58, 67224.99, 67118.06, 67176.49),
    (67176.49, 67187.14, 67124.65, 67145.42),
    (67145.42, 67166.00, 67063.33, 67128.75),
    (67128.75, 67182.23, 67067.47, 67131.34),
    (67131.34, 67150.42, 67048.13, 67087.27),
    (67087.26, 67139.93, 67073.80, 67110.51),
    (67110.52, 67197.44, 67085.00, 67193.62),
    (67193.62, 67239.99, 67127.72, 67191.56),
    (67192.23, 67227.95, 67163.93, 67216.38),
    (67216.38, 67241.82, 67176.37, 67205.95),
    (67205.96, 67243.07, 67160.00, 67202.85),
    (67202.85, 67266.12, 67152.94, 67184.89),
    (67184.90, 67305.44, 67140.61, 67261.12),
    (67261.12, 67320.73, 67213.03, 67285.48),
    (67285.48, 67400.85, 67236.06, 67373.15),
    (67373.15, 67414.11, 67333.40, 67357.86),
    (67357.86, 67385.19, 67299.01, 67354.46),
    (67354.48, 67440.62, 67297.29, 67432.88),
    (67432.88, 67461.26, 67380.93, 67391.66),
    (67391.66, 67461.18, 67335.10, 67350.46),
    (67350.46, 67388.30, 67318.56, 67378.23),
    (67378.22, 67409.71, 67313.88, 67400.10),
    (67400.10, 67527.75, 67338.33, 67465.59),
    (67465.59, 67587.67, 67446.37, 67534.55),
    (67534.55, 67551.88, 67464.01, 67469.32),
    (67469.32, 67512.37, 67386.61, 67402.75),
    (67402.75, 67480.95, 67354.77, 67446.79),
    (67446.79, 67508.36, 67399.18, 67415.59),
    (67415.59, 67478.01, 67396.46, 67404.71),
    (67404.73, 67411.30, 67341.00, 67411.10),
  ];

  // Market panel.
  static const openInterest = r'OI $412M';
  static const longShare = 0.58;
  static const longOi = r'$239M';
  static const shortOi = r'$173M';
  static const fundingRate = '0.011% / 8h';
  static const fundingNext = 'Next in 3h 12m';
  static const volume = r'Vol $1.2B';
  static const rangeLow = r'$64,850';
  static const rangeHigh = r'$69,300';

  /// Where the price sits in the 24h range (Figma dot at 212 of 370).
  static const rangePosition = 212 / 370;
  static const fundingSummary = 'Longs paid 8 of 9';

  // Book panel. The design's BTC book (at $67,412, ticks of 0.5) as a
  // template: each level's distance from the best bid in ticks, its size in
  // BTC, and its depth bar (cumulative size as a share of the deepest row).
  static const _bidTicks = [0, -1, -4, -7, -12, -14, -17, -20, -23, -26];
  static const _askTicks = [1, 2, 5, 8, 13, 14, 19, 22, 25, 28];
  static const _bidSizes = [
    0.88,
    2.10,
    0.53,
    3.40,
    1.27,
    0.74,
    2.66,
    1.05,
    3.12,
    0.90,
  ];
  static const _askSizes = [
    1.12,
    0.41,
    2.95,
    0.62,
    1.84,
    0.95,
    1.60,
    2.04,
    0.77,
    3.25,
  ];
  static const _bidDepth = [14, 47, 55, 109, 129, 140, 182, 196, 214, 230];
  static const _askDepth = [18, 24, 70, 80, 109, 124, 149, 170, 185, 205];
  static const _designPrice = 67412.0;

  /// The book around [price]: the template's shape with a tick that suits
  /// the price (0.5 at BTC's, 0.02 at ETH's; at least a cent above $10 and a
  /// hundredth of a cent below) and sizes holding the same dollar depth.
  /// Rows are (price, size, depth fraction). Mock.
  static ({
    List<(String, String, double)> bids,
    List<(String, String, double)> asks,
    String spread,
  })
  book(double price) {
    final raw = price * 0.5 / _designPrice;
    final unit = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    var tick = [
      1,
      2,
      5,
      10,
    ].map((m) => m * unit).firstWhere((t) => t >= raw * 0.7);
    tick = math.max(tick, price >= 10 ? 0.01 : 0.0001);
    // Decimals the tick needs (0.5 → 1, 0.02 → 2), guarded against float
    // error in the log.
    final decimals = math.max(0, (-(math.log(tick) / math.ln10) - 1e-6).ceil());
    final shown = math.max(decimals, price >= 1000 ? 1 : 2);
    final bestBid = (price / tick + 1e-9).floor() * tick;
    final scale = _designPrice / price;
    String size(double btc) {
      final v = btc * scale;
      return groupDigits(
        v,
        v >= 100
            ? 0
            : v >= 10
            ? 1
            : 2,
      );
    }

    List<(String, String, double)> side(
      List<int> ticks,
      List<double> sizes,
      List<int> depth,
    ) => [
      for (var k = 0; k < ticks.length; k++)
        (
          groupDigits(bestBid + ticks[k] * tick, shown),
          size(sizes[k]),
          depth[k] / 230,
        ),
    ];
    return (
      bids: side(_bidTicks, _bidSizes, _bidDepth),
      asks: side(_askTicks, _askSizes, _askDepth),
      spread: 'Spread ${groupDigits(tick, decimals)}',
    );
  }
}
