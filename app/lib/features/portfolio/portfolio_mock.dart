import 'package:flutter/painting.dart';

import '../../design_system/design_system.dart';
import '../live/market_prices.dart';

/// One open position. Demo data only; nothing here is a real balance.
class PortfolioPosition {
  const PortfolioPosition({
    required this.id,
    required this.title,
    required this.side,
    required this.leverage,
    required this.sparkAsset,
    required this.pnl,
    required this.pnlPercent,
    required this.detail,
    required this.notionalCents,
    required this.marginCents,
    this.coinAsset,
    this.initial,
    this.clashId,
  });

  /// The order's action id for a fill; a fixed id for a seed position.
  final String id;
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

  /// Size and the margin it holds, in cents, as filled (never recomputed).
  final int notionalCents;
  final int marginCents;

  /// The Arena clash a fill joined, if any (unit 04).
  final String? clashId;

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

  /// The user's cash, the Scenario seed: $12,480 in cents.
  static const cashCents = 1248000;

  /// The demo's second identity (VC-DEM-004): a copier with its own paper
  /// cash and no positions, orders or receipts.
  static const copierHandle = 'sam.sol';
  static const copierCashCents = 100000;
  static const change24h = r'+$91 (0.73%)';

  /// The user's own market (their TPX symbol) and its market cap.
  static const marketSymbol = 'MAYA';
  static const marketCap = r'$44.0M';
  static const spans = ['1h', '4h', '1D', '1W', '1M', 'All'];
  static const defaultSpan = 2; // 1D

  static const positions = [
    PortfolioPosition(
      id: 'p-eth',
      title: 'Ethereum',
      notionalCents: 400000,
      marginCents: 80000,
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
        price: 2968.40,
        entry: 2902.70,
        takeProfit: 2989.50,
        stopLoss: 2844.80,
      ),
    ),
    PortfolioPosition(
      id: 'p-sol',
      title: 'Solana',
      notionalCents: 50000,
      marginCents: 5000,
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
      id: 'p-0xreal',
      title: '0xreal',
      notionalCents: 6750,
      marginCents: 6750,
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

/// A resting limit order (market orders fill at once, so only limits sit
/// open). Fields follow the backend's `Order` (request + status); amounts
/// are shown, never computed into anything financial. Demo data only.
class OpenOrder {
  const OpenOrder({
    required this.id,
    required this.asset,
    required this.symbol,
    required this.coinAsset,
    required this.side,
    required this.leverage,
    required this.limitPrice,
    required this.quantity,
    required this.filled,
    this.decimals = 2,
    this.quantityDecimals = 2,
    this.takeProfit,
    this.stopLoss,
    this.reduceOnly = false,
  });

  final String id;
  final String asset;
  final String symbol;
  final String coinAsset;
  final TradeSide side;
  final int leverage;
  final double limitPrice;

  /// The market's live price, for how far the limit is from filling.
  double get markPrice => MarketPrices.now(symbol);

  /// Order size and how much of it has filled, in asset units.
  final double quantity;
  final double filled;
  final int decimals;
  final int quantityDecimals;
  final double? takeProfit;
  final double? stopLoss;
  final bool reduceOnly;

  String get tag => '${side.label.toUpperCase()} ${leverage}x';
  double get fillShare => quantity == 0 ? 0 : filled / quantity;
  bool get partlyFilled => filled > 0;

  /// Order value at the limit price.
  double get notional => limitPrice * quantity;

  /// How far the mark must move to reach the limit, as a share of the mark.
  double get distance => (limitPrice - markPrice).abs() / markPrice;
  bool get limitBelowMark => limitPrice < markPrice;
}

/// Open orders for the Portfolio "Open orders" tab. Marks match the
/// market prices every other screen shows. Simulated.
abstract final class OpenOrdersMock {
  static const orders = [
    OpenOrder(
      id: 'o-eth-1',
      asset: 'Ethereum',
      symbol: 'ETH',
      coinAsset: VistaAssets.coinEthRow,
      side: TradeSide.long,
      leverage: 5,
      limitPrice: 2850,
      quantity: 0.75,
      filled: 0,
      takeProfit: 3060,
      stopLoss: 2790,
    ),
    OpenOrder(
      id: 'o-sol-1',
      asset: 'Solana',
      symbol: 'SOL',
      coinAsset: VistaAssets.coinSolRow,
      side: TradeSide.short,
      leverage: 10,
      limitPrice: 222.50,
      quantity: 4.5,
      filled: 1.2,
      quantityDecimals: 1,
      takeProfit: 205,
    ),
    // Reduce-only: trims the ETH long above the market, never adds to it.
    OpenOrder(
      id: 'o-eth-2',
      asset: 'Ethereum',
      symbol: 'ETH',
      coinAsset: VistaAssets.coinEthRow,
      side: TradeSide.short,
      leverage: 5,
      limitPrice: 3080,
      quantity: 0.4,
      filled: 0,
      reduceOnly: true,
    ),
  ];
}
