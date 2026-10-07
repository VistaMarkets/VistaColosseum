import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../account/account_top_bar.dart';
import '../calls/calls_store.dart';
import '../home/home_feed.dart';
import '../live/market_prices.dart';
import '../market/trader_market_screen.dart';
import '../markets/markets_mock.dart';
import '../profile/profile_screen.dart';
import '../trade/asset_trade_screen.dart';
import '../trade/caller_play_screen.dart';
import '../trade/order_ticket.dart';
import 'arena_hub.dart';
import 'arena_mock.dart';
import 'arena_ranks.dart';
import 'live_battles_screen.dart';
import 'debate_screen.dart';
import 'pick_position_screen.dart';
import 'settlement_item.dart';
import 'take_card.dart';

/// Arena tab (Figma 559:204, ARENA-GAME): three views under the account
/// bar, Arena | Threads | Ranks, and the last one used comes back.
///
/// - Arena (`arena_hub.dart`): your season, the hottest battle face to face,
///   markets heating up, hot threads, your markets.
/// - Threads: the feed. Market rooms along the top (All, busy assets, trader
///   markets), then calls with settled calls and debates mixed in, ordered
///   Popular (the Home ranking) or Recent.
/// - Ranks (`arena_ranks.dart`): the week's and season's leaderboard.
class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key, this.onNotBuilt, this.onExplore});

  /// Called with a feature name when a control leads somewhere not built yet.
  final ValueChanged<String>? onNotBuilt;

  /// Switches to the Explore tab (from the + flow's empty state).
  final VoidCallback? onExplore;

  /// Arena, Threads or Ranks; remembered while the app runs.
  static final lastTab = ValueNotifier<int>(0);

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  /// Height the floating + button takes above the nav (button plus margins).
  static const double _composerSpace = 68;

  set _tab(int i) => ArenaScreen.lastTab.value = i;

  int _sort = 0; // ArenaMock.sorts

  /// The selected room's key; null is All.
  String? _room;

  void _push(Route<void> route) => Navigator.of(context).push(route);

  // Each room is its own list from the top; nothing restores an old offset.
  final _feedScroll = ScrollController(keepScrollOffset: false);

  @override
  void dispose() {
    _feedScroll.dispose();
    super.dispose();
  }

  /// The + : pick the position to back the take, write it, post it. The
  /// new call leads Threads: back to All and the top, so it shows whichever
  /// view or room you were in or however far you had scrolled.
  Future<void> _newTake() =>
      _post(PickPositionScreen.route(onExplore: widget.onExplore));

  /// Challenge: take the other side of [t] with a position on its market
  /// (and its debate, when it's on one).
  Future<void> _challenge(Take t) => _post(
    PickPositionScreen.route(
      onExplore: widget.onExplore,
      debate: Debates.of(t),
      ticker: t.ticker,
      side: t.side == TradeSide.long ? TradeSide.short : TradeSide.long,
    ),
  );

  Future<void> _post(Route<Take> route) async {
    final take = await Navigator.of(context).push(route);
    if (take == null || !mounted) return;
    CallsStore.add(take);
    setState(() {
      _tab = 1;
      _room = null;
    });
    if (_feedScroll.hasClients) _feedScroll.jumpTo(0);
  }

  Widget _takeItem(Take t, {bool challenge = false}) {
    final debate = Debates.of(t);
    return TakeItem(
      take: t,
      onChallenge: challenge ? () => _challenge(t) : null,
      onCaller: () => _push(ProfileScreen.route(t.handle)),
      onMarket: () => _push(TraderMarketScreen.route(t.handle)),
      onBattle: debate == null ? null : () => _push(DebateScreen.route(debate)),
      onCall: t.call == null
          ? null
          : () => _push(CallerPlayScreen.route(CallsStore.postOf(t), t.ticker)),
      // Simulated only: joining places nothing real.
      onJoin: () => showOrderTicket(context, symbol: t.ticker, side: t.side),
    );
  }

  /// Calls in the chosen order with settlements mixed in: by age for
  /// Recent; for Popular, one after every [_settlementEvery] calls, newest
  /// first.
  static const _settlementEvery = 3;

  List<Object> _feed(List<Take> calls, List<Settlement> settled) {
    if (_sort == 1) {
      final items = <(int, Object)>[
        for (final t in calls) (CallsStore.minutesAgo(t.age), t),
        for (final st in settled) (CallsStore.minutesAgo(st.when), st),
      ];
      mergeSort(items, compare: (a, b) => a.$1.compareTo(b.$1));
      return [for (final (_, x) in items) x];
    }
    final ranked = HomeFeed.forYou(calls);
    final out = <Object>[];
    var s = 0;
    for (final (i, t) in ranked.indexed) {
      out.add(t);
      if ((i + 1) % _settlementEvery == 0 && s < settled.length) {
        out.add(settled[s++]);
      }
    }
    out.addAll(settled.skip(s));
    return out;
  }

  /// Threads: rooms on top, then the feed.
  Widget _threads(double navSpace) => Column(
    children: [
      // Rooms stay put while the feed scrolls. One row that
      // scrolls sideways when they outrun the screen.
      ValueListenableBuilder(
        valueListenable: CallsStore.all,
        builder: (context, takes, _) {
          final rooms = _Room.all(takes);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              VistaSpace.gutter,
              0,
              VistaSpace.gutter,
              VistaSpace.xs,
            ),
            child: Row(
              children: [
                for (final (i, r) in rooms.indexed) ...[
                  if (i > 0) const SizedBox(width: VistaSpace.md),
                  VistaFilterChip(
                    label: r.label,
                    accent: true,
                    selected: r.key == (_room ?? ''),
                    onPressed: () => setState(() => _room = r.key),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      Expanded(
        // Every call, shared with the trade pages' Callers.
        child: ValueListenableBuilder(
          valueListenable: CallsStore.all,
          builder: (context, takes, _) {
            final room = _Room.find(takes, _room);
            final items = _feed(
              [
                for (final t in takes)
                  if (room == null || room.matches(t)) t,
              ],
              [
                for (final st in ArenaMock.settlements)
                  if (room == null || room.matchesSettlement(st)) st,
              ],
            );
            return ListView(
              key: ValueKey(_room ?? ''),
              controller: _feedScroll,
              // Room to scroll the last call clear of the + button
              // and nav.
              padding: EdgeInsets.only(
                bottom: VistaSpace.gutter + _composerSpace + navSpace,
              ),
              children: [
                if (room != null) _RoomHeader(room: room, onOpen: _push),
                ArenaSectionHead(
                  title: 'Calls',
                  top: VistaSpace.md,
                  bottom: 0,
                  trailing: _SortMenu(
                    sort: _sort,
                    onChanged: (i) => setState(() => _sort = i),
                  ),
                ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(VistaSpace.section),
                    child: Text(
                      'No calls here yet.',
                      textAlign: TextAlign.center,
                      style: VistaType.body.copyWith(
                        color: VistaColors.textMuted,
                      ),
                    ),
                  ),
                for (final item in items)
                  if (item is Settlement)
                    SettlementItem(
                      settlement: item,
                      onCaller: item.handle == null
                          ? null
                          : () => _push(ProfileScreen.route(item.handle!)),
                      onMarket: item.handle == null
                          ? null
                          : () => _push(TraderMarketScreen.route(item.handle!)),
                      onDebate: item.debate == null
                          ? null
                          : () => _push(DebateScreen.route(item.debate!)),
                    )
                  else if (item is Take)
                    _takeItem(item),
              ],
            );
          },
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    // The list runs to the bottom of the screen and scrolls under the
    // floating + button and nav, which sit over it with nothing behind them.
    final navSpace = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              // The same account bar as Home and Portfolio.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VistaSpace.gutter,
                ),
                child: AccountTopBar(
                  onNotBuilt: widget.onNotBuilt,
                  showSettings: true,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: ArenaScreen.lastTab,
                builder: (context, tab, _) => VistaSegmentedTabs(
                  labels: const ['Arena', 'Threads', 'Ranks'],
                  selectedIndex: tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: ArenaScreen.lastTab,
                  builder: (context, tab, _) => switch (tab) {
                    1 => _threads(navSpace),
                    2 => ArenaRanks(
                      bottomPadding: navSpace + VistaSize.navBar,
                      onTrader: (h) => _push(ProfileScreen.route(h)),
                    ),
                    _ => ArenaHub(
                      bottomPadding:
                          VistaSpace.gutter + _composerSpace + navSpace,
                      onRanks: () => setState(() => _tab = 2),
                      onRoom: (key) => setState(() {
                        _tab = 1;
                        _room = key;
                      }),
                      onThreads: () => setState(() {
                        _tab = 1;
                        _room = null;
                      }),
                      onDebate: (b) => _push(DebateScreen.route(b)),
                      onAllDebates: () => _push(LiveBattlesScreen.route()),
                      onNewCall: _newTake,
                      onJoin: (ticker, side) =>
                          showOrderTicket(context, symbol: ticker, side: side),
                      takeItem: (t) => _takeItem(t, challenge: true),
                    ),
                  },
                ),
              ),
            ],
          ),
          // The + floats in the lower right, just above the nav.
          ValueListenableBuilder(
            valueListenable: ArenaScreen.lastTab,
            builder: (context, tab, _) => tab == 2
                ? const SizedBox.shrink()
                : Positioned(
                    right: VistaSpace.gutter,
                    bottom: navSpace + VistaSpace.md,
                    child: _AddTakeButton(onTap: _newTake),
                  ),
          ),
        ],
      ),
    );
  }
}

/// The floating + in the lower right: starts a take by picking a position.
class _AddTakeButton extends StatelessWidget {
  const _AddTakeButton({required this.onTap});

  static const double size = 56;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Make a call',
      excludeSemantics: true,
      child: VistaPressable(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: VistaColors.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x59000000),
                offset: Offset(0, 6),
                blurRadius: 18,
              ),
            ],
          ),
          child: Text(
            '+',
            style: VistaType.displayMedium.copyWith(
              color: VistaColors.onAccent,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// A market room: an asset (by ticker) or a trader market (by handle).
class _Room {
  const _Room({
    required this.key,
    required this.label,
    this.ticker,
    this.handle,
  });

  final String key;
  final String label;
  final String? ticker;
  final String? handle;

  bool matches(Take t) =>
      ticker != null ? t.ticker == ticker : t.handle == handle;

  bool matchesSettlement(Settlement s) =>
      ticker != null ? s.marketTicker == ticker : s.handle == handle;

  /// All, the busiest assets, then trader markets with calls.
  static List<_Room> all(List<Take> takes) {
    final debates = BattlesStore.all.value;
    final assets = [
      for (final m in MarketsMock.assets)
        (
          m.id,
          takes.where((t) => t.ticker == m.id).length +
              debates.where((b) => b.ticker == m.id).length,
        ),
    ].where((a) => a.$2 > 0).toList()..sort((a, b) => b.$2.compareTo(a.$2));
    final traders = [
      for (final m in MarketsMock.traders)
        (m.id, takes.where((t) => t.handle == m.id).length),
    ].where((a) => a.$2 > 0).toList()..sort((a, b) => b.$2.compareTo(a.$2));
    return [
      const _Room(key: '', label: 'All'),
      for (final (id, _) in assets) _Room(key: id, label: id, ticker: id),
      for (final (handle, _) in traders)
        _Room(
          key: '@$handle',
          label: MarketsMock.traderCards[handle]?.symbol ?? handle,
          handle: handle,
        ),
    ];
  }

  /// The room for [key], or null for All (or a room that has emptied).
  static _Room? find(List<Take> takes, String? key) {
    if (key == null || key.isEmpty) return null;
    for (final r in all(takes)) {
      if (r.key == key) return r;
    }
    return null;
  }
}

/// The room's market at the top of its feed: name, live price and change,
/// and a way into the market.
class _RoomHeader extends StatelessWidget {
  const _RoomHeader({required this.room, required this.onOpen});

  final _Room room;
  final void Function(Route<void>) onOpen;

  @override
  Widget build(BuildContext context) {
    final r = room;
    final id = r.ticker ?? r.handle!;
    final item = [
      ...MarketsMock.assets,
      ...MarketsMock.traders,
    ].where((m) => m.id == id).firstOrNull;
    final change = item?.changePct ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VistaSpace.gutter + VistaSpace.xs,
        VistaSpace.md,
        VistaSpace.gutter + VistaSpace.xs,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: MarketPrices.of(id),
              builder: (context, price, _) => Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: r.label, style: VistaType.headline),
                    if (r.handle != null)
                      TextSpan(
                        text: ' ${r.handle}',
                        style: VistaType.bodyMedium.copyWith(
                          color: VistaColors.textMuted,
                        ),
                      ),
                    TextSpan(
                      text: '  ${MarketPrices.format(price, compact: true)} ',
                      style: VistaType.figures(VistaType.subhead),
                    ),
                    TextSpan(
                      text: vistaChangeLabel(change),
                      style: VistaType.figures(VistaType.label)
                          .copyWith(color: vistaChangeColor(change)),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Open the ${r.label} market',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onOpen(
                r.ticker != null
                    ? AssetTradeScreen.route(r.ticker!)
                    : TraderMarketScreen.route(r.handle!),
              ),
              child: SizedBox(
                height: VistaSize.tapTarget,
                child: Center(
                  child: Text(
                    'Trade ›',
                    style: VistaType.subhead.copyWith(
                      color: VistaColors.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Popular ▾" by the Calls heading: picks how the calls are ordered.
class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sort, required this.onChanged});

  final int sort;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: '',
      initialValue: sort,
      color: VistaColors.surfaceRaised,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        for (var i = 0; i < ArenaMock.sorts.length; i++)
          PopupMenuItem(
            value: i,
            child: Text(
              ArenaMock.sorts[i],
              style: VistaType.subhead.copyWith(
                color: i == sort ? VistaColors.accent : VistaColors.textPrimary,
              ),
            ),
          ),
      ],
      child: Semantics(
        button: true,
        label: 'Sort calls: ${ArenaMock.sorts[sort]}',
        excludeSemantics: true,
        child: SizedBox(
          height: VistaSize.tapTarget,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ArenaMock.sorts[sort],
                  style: VistaType.bodyMedium.copyWith(
                    color: VistaColors.textMuted,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: VistaColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
