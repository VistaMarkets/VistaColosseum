import 'package:flutter/foundation.dart';

import '../design_system/design_system.dart';
import '../features/live/live_feed.dart';
import '../features/live/market_prices.dart';
import '../features/markets/markets_mock.dart';
import '../features/people/follow_mock.dart';
import '../features/portfolio/portfolio_mock.dart';
import '../features/trade/trade_mock.dart';

/// All mutable demo state, in one place. Seeded from the mocks, which are
/// the fixture and never live state; [reset] puts every value back to that
/// seed. Identities, prices and calls stay const fixtures and are not here.
///
/// Simulated: nothing is sent, and nothing survives a restart. Money is
/// `int` cents.
abstract final class Scenario {
  /// Which fixture the demo runs on; shown when the demo is reset.
  static const fixtureVersion = 'fixture-v1';

  /// `--dart-define=HAS_MARKET=true` starts with the user's market listed.
  static const _startWithMarket = bool.fromEnvironment('HAS_MARKET');

  static final cashCents = ValueNotifier<int>(PortfolioMock.cashCents);
  static final positions = ValueNotifier<List<PortfolioPosition>>(
    PortfolioMock.positions,
  );
  static final openOrders = ValueNotifier<List<OpenOrder>>(
    OpenOrdersMock.orders,
  );

  /// The user's own market: whether it is listed, its ticker (suggested
  /// before listing), and its id once listed (the symbol, as markets use).
  static final hasMarket = ValueNotifier<bool>(_startWithMarket);
  static final ticker = ValueNotifier<String>(PortfolioMock.marketSymbol);
  static final marketId = ValueNotifier<String?>(_seedMarketId);

  /// Liked calls, keyed `callerHandle/ticker`.
  static final liked = ValueNotifier<Set<String>>(const {});

  /// Starred assets and trader markets, in the order starred.
  static final favoriteAssets = ValueNotifier<List<String>>(
    MarketsMock.assetFavorites,
  );
  static final favoriteTraders = ValueNotifier<List<String>>(
    MarketsMock.traderFavorites,
  );

  /// The user's Followers and Following lists, and the handles the user
  /// follows (every Follow button reads this).
  static final followers = ValueNotifier<List<FollowPerson>>(
    FollowMock.followers,
  );
  static final following = ValueNotifier<List<FollowPerson>>(
    FollowMock.following,
  );
  static final followed = ValueNotifier<Set<String>>(_seedFollowed);

  /// The demo's "now", fixed at the fixture's start (where charts end).
  static final clock = ValueNotifier<DateTime>(TradeMock.chartEnd);

  /// Filled paper orders, newest first.
  static final receipts = ValueNotifier<List<OrderReceipt>>(const []);

  /// Markets whose price context has expired: a market order on one fails
  /// until [refreshPrice] (the ticket's Retry).
  static final stalePrices = ValueNotifier<Set<String>>(TradeMock.stalePrices);

  static String? get _seedMarketId =>
      _startWithMarket ? PortfolioMock.marketSymbol : null;

  /// A handle's last entry wins, as the follow lists showed it.
  static Set<String> get _seedFollowed => Set.unmodifiable({
    for (final MapEntry(:key, :value) in {
      for (final p in [...FollowMock.followers, ...FollowMock.following])
        p.handle: p.following,
    }.entries)
      if (value) key,
  });

  /// Follows or unfollows [handle]. Local only: nothing is sent anywhere.
  static void toggleFollow(String handle) {
    final f = followed.value;
    followed.value = Set.unmodifiable(
      f.contains(handle) ? f.where((h) => h != handle) : {...f, handle},
    );
  }

  /// Retry's refresh: [symbol]'s price context is current again.
  static void refreshPrice(String symbol) => stalePrices.value =
      Set.unmodifiable(stalePrices.value.where((s) => s != symbol));

  /// Whether [symbol] is an asset with a quote. A trader market's handle
  /// is not: trader-index tickets are not built (VC-MKT-005).
  static bool tradable(String symbol) => TradeMock.quotes.containsKey(symbol);

