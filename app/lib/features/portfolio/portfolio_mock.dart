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
    required this.detail,
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

  /// Sheet content. Only Ethereum's is designed (Figma 104:110); Solana's
  /// and 0xreal's are placeholders consistent with their rows.
  final PositionDetail detail;

  bool get inProfit => !pnl.startsWith('−');
  Color get pnlColor => inProfit ? VistaColors.long : VistaColors.short;
  String get tag => '${side.label.toUpperCase()} ${leverage}x';
}

/// What the position sheet shows for a position (Figma 104:110). Prices are
/// numbers so the take-profit / stop-loss steppers can move them.
class PositionDetail {
  const PositionDetail({
    required this.avatar,
    required this.opened,
    required this.pnl,
    required this.size,
    required this.symbol,
    required this.price,
    required this.entry,
    required this.takeProfit,
    required this.stopLoss,
    this.decimals = 0,
  });

  /// Leading mark: an asset icon, or null for a trader initial.
  final String? avatar;
  final String opened;
  final String pnl;
  final String size;
  final String symbol;
  final double price;
  final double entry;
  final double takeProfit;
  final double stopLoss;
  final int decimals;
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
      detail: PositionDetail(
        avatar: VistaAssets.positionAvatarEth,
        opened: '20h ago',
        pnl: r'+$90.00',
        size: r'$4,000 position',
        symbol: 'ETH',
        price: 3489.20,
        entry: 3412,
        takeProfit: 3514,
        stopLoss: 3344,
      ),
    ),
    PortfolioPosition(
      title: 'Solana',
      side: TradeSide.short,
      leverage: 10,
      coinAsset: VistaAssets.coinPlaceholder,
      sparkAsset: VistaAssets.sparkSol,
      pnl: r'−$30',
      pnlPercent: '−6.0%',
      detail: PositionDetail(
        avatar: VistaAssets.coinSolSmall,
        opened: '2d ago',
        pnl: r'−$30.00',
        size: r'$500 position',
        symbol: 'SOL',
        price: 214.90,
        entry: 213.62,
        takeProfit: 210.77,
        stopLoss: 217.90,
        decimals: 2,
      ),
    ),
    PortfolioPosition(
      title: '0xreal',
      side: TradeSide.long,
      leverage: 1,
      initial: '0',
      sparkAsset: VistaAssets.spark0xreal,
      pnl: r'+$2.16',
      pnlPercent: '+3.2%',
      detail: PositionDetail(
        avatar: null,
        opened: '5d ago',
        pnl: r'+$2.16',
        size: r'$67.50 position',
        symbol: '0xreal',
        price: 0.3820,
        entry: 0.3702,
        takeProfit: 0.4000,
        stopLoss: 0.3500,
        decimals: 4,
      ),
    ),
  ];
}
