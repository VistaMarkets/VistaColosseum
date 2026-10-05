import 'package:flutter/foundation.dart';

import '../../design_system/design_system.dart';
import '../live/live_feed.dart';
import 'portfolio_mock.dart';

/// The viewer's open positions, shared by the order tickets (a market fill
/// adds one), Portfolio and the position sheet (which lists and closes
/// them) and Arena's position picker. Held in memory; simulated, nothing is
/// sent.
abstract final class PositionsState {
  static final open = ValueNotifier<List<PortfolioPosition>>(
    List.unmodifiable(PortfolioMock.positions),
  );

  /// A new position goes on top.
  static void add(PortfolioPosition p) =>
      open.value = List.unmodifiable([p, ...open.value]);

  /// Closes [p]; returns where it was, for Undo.
  static int remove(PortfolioPosition p) {
    final index = open.value.indexOf(p);
    if (index >= 0) {
      open.value = List.unmodifiable([...open.value]..removeAt(index));
    }
    return index;
  }

  static void insert(int index, PortfolioPosition p) {
    if (open.value.contains(p)) return;
    final items = [...open.value];
    items.insert(index.clamp(0, items.length), p);
    open.value = List.unmodifiable(items);
  }

  static void reset() =>
      open.value = List.unmodifiable(PortfolioMock.positions);

  /// A filled market order as a position: just opened, so no P/L yet.
  /// [name] is the market's name ("Ethereum"), or the trader's handle for
  /// a trader market. Exits default to ±5% when the order had none.
  static PortfolioPosition fromFill({
    required String symbol,
    required String name,
    required bool traderMarket,
    required TradeSide side,
    required int leverage,
    required double entry,
    required double notional,
    double? takeProfit,
    double? stopLoss,
  }) {
    final long = side == TradeSide.long;
    final decimals = entry >= 1000
        ? 0
        : entry >= 1
        ? 2
        : 4;
    return PortfolioPosition(
      title: name,
      side: side,
      leverage: leverage,
      coinAsset: traderMarket ? null : VistaAssets.coinPlaceholder,
      initial: traderMarket ? symbol[0].toUpperCase() : null,
      sparkAsset: long ? VistaAssets.sparkEth : VistaAssets.sparkSol,
      pnl: r'+$0',
      pnlPercent: '+0.0%',
      detail: PositionDetail(
        avatar: switch (symbol) {
          'ETH' => VistaAssets.coinEthSmall,
          'SOL' => VistaAssets.coinSolSmall,
          _ => null,
        },
        opened: 'just now',
        pnl: r'+$0.00',
        size: '${formatUsd(notional)} position',
        symbol: symbol,
        price: entry,
        entry: entry,
        takeProfit: takeProfit ?? entry * (long ? 1.05 : 0.95),
        stopLoss: stopLoss ?? entry * (long ? 0.95 : 1.05),
        decimals: decimals,
      ),
    );
  }
}
