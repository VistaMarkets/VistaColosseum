import 'package:flutter/foundation.dart';

import '../charting/time_marks.dart';
import '../design_system/design_system.dart';
import '../features/arena/arena_mock.dart';
import '../features/live/live_feed.dart';
import '../features/live/market_prices.dart';
import '../features/market/market_mock.dart';
import '../features/markets/markets_mock.dart';
import '../features/people/follow_mock.dart';
import '../features/portfolio/portfolio_mock.dart';
import '../features/trade/trade_mock.dart';

/// A trader's record (VC-MKT-002), as [Scenario.record] derives it:
/// settled calls (right + wrong), open ones, unavailable ones (calls with
/// no outcome the record can count, in no other figure), the hit rate as
/// an integer percent (null with nothing settled), and the clock it is as
/// of.
typedef RecordMetrics = ({
  int settled,
  int right,
  int wrong,
  int open,
  int unavailable,
  int? hitRatePct,
  DateTime asOf,
});

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
  /// before listing), its id once listed (the symbol, as markets use), and
  /// when it was listed: the clock at listing, or the seed's
  /// [YourMarketMock.listedAt] when `HAS_MARKET` starts with it listed.
  static final hasMarket = ValueNotifier<bool>(_startWithMarket);
  static final ticker = ValueNotifier<String>(PortfolioMock.marketSymbol);
  static final marketId = ValueNotifier<String?>(_seedMarketId);
  static final listedAt = ValueNotifier<DateTime?>(_seedListedAt);

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

  /// The side the active persona's latest fill in each Arena battle took,
  /// by clash id: part of its books, so it changes hands with [receipts] on
  /// [switchPersona]. Only [placeOrder] adds to it, on a fill.
  static final participation = ValueNotifier<Map<String, TradeSide>>(const {});

  /// The Arena's sort, crowd-split range and Ask query, shared by the list
  /// and the crowd panel.
  static final arena = ValueNotifier<ArenaView>(ArenaMock.allBattles);

  /// Fee credits to the user's market, newest first: the demo ledger
  /// (VC-MKT-004). Every fee total is summed from these, never stored.
  static final feeEntries = ValueNotifier<List<FeeEntry>>(YourMarketMock.fees);

  /// Published calls' receipts (VC-REC-001). Record lists and Call details
  /// resolve to these; paper fills stay in [receipts].
  static final callReceipts = ValueNotifier<List<CallReceipt>>(seedCalls);

  /// Presenter-only (Settings › Simulate load failure): the Explore list
  /// shows its failed state until Retry turns this off. Nothing else
  /// reads it.
  static final marketsLoadFails = ValueNotifier<bool>(false);

  /// Who the demo acts as (VC-DEM-004). [cashCents], [positions],
  /// [openOrders], [receipts] and [participation] hold this persona's
  /// books; the other's wait in [_parked]. Everything else is shared, and
  /// the fee ledger is the creator's.
  static final activePersona = ValueNotifier<Persona>(Persona.creator);
  static Books _parked = _copierSeed;

  static const Books _copierSeed = (
    cashCents: PortfolioMock.copierCashCents,
    positions: [],
    openOrders: [],
    receipts: [],
    participation: {},
  );

  static Books get _active => (
    cashCents: cashCents.value,
    positions: positions.value,
    openOrders: openOrders.value,
    receipts: receipts.value,
    participation: participation.value,
  );

  /// [p]'s books, active or parked.
  static Books booksOf(Persona p) =>
      p == activePersona.value ? _active : _parked;

  /// Acts as the other persona. Each keeps its own books; nothing
  /// financial changes, it only changes hands.
  static void switchPersona() {
    final next = _parked;
    _parked = _active;
    cashCents.value = next.cashCents;
    positions.value = next.positions;
    openOrders.value = next.openOrders;
    receipts.value = next.receipts;
    participation.value = next.participation;
    activePersona.value = activePersona.value == Persona.creator
        ? Persona.copier
        : Persona.creator;
  }

  /// The copy fee [intent] pays on a fill: [kCopyFeeCents] when it comes
  /// from a call someone other than the active persona made, else 0.
  static int copyFeeCents(OrderIntent intent) {
    final author = intent.sourceAuthorHandle;
    return author == null || author == activePersona.value.handle
        ? 0
        : kCopyFeeCents;
  }

  /// Copy fees the creator earned, newest first (the ledger's copy
  /// section). Fee totals elsewhere count market credits only.
  static List<FeeEntry> get copyFees => [
    for (final e in feeEntries.value)
      if (e.kind == FeeKind.copyFee) e,
  ];

  static String? get _seedMarketId =>
      _startWithMarket ? PortfolioMock.marketSymbol : null;

  static DateTime? get _seedListedAt =>
      _startWithMarket ? YourMarketMock.listedAt : null;

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

  /// The credits of the user's listed market dated at or after its listing:
  /// none before listing, none for a market listed under another ticker,
  /// and none from before a fresh listing existed to earn them.
  static List<FeeEntry> get marketFees {
    final since = listedAt.value;
    if (since == null) return const [];
    return [
      for (final e in feeEntries.value)
        if (e.kind == FeeKind.credit &&
            e.marketId == marketId.value &&
            !e.at.isBefore(since))
          e,
    ];
  }

  /// What [marketFees] add up to, in int cents.
  static int get marketFeesCents =>
      marketFees.fold(0, (sum, e) => sum + e.amountCents);

  /// [author]'s record, derived from [callReceipts] as of [clock] each
  /// time it is read; nothing stores it. Each call counts by its outcome
  /// at the clock ([outcomeAt]): right and wrong calls have
  /// settled, open ones have not, and a call with no outcome is counted
  /// as unavailable and in no other figure, never dropped. The hit rate is
  /// right ÷ settled as an integer percent, rounded half up in integer
  /// arithmetic.
  ///
  /// Capital-independent: it counts outcomes only and never reads a
  /// call's paper trade size ([CallReceipt.sizeCents]), so two traders
  /// with the same outcomes get the same record whatever they staked.
  static RecordMetrics record(String author) {
    var right = 0, wrong = 0, open = 0, unavailable = 0;
    for (final c in callReceipts.value) {
      if (c.author != author) continue;
      switch (outcomeAt(c, clock.value)) {
        case CallOutcome.right:
          right++;
        case CallOutcome.wrong:
          wrong++;
        case CallOutcome.open:
          open++;
        case null:
          unavailable++;
      }
    }
    final settled = right + wrong;
    return (
      settled: settled,
      right: right,
      wrong: wrong,
      open: open,
      unavailable: unavailable,
      hitRatePct: settled == 0 ? null : (right * 100 + settled ~/ 2) ~/ settled,
      asOf: clock.value,
    );
  }

  /// [c]'s outcome as of [at]. A right or wrong call has settled only once
  /// its settlement date ([CallReceipt.settledAt], "Sep 12", read in
  /// [at]'s year) is on or before [at]'s day; settling later, it is still
  /// open at [at]. A verdict with no settlement date in that form cannot be
  /// placed against the clock, so it has no outcome there (unavailable).
  static CallOutcome? outcomeAt(CallReceipt c, DateTime at) {
    final result = c.result;
    if (result == null || result == CallOutcome.open) return result;
    if (c.settledAt?.split(' ') case [final m, final d]) {
      final month = monthAbbrs.indexOf(m) + 1;
      final day = int.tryParse(d);
      if (month > 0 && day != null) {
        final on = DateTime(at.year, month, day);
        return on.isAfter(at) ? CallOutcome.open : result;
      }
    }
    return null;
  }

  /// Changes the given parts of the Arena's view.
  static void setArena({int? sort, int? from, int? to, String? query}) {
    final v = arena.value;
    arena.value = (
      sort: sort ?? v.sort,
      from: from ?? v.from,
      to: to ?? v.to,
      query: query ?? v.query,
    );
  }

  /// The user's fills on [side] of battle [clashId]. Receipts are unique
  /// by action id, so a repeated confirm counts once; a failure or a
  /// cancel leaves no receipt and counts nothing.
  static int joins(String clashId, TradeSide side) => receipts.value
      .where((r) => r.clashId == clashId && r.side == side)
      .length;

  /// Retry's refresh: [symbol]'s price context is current again.
  static void refreshPrice(String symbol) => stalePrices.value =
      Set.unmodifiable(stalePrices.value.where((s) => s != symbol));

  /// Whether [symbol] is an asset with a quote. A trader market's handle
  /// is not: trader-index tickets are not built (VC-MKT-005).
  static bool tradable(String symbol) => TradeMock.quotes.containsKey(symbol);

  /// Why [intent] can't be placed, or null. Tickets show it on their
  /// button, except a trader index, whose ticket closes with a toast
  /// instead. [placeOrder] refuses with it, so no caller places a trader
  /// index, a bad size, price or exit, a leverage under 1x, a reduce-only
  /// market order, or more than cash covers.
  static String? problem(OrderIntent intent) {
    if (!tradable(intent.symbol)) return traderIndexNotBuilt;
    if (intent.leverage < 1) return 'Choose a leverage';
    if (!(intent.units > 0) || !intent.units.isFinite) return 'Enter a size';
    if (!(intent.price > 0) || !intent.price.isFinite) return 'Enter a price';
    if (!_level(intent.takeProfit)) return 'Enter a take profit';
    if (!_level(intent.stopLoss)) return 'Enter a stop loss';
    // There is no position to reduce, so it would open one.
    if (intent.reduceOnly && intent.kind == OrderKind.market) {
      return 'Reduce only — not in the demo yet';
    }
    // Margin alone first: past cash, margin + fee need not fit an int.
    if (intent.marginCents > cashCents.value) return notEnoughFunds;
    if (intent.notionalCents > OrderIntent.maxNotionalCents) {
      return 'Size too large';
    }
    if (intent.marginCents <= 0) return 'Size too small';
    // A copy that would fill pays its copy fee from the same cash.
    final copyFee = intent.kind == OrderKind.market ? copyFeeCents(intent) : 0;
    if (intent.totalCents + copyFee > cashCents.value) return notEnoughFunds;
    return null;
  }

  /// An exit is unset, or a real price.
  static bool _level(double? price) =>
      price == null || (price > 0 && price.isFinite);

  /// The most margin cash covers at [leverage], leaving room for the fee
  /// and any [copyFeeCents] on top.
  static int maxMarginCents(int leverage, int feeBps, {int copyFeeCents = 0}) =>
      (cashCents.value - copyFeeCents) * 10000 ~/ (10000 + leverage * feeBps);

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
      return const OrderFailed(priceExpired);
    }
    final long = intent.side == TradeSide.long;
    final copyFee = copyFeeCents(intent);
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
      copyFeeCents: copyFee,
      sourceCallId: intent.sourceCallId,
      sourceAuthorHandle: intent.sourceAuthorHandle,
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
    // The ledger is the creator's: it earns a copier's copy fee. A copy
    // the creator makes of someone else's call pays that author, who has
    // no ledger in the demo.
    if (copyFee > 0 && activePersona.value != Persona.creator) {
      feeEntries.value = List.unmodifiable([
        FeeEntry(
          id: 'copy-$id',
          marketId: ticker.value,
          eventTitle: 'Copy fee',
          amountCents: copyFee,
          at: clock.value,
          kind: FeeKind.copyFee,
          sourceCallId: intent.sourceCallId,
          counterparty: activePersona.value.handle,
          asset: intent.symbol,
        ),
        ...feeEntries.value,
      ]);
    }
    if (intent.clashId case final clash?) {
      participation.value = Map.unmodifiable({
        ...participation.value,
        clash: intent.side,
      });
    }
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
    listedAt.value = withMarket ? YourMarketMock.listedAt : null;
    liked.value = const {};
    favoriteAssets.value = MarketsMock.assetFavorites;
    favoriteTraders.value = MarketsMock.traderFavorites;
    followers.value = FollowMock.followers;
    following.value = FollowMock.following;
    followed.value = _seedFollowed;
    clock.value = TradeMock.chartEnd;
    receipts.value = const [];
    stalePrices.value = TradeMock.stalePrices;
    participation.value = const {};
    arena.value = ArenaMock.allBattles;
    feeEntries.value = YourMarketMock.fees;
    callReceipts.value = seedCalls;
    marketsLoadFails.value = false;
    activePersona.value = Persona.creator;
    _parked = _copierSeed;
  }
}

