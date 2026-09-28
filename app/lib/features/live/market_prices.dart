import 'package:flutter/foundation.dart';

import 'live_feed.dart';

/// One price per market, shared by every screen that shows it: Home cards,
/// trade pages, Explore rows and rail, positions, open orders and profile
/// holdings. Each market has a single simulated live feed, so any two
/// screens always agree. Assets are keyed by ticker, trader markets by
/// handle. Simulated; not market data.
abstract final class MarketPrices {
  static const Map<String, double> _base = {
    'BTC': 67412,
    'ETH': 2968.40,
    'SOL': 214.90,
    'ARB': 1.04,
    'AVAX': 38.20,
    'maya.eth': 0.4400,
    '0xreal': 0.3820,
    'lunaq': 0.3145,
    'deltaone': 0.2610,
    'kestrel': 0.1980,
    'kilo.sol': 0.1720,
    'nara': 0.1410,
  };

  /// The price each market opens the session at.
  static double base(String symbol) => _base[symbol] ?? 0;

  /// The feed key and tick size behind [of], for widgets that take a key
  /// (such as `LiveUsd`) so they read the same feed.
  static String feedKey(String symbol) => 'price:$symbol';
  static double step(String symbol) => base(symbol) * 0.0004;

  /// The market's live price.
  static ValueListenable<double> of(String symbol) =>
      LiveFeed.watch(feedKey(symbol), base(symbol), step(symbol));

  /// The live price right now.
  static double now(String symbol) => of(symbol).value;

  /// Decimal places for a price: cents, or four places under a dollar.
  /// [compact] drops the cents on four-figure prices, as lists show them.
  static int decimalsFor(double price, {bool compact = false}) {
    if (price < 1) return 4;
    if (compact && price >= 1000) return 0;
    return 2;
  }

  /// "$67,412", "$214.90" or "$0.4400" (compact), for lists and tags.
  static String format(double price, {bool compact = false}) =>
      formatUsd(price, decimals: decimalsFor(price, compact: compact));
}