  /// Why [intent] can't be placed, or null. Tickets show it on their
  /// button; [placeOrder] refuses with it, so no caller places a trader
  /// index, a non-finite or sub-cent size, or a leverage under 1x.
  static String? problem(OrderIntent intent) {
    if (!tradable(intent.symbol)) return traderIndexNotBuilt;
    if (intent.leverage < 1) return 'Choose a leverage';
    if (!(intent.units > 0) || !intent.units.isFinite) return 'Enter a size';
    if (!(intent.price > 0) || !intent.price.isFinite) return 'Enter a price';
    if (intent.marginCents <= 0) return 'Enter a size';
    if (intent.totalCents > cashCents.value) return notEnoughFunds;
    return null;
  }

  /// The most margin cash covers at [leverage], leaving room for the fee.
  static int maxMarginCents(int leverage, int feeBps) =>
      cashCents.value * 10000 ~/ (10000 + leverage * feeBps);

  /// The one write path for orders. A market order debits margin + fee,
  /// adds one position and one receipt; a limit or stop rests in Open
  /// orders. A repeat of an action that changed state returns what it did
  /// and changes nothing more; a failure changed nothing, so the same
  /// action may be retried.
  static OrderResult placeOrder(OrderIntent intent) {
    final id = intent.actionId;
    for (final r in receipts.value) {
      if (r.id == id) return OrderFilled(r);
    }
    for (final o in openOrders.value) {
      if (o.id == id) return OrderResting(o);
    }
    final problem = Scenario.problem(intent);
    if (problem != null) return OrderFailed(problem);
    final price = intent.price;
    final decimals = MarketPrices.decimalsFor(price, compact: true);
    if (intent.kind != OrderKind.market) {
      final order = OpenOrder(
        id: id,
        asset: intent.name,
        symbol: intent.symbol,
        coinAsset: intent.icon,
        side: intent.side,
        leverage: intent.leverage,
        limitPrice: price,
        quantity: intent.units,
        filled: 0,
        decimals: decimals,
        quantityDecimals: intent.unitDecimals,
        takeProfit: intent.takeProfit,
        stopLoss: intent.stopLoss,
        reduceOnly: intent.reduceOnly,
      );
      openOrders.value = List.unmodifiable([order, ...openOrders.value]);
      return OrderResting(order);
    }
    if (stalePrices.value.contains(intent.symbol)) {
      return const OrderFailed('Price expired');
    }
    final long = intent.side == TradeSide.long;
    final receipt = OrderReceipt(
      id: id,
      symbol: intent.symbol,
      name: intent.name,
      side: intent.side,
      leverage: intent.leverage,
      units: intent.units,
      price: price,
      notionalCents: intent.notionalCents,
      marginCents: intent.marginCents,
      feeCents: intent.feeCents,
      at: clock.value,
      clashId: intent.clashId,
    );
    final position = PortfolioPosition(
      id: id,
      title: intent.name,
      side: intent.side,
      leverage: intent.leverage,
      coinAsset: intent.icon,
      sparkAsset: VistaAssets.spark24UpA,
      pnl: r'+$0.00',
      pnlPercent: '+0.0%',
      notionalCents: receipt.notionalCents,
      marginCents: receipt.marginCents,
      clashId: intent.clashId,
      detail: PositionDetail(
        avatar: intent.icon,
        opened: 'just now',
        pnl: r'+$0.00',
        size: '${formatCents(receipt.notionalCents)} position',
        symbol: intent.symbol,
        price: price,
        entry: price,
        // Unset exits show the tickets' defaults: +7% / −2.1%.
        takeProfit: intent.takeProfit ?? price * (long ? 1.07 : 0.93),
        stopLoss: intent.stopLoss ?? price * (long ? 0.979 : 1.021),
        decimals: decimals,
      ),
    );
    cashCents.value -= receipt.totalCents;
    positions.value = List.unmodifiable([position, ...positions.value]);
    receipts.value = List.unmodifiable([receipt, ...receipts.value]);
    return OrderFilled(receipt);
  }