/// The demo's two identities: the creator (today's seed) and a copier
/// with its own paper cash.
enum Persona {
  creator(PortfolioMock.handle, 'Creator'),
  copier(PortfolioMock.copierHandle, 'Copier');

  const Persona(this.handle, this.label);
  final String handle;
  final String label;
}

/// One persona's books: its financial state and the Arena sides its fills
/// took.
typedef Books = ({
  int cashCents,
  List<PortfolioPosition> positions,
  List<OpenOrder> openOrders,
  List<OrderReceipt> receipts,
  Map<String, TradeSide> participation,
});

/// What a copier pays per confirmed copy, flat (fixture constant).
const kCopyFeeCents = 500;

/// The copy line a review and a receipt show.
String copyLine(String author, int cents) =>
    'Copying @$author · ${formatCents(cents)} copy fee';

/// What a ticket can place: market fills at once, limit and stop rest.
enum OrderKind { market, limit, stop }

/// The funds failure, worded the same on both tickets and in the store.
const notEnoughFunds = 'Not enough funds';

/// The stale-price failure, the one a ticket offers Retry for.
const priceExpired = 'Price expired';

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
    this.sourceCallId,
    this.sourceAuthorHandle,
  });

  final String actionId;

  /// The call this order was opened from, and its author: a copy when
  /// the author is not the active persona.
  final String? sourceCallId;
  final String? sourceAuthorHandle;
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

  /// The largest notional the store takes, about $9 billion: times any fee
  /// rate the cent math stays under 2^53, exact as an `int` on every
  /// platform, so no cost wraps.
  static const maxNotionalCents = 900719925474;

  /// A non-finite size or price costs nothing here, so a ticket still
  /// renders; [Scenario.problem] refuses it. A notional past
  /// [maxNotionalCents] is held just past it, for the same reason.
  static int _cents(double usd) =>
      usd.isFinite ? (usd * 100).clamp(0, maxNotionalCents + 1).round() : 0;

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
    this.copyFeeCents = 0,
    this.sourceCallId,
    this.sourceAuthorHandle,
  });

  /// The copy fee paid (0 unless a copy), and the call it copied.
  final int copyFeeCents;
  final String? sourceCallId;
  final String? sourceAuthorHandle;

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

  /// What the fill took from cash.
  int get totalCents => marginCents + feeCents + copyFeeCents;
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
