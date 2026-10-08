import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../design_system/design_system.dart';
import '../live/market_prices.dart';
import 'portfolio_mock.dart';

/// A position you've closed: what it was, where it opened and closed, and
/// the P/L it realised. Simulated.
class ClosedTrade {
  const ClosedTrade({
    required this.title,
    required this.symbol,
    required this.side,
    required this.leverage,
    required this.entry,
    required this.exit,
    required this.pnl,
    required this.pnlPercent,
    required this.closed,
    this.coinAsset,
    this.initial,
  });

  /// From an open position, closed now at the live price.
  factory ClosedTrade.from(PortfolioPosition p) => ClosedTrade(
    title: p.title,
    symbol: p.detail.symbol,
    side: p.side,
    leverage: p.leverage,
    entry: p.detail.entry,
    exit: MarketPrices.of(p.detail.symbol).value,
    pnl: p.pnl,
    pnlPercent: p.pnlPercent,
    closed: 'now',
    coinAsset: p.coinAsset,
    initial: p.initial,
  );

  final String title;
  final String symbol;
  final TradeSide side;
  final int leverage;
  final double entry;
  final double exit;

  /// Realised, e.g. "+$90" / "−$30".
  final String pnl;
  final String pnlPercent;

  /// When it closed: "now", "2d".
  final String closed;
  final String? coinAsset;
  final String? initial;

  bool get inProfit => !pnl.startsWith('−');
  Color get pnlColor => inProfit ? VistaColors.long : VistaColors.short;
  String get tag => '${side.label.toUpperCase()} ${leverage}x';
}

/// Your closed trades, newest first. Closing a position adds one; its
/// Undo takes it back. Held in memory; seeded with a few past trades.
abstract final class TradeHistory {
  static final closed = ValueNotifier<List<ClosedTrade>>(_seed);

  static void add(ClosedTrade t) =>
      closed.value = List.unmodifiable([t, ...closed.value]);

  static void remove(ClosedTrade t) =>
      closed.value = List.unmodifiable([...closed.value]..remove(t));

  static void reset() => closed.value = _seed;

  static final _seed = List<ClosedTrade>.unmodifiable(const [
    ClosedTrade(
      title: 'Bitcoin',
      symbol: 'BTC',
      side: TradeSide.long,
      leverage: 3,
      entry: 64920,
      exit: 66340,
      pnl: r'+$131',
      pnlPercent: '+6.6%',
      closed: '2d',
      coinAsset: VistaAssets.coinBtcRow,
    ),
    ClosedTrade(
      title: 'Solana',
      symbol: 'SOL',
      side: TradeSide.short,
      leverage: 5,
      entry: 201.30,
      exit: 196.80,
      pnl: r'+$56',
      pnlPercent: '+11.2%',
      closed: '5d',
      coinAsset: VistaAssets.coinSolRow,
    ),
    ClosedTrade(
      title: 'Arbitrum',
      symbol: 'ARB',
      side: TradeSide.long,
      leverage: 10,
      entry: 1.14,
      exit: 1.09,
      pnl: r'−$44',
      pnlPercent: '−43.9%',
      closed: '1w',
      coinAsset: VistaAssets.coinArbRow,
    ),
  ]);
}
