import 'package:flutter/painting.dart';

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

/// A caller's live position in this asset (Callers panel).
class AssetCaller {
  const AssetCaller(this.handle, this.side, this.detail, this.pnl);

  final String handle;
  final TradeSide side;
  final String detail;
  final String pnl;

  bool get inProfit => !pnl.startsWith('−');
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
      price: r'$3,180.00',
      changeUsd: r'−$13',
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
  static const lastPrice = '67,412';

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

  /// Last 9 funding payments: height (of 24) and whether longs paid.
  static const funding = [
    (12.0, true),
    (16.0, true),
    (6.0, false),
    (14.0, true),
    (18.0, true),
    (20.0, true),
    (24.0, true),
    (18.0, true),
    (22.0, true),
  ];
  static const liqLong = r'$65,900';
  static const liqShort = r'$68,900';

  // Book panel: (price, size, depth fraction of the half-row).
  static const spread = 'Spread 0.5';
  static const bids = [
    ('67,412.0', '0.88', 14 / 182),
    ('67,411.5', '2.10', 47 / 182),
    ('67,410.0', '0.53', 55 / 182),
    ('67,408.5', '3.40', 109 / 182),
    ('67,406.0', '1.27', 129 / 182),
    ('67,405.0', '0.74', 140 / 182),
    ('67,403.5', '2.66', 182 / 182),
  ];
  static const asks = [
    ('67,412.5', '1.12', 18 / 182),
    ('67,413.0', '0.41', 24 / 182),
    ('67,414.5', '2.95', 70 / 182),
    ('67,416.0', '0.62', 80 / 182),
    ('67,418.5', '1.84', 109 / 182),
    ('67,419.0', '0.95', 124 / 182),
    ('67,421.5', '1.60', 149 / 182),
  ];
  static const bidTotal = '11.58';
  static const askTotal = '9.49';
  static const slippageLabel = r'Market buy $10,000';
  static const slippage = '≈ 0.002% slippage';

  // Callers panel.
  static const callersLong = 8;
  static const callersShort = 4;
  static const callers = [
    AssetCaller('maya.eth', TradeSide.long, r'5x · from $66,900', '+3.8%'),
    AssetCaller('0xreal', TradeSide.short, r'3x · from $67,950', '+2.4%'),
    AssetCaller('lunaq', TradeSide.long, r'10x · from $67,300', '+1.7%'),
    AssetCaller('deltaone', TradeSide.short, r'2x · from $66,800', '−1.8%'),
  ];
}
