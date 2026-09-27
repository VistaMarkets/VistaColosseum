import 'package:flutter/painting.dart';

import '../../design_system/design_system.dart';

/// One open position. Demo data only; nothing here is a real balance.
class PortfolioPosition {
  const PortfolioPosition({
    required this.title,
    required this.side,
    required this.leverage,
    required this.sparkAsset,
    required this.pnl,
    required this.pnlPercent,
    this.coinAsset,
    this.initial,
  });

  final String title;
  final TradeSide side;
  final int leverage;
  final String sparkAsset;
  final String pnl;
  final String pnlPercent;

  /// Asset positions show a coin; trader (TPX) positions show an initial.
  final String? coinAsset;
  final String? initial;

  bool get inProfit => !pnl.startsWith('−');
  Color get pnlColor => inProfit ? VistaColors.long : VistaColors.short;
  String get tag => '${side.label.toUpperCase()} ${leverage}x';
}

/// Mock content from the Figma frame (174:110). Simulated.
abstract final class PortfolioMock {
  static const handle = 'maya.eth';
  static const balance = r'$12,480';
  static const change24h = r'+$91 (0.73%)';
  static const fees = r'$42.80';

  /// The user's own market (their TPX symbol) and its market cap.
  static const marketSymbol = 'MAYA';
  static const marketCap = r'$44.0M';
  static const marketCapChange24h = r'+$1.8M (4.27%)';
  static const spans = ['1h', '4h', '1D', '1W', '1M', 'All'];
  static const defaultSpan = 2; // 1D

  static const positions = [
    PortfolioPosition(
      title: 'Ethereum',
      side: TradeSide.long,
      leverage: 5,
      coinAsset: VistaAssets.coinPlaceholder,
      sparkAsset: VistaAssets.sparkEth,
      pnl: r'+$90',
      pnlPercent: '+11.3%',
    ),
    PortfolioPosition(
      title: 'Solana',
      side: TradeSide.short,
      leverage: 10,
      coinAsset: VistaAssets.coinPlaceholder,
      sparkAsset: VistaAssets.sparkSol,
      pnl: r'−$30',
      pnlPercent: '−6.0%',
    ),
    PortfolioPosition(
      title: '0xreal',
      side: TradeSide.long,
      leverage: 1,
      initial: '0',
      sparkAsset: VistaAssets.spark0xreal,
      pnl: r'+$2.16',
      pnlPercent: '+3.2%',
    ),
  ];
}