  /// Puts every value back to the fixture seed. [withMarket] overrides the
  /// `HAS_MARKET` start, for tests that need one or the other.
  static void reset({bool withMarket = _startWithMarket}) {
    cashCents.value = PortfolioMock.cashCents;
    positions.value = PortfolioMock.positions;
    openOrders.value = OpenOrdersMock.orders;
    hasMarket.value = withMarket;
    ticker.value = PortfolioMock.marketSymbol;
    marketId.value = withMarket ? PortfolioMock.marketSymbol : null;
    liked.value = const {};
    favoriteAssets.value = MarketsMock.assetFavorites;
    favoriteTraders.value = MarketsMock.traderFavorites;
    followers.value = FollowMock.followers;
    following.value = FollowMock.following;
    followed.value = _seedFollowed;
    clock.value = TradeMock.chartEnd;
    receipts.value = const [];
    stalePrices.value = TradeMock.stalePrices;
  }
}

/// What a ticket can place: market fills at once, limit and stop rest.
enum OrderKind { market, limit, stop }

/// The funds failure, worded the same on both tickets and in the store.
const notEnoughFunds = 'Not enough funds';

/// What a trader-index ticket says instead of placing (VC-MKT-005).
const traderIndexNotBuilt = 'Trader-index ticket — not in the demo yet';

/// One order as a ticket asks for it. [actionId] is minted once when the
/// ticket opens and reused on every confirm of it. Costs are rounded once
/// here, in int cents (VC-ORD-003), the only conversion from `double`: the
/// review shows them and [Scenario.placeOrder] stores them in the receipt
/// and the position; nothing recomputes them.
class OrderIntent {
  OrderIntent({
    required this.actionId,
    required this.symbol,
    required this.name,
    required this.side,
    required this.units,
    required this.price,
    required this.leverage,
    this.kind = OrderKind.market,
    this.icon = VistaAssets.coinPlaceholder,
    this.takeProfit,
    this.stopLoss,
    this.reduceOnly = false,
    this.clashId,
  });

  final String actionId;
  final String symbol;
  final String name;
  final TradeSide side;

  /// Size in the market's units, and the reference price (the live price
  /// for a market order, the limit or trigger otherwise).
  final double units;
  final double price;
  final int leverage;
  final OrderKind kind;
  final String icon;
  final double? takeProfit;
  final double? stopLoss;
  final bool reduceOnly;

  /// The Arena clash this order joins, if any (unit 04 adds behavior).
  final String? clashId;

  /// Places a size is shown to: finer for dearer markets.
  int get unitDecimals => price >= 1000
      ? 4
      : price >= 10
      ? 2
      : price >= 1
      ? 1
      : 0;

  int get feeBps =>
      kind == OrderKind.limit ? TradeMock.makerFeeBps : TradeMock.takerFeeBps;
  late final int notionalCents = _cents(units * price);
  late final int marginCents = (notionalCents / leverage).round();
  late final int feeCents = notionalCents * feeBps ~/ 10000;

  /// A non-finite size or price costs nothing here, so a ticket still
  /// renders; [Scenario.problem] refuses it.
  static int _cents(double usd) => usd.isFinite ? (usd * 100).round() : 0;

  /// Paper funds required: what a fill takes from cash.
  int get totalCents => marginCents + feeCents;
}

/// A filled paper order (unit 06 lists these apart from call receipts).
/// Simulated — no real order.
class OrderReceipt {
  const OrderReceipt({
    required this.id,
    required this.symbol,
    required this.name,
    required this.side,
    required this.leverage,
    required this.units,
    required this.price,
    required this.notionalCents,
    required this.marginCents,
    required this.feeCents,
    required this.at,
    this.clashId,
  });

  /// The order's action id.
  final String id;
  final String symbol;
  final String name;
  final TradeSide side;
  final int leverage;
  final double units;
  final double price;
  final int notionalCents;
  final int marginCents;
  final int feeCents;
  final DateTime at;
  final String? clashId;

  int get totalCents => marginCents + feeCents;
}

/// What [Scenario.placeOrder] did.
sealed class OrderResult {
  const OrderResult();
}

final class OrderFilled extends OrderResult {
  const OrderFilled(this.receipt);
  final OrderReceipt receipt;
}

final class OrderResting extends OrderResult {
  const OrderResting(this.order);
  final OpenOrder order;
}

final class OrderFailed extends OrderResult {
  const OrderFailed(this.reason);
  final String reason;
}
