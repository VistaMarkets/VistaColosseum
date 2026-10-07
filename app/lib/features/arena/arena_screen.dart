import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../account/account_top_bar.dart';
import '../calls/calls_store.dart';
import '../home/home_feed.dart';
import '../live/market_prices.dart';
import '../market/trader_market_screen.dart';
import '../markets/markets_mock.dart';
import '../people/follow_state.dart';
import '../profile/profile_screen.dart';
import '../trade/caller_play_screen.dart';
import '../trade/order_ticket.dart';
import '../portfolio/portfolio_mock.dart';
import '../portfolio/positions_state.dart';
import 'arena_feed_screen.dart';
import 'arena_mock.dart';
import 'debate_screen.dart';
import 'pick_position_screen.dart';
import 'room_screen.dart';
import 'hub_call_card.dart';

/// Arena tab (Figma 551:205, ARENA-HUB-01): the account bar, search, your
/// markets and what's trending as people-first rows (who is in, which way),
/// then the top calls. A market's row opens its room
/// (`RoomScreen`), and See all opens every call (`ArenaFeedScreen`). The + makes a
/// call from a position.
class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key, this.onNotBuilt, this.onExplore});

  /// Called with a feature name when a control leads somewhere not built yet.
  final ValueChanged<String>? onNotBuilt;

  /// Switches to the Explore tab (from the + flow's empty state).
  final VoidCallback? onExplore;

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  /// Room for the floating + above the nav (button plus margins).
  static const double _plusSpace = 68;

  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _push(Route<void> route) => Navigator.of(context).push(route);

  /// Every call, opened on [room] (a ticker or "@handle") or All.
  void _feed([String? room]) =>
      _push(ArenaFeedScreen.route(onExplore: widget.onExplore, room: room));

  /// A market's room (a ticker or "@handle").
  void _room(String key) =>
      _push(RoomScreen.route(key, onExplore: widget.onExplore));

  /// The + : pick a position, write the call, post it. It leads Calls.
  Future<void> _newCall() async {
    final take = await Navigator.of(context)
        .push(PickPositionScreen.route(onExplore: widget.onExplore));
    if (take != null) CallsStore.add(take);
  }

  /// "$eth", "ETH", "@maya.eth" or "maya" opens that market's room.
  void _find(String q) {
    final s = q.trim().replaceFirst(RegExp(r'^[\$@]'), '').toLowerCase();
    if (s.isEmpty) return;
    for (final m in MarketsMock.assets) {
      if (m.id.toLowerCase() == s) return _room(m.id);
    }
    for (final m in MarketsMock.traders) {
      final symbol = MarketsMock.traderCards[m.id]?.symbol.toLowerCase();
      if (m.id.toLowerCase().startsWith(s) || symbol == s) {
        return _room('@${m.id}');
      }
    }
    widget.onNotBuilt?.call('Search');
  }

  @override
  Widget build(BuildContext context) {
    final navSpace = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              // The same account bar as Home and Explore.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VistaSpace.gutter,
                ),
                child: AccountTopBar(
                  onNotBuilt: widget.onNotBuilt,
                  showSettings: true,
                ),
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: CallsStore.all,
                  builder: (context, calls, _) => ValueListenableBuilder(
                    // Your markets are the ones you hold (Portfolio).
                    valueListenable: PositionsState.open,
                    builder: (context, positions, _) => ListView(
                      padding: EdgeInsets.only(
                        bottom: VistaSpace.gutter + _plusSpace + navSpace,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            VistaSpace.gutter,
                            VistaSpace.xl,
                            VistaSpace.gutter,
                            0,
                          ),
                          child: VistaSearchField(
                            hint: r'Search $tickers or @people',
                            controller: _search,
                            onChanged: (_) {},
                            onSubmitted: _find,
                          ),
                        ),
                        const _Head('Your markets'),
                        if (_yourMarkets(calls, positions).isEmpty)
                          _NoMarkets(onExplore: widget.onExplore),
                        for (final r in _yourMarkets(calls, positions))
                          _RoomRow(room: r, onTap: () => _room(r.key)),
                        const _Head('Trending now'),
                        for (final r in _trending(calls))
                          _RoomRow(room: r, onTap: () => _room(r.key)),
                        _Head('Calls', trailing: 'See all', onTrailing: _feed),
                        for (final t in [
                          for (final t in HomeFeed.forYou(calls))
                            if (t.call != null) t,
                        ].take(2))
                          HubCallCard(
                            take: t,
                            onCaller: () =>
                                _push(ProfileScreen.route(t.handle)),
                            onMarket: () =>
                                _push(TraderMarketScreen.route(t.handle)),
                            onDebate: Debates.of(t) == null
                                ? null
                                : () =>
                                      _push(DebateScreen.route(Debates.of(t)!)),
                            onPosition: () => _push(
                              CallerPlayScreen.route(
                                CallsStore.postOf(t),
                                t.ticker,
                              ),
                            ),
                            onJoin: () => showOrderTicket(
                              context,
                              symbol: t.ticker,
                              side: t.side,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // The + floats in the lower right, just above the nav.
          Positioned(
            right: VistaSpace.gutter,
            bottom: navSpace + VistaSpace.md,
            child: _PlusButton(onTap: _newCall),
          ),
        ],
      ),
    );
  }

  /// Every market you hold a position in (Portfolio), in Portfolio's
  /// order, once each, with your position on it.
  static List<_Room> _yourMarkets(
    List<Take> calls,
    List<PortfolioPosition> positions,
  ) {
    final seen = <String>{};
    return [
      for (final p in positions)
        if (seen.add(p.detail.symbol))
          for (final m in [...MarketsMock.assets, ...MarketsMock.traders])
            if (m.id == p.detail.symbol)
              MarketsMock.traders.contains(m)
                  ? _Room.trader(m, calls, held: p)
                  : _Room.asset(m, calls, held: p),
    ];
  }

  static List<_Room> _trending(List<Take> calls) => [
    for (final t in ArenaMock.trending)
      for (final m in [...MarketsMock.assets, ...MarketsMock.traders])
        if (m.id == t.id)
          MarketsMock.traders.contains(m)
              ? _Room.trader(m, calls, trend: t)
              : _Room.asset(m, calls, trend: t),
  ];
}

/// A market as the hub shows it: its line, and who is in it.
class _Room {
  _Room({
    required this.key,
    required this.market,
    required this.title,
    required this.sub,
    required this.calls,
    required this.people,
    required this.line,
    this.trader,
    this.reason,
  });

  /// An asset's room: its calls today and debates, and who is in which way.
  factory _Room.asset(
    MarketItem m,
    List<Take> calls, {
    Trend? trend,
    PortfolioPosition? held,
  }) {
    final on = calls.where((t) => t.ticker == m.id).toList();
    final debates = BattlesStore.all.value
        .where((b) => b.ticker == m.id)
        .length;
    // Everyone with a call on it, most liked first.
    final backed = [...on]..sort((a, b) => b.likes.compareTo(a.likes));
    final longs = backed.where((t) => t.side == TradeSide.long).toList();
    final shorts = backed.where((t) => t.side == TradeSide.short).toList();
    final followed = backed
        .where((t) => FollowState.isFollowing(t.handle))
        .toList();
    final majority = longs.length >= shorts.length
        ? TradeSide.long
        : TradeSide.short;
    final side = majority == TradeSide.long ? longs : shorts;
    final List<InlineSpan> line;
    final List<String> people;
    if (longs.isNotEmpty && shorts.isNotEmpty && followed.isEmpty) {
      people = [longs.first.handle, shorts.first.handle];
      line = [
        _strong(longs.first.handle),
        _muted(' is long, '),
        _strong(shorts.first.handle),
        _muted(' is short'),
      ];
    } else if (side.isNotEmpty) {
      final others = {for (final t in side) t.handle}.toList();
      final you = others.where(FollowState.isFollowing).length;
      people = others.take(3).toList();
      line = [
        _strong(others.first),
        _muted(
          you > 1 || (you == 1 && !FollowState.isFollowing(others.first))
              ? ' and ${you - (FollowState.isFollowing(others.first) ? 1 : 0)} you follow are '
              : others.length > 1
              ? ' and ${others.length - 1} others are '
              : ' is ',
        ),
        _sideSpan(majority),
      ];
    } else {
      people = const [];
      line = [_muted('No calls yet. Be first.')];
    }
    final n = on.length;
    return _Room(
      key: m.id,
      market: m,
      title: m.name,
      sub:
          trend?.note ??
          [
            ?_yours(held),
            '$n call${n == 1 ? '' : 's'} today',
            if (debates > 0) '$debates debate${debates == 1 ? '' : 's'}',
          ].join(' · '),
      calls: n,
      people: people,
      line: line,
      reason: trend?.reason,
    );
  }

  /// A trader market's room: its owner and record, and who holds it.
  factory _Room.trader(
    MarketItem m,
    List<Take> calls, {
    Trend? trend,
    PortfolioPosition? held,
  }) {
    final symbol = MarketsMock.traderCards[m.id]?.symbol ?? m.name;
    final record = CallsStore.recordOf(m.id);
    final holders = ArenaMock.holders[m.id];
    final bought = ArenaMock.boughtToday[m.id];
    final List<InlineSpan> line;
    final List<String> people;
    if (trend != null && bought != null) {
      people = {bought, ...?holders?.names}.take(2).toList();
      line = [_strong(bought), _muted(' bought $symbol today')];
    } else if (holders != null) {
      people = holders.names;
      line = [
        _strong(holders.names.first),
        _muted(' and ${holders.count - 1} others hold $symbol'),
      ];
    } else if (held != null) {
      people = [PortfolioMock.handle];
      line = [_strong('You'), _muted(' hold $symbol')];
    } else {
      people = const [];
      line = [_muted('Be the first to hold $symbol')];
    }
    return _Room(
      key: '@${m.id}',
      market: m,
      trader: m.id,
      title: symbol,
      sub: [?_yours(held), m.id, ?record].join(' · '),
      calls: calls.where((t) => t.handle == m.id).length,
      people: people,
      line: line,
      reason: trend?.reason,
    );
  }

  final String key;
  final MarketItem market;
  final String? trader;
  final String title;
  final String sub;
  final int calls;
  final List<String> people;
  final List<InlineSpan> line;
  final String? reason;

  /// "You: LONG 5x", for a market you hold.
  static String? _yours(PortfolioPosition? p) =>
      p == null ? null : 'You: ${p.side.label.toUpperCase()} ${p.leverage}x';

  static TextSpan _strong(String s) => TextSpan(
    text: s,
    style: const TextStyle(color: VistaColors.textPrimary),
  );
  static TextSpan _muted(String s) => TextSpan(
    text: s,
    style: const TextStyle(
      color: VistaColors.textMuted,
      fontWeight: FontWeight.w500,
    ),
  );
  static TextSpan _sideSpan(TradeSide s) => TextSpan(
    text: s.label.toLowerCase(),
    style: TextStyle(color: s.color),
  );
}

/// Your markets with nothing held: they come from your positions.
class _NoMarkets extends StatelessWidget {
  const _NoMarkets({this.onExplore});

  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VistaSpace.gutter + VistaSpace.xs,
        VistaSpace.xs,
        VistaSpace.gutter + VistaSpace.xs,
        VistaSpace.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Markets you hold show here.',
              style: VistaType.bodyMedium.copyWith(
                color: VistaColors.textMuted,
              ),
            ),
          ),
          if (onExplore != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onExplore,
              child: SizedBox(
                height: VistaSize.tapTarget,
                child: Center(
                  child: Text(
                    'Find a market ›',
                    style: VistaType.subhead.copyWith(
                      color: VistaColors.accent,
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

/// Section title with an optional link on the right.
class _Head extends StatelessWidget {
  const _Head(this.title, {this.trailing, this.onTrailing});

  final String title;
  final String? trailing;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VistaSpace.gutter + VistaSpace.xs,
        VistaSpace.lg,
        VistaSpace.gutter + VistaSpace.xs,
        0,
      ),
      child: SizedBox(
        height: VistaSize.tapTarget,
        child: Row(
          children: [
            Expanded(child: Text(title, style: VistaType.title)),
            if (trailing != null)
              Semantics(
                button: true,
                label: '$trailing: $title',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTrailing,
                  child: SizedBox(
                    height: VistaSize.tapTarget,
                    child: Center(
                      child: Text(
                        trailing!,
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
      ),
    );
  }
}

/// A market row (Figma room/ETH): icon, name (with why it's trending),
/// a second line, live price and change, then who is in it.
class _RoomRow extends StatelessWidget {
  const _RoomRow({required this.room, required this.onTap});

  final _Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = room;
    final m = r.market;
    return Semantics(
      button: true,
      label: '${r.title} room',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            VistaSpace.gutter + VistaSpace.xs,
            VistaSpace.xl,
            VistaSpace.gutter + VistaSpace.xs,
            VistaSpace.xl,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: VistaColors.hairline)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (r.trader != null)
                    PersonInitial(r.trader!, size: 36)
                  else
                    VistaIcon(m.rowIcon, size: 36),
                  const SizedBox(width: VistaSpace.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: r.title),
                              if (r.reason != null)
                                TextSpan(
                                  text: '  ${r.reason}',
                                  style: VistaType.subhead.copyWith(
                                    color: VistaColors.accent,
                                  ),
                                ),
                            ],
                          ),
                          style: VistaType.headline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: VistaSpace.xxs),
                        Text(
                          r.sub,
                          style: VistaType.bodyMedium.copyWith(
                            color: VistaColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: VistaSpace.md),
                  ValueListenableBuilder(
                    valueListenable: MarketPrices.of(m.id),
                    builder: (context, price, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          MarketPrices.format(price, compact: true),
                          style: VistaType.figures(VistaType.subhead),
                        ),
                        const SizedBox(height: VistaSpace.xxs),
                        Text(
                          vistaChangeLabel(m.changePct),
                          style: VistaType.figures(VistaType.chip)
                              .copyWith(color: vistaChangeColor(m.changePct)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VistaSpace.md),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Row(
                  children: [
                    if (r.people.isNotEmpty) ...[
                      SizedBox(
                        width: 22.0 + (r.people.length - 1) * 16,
                        height: 22,
                        child: Stack(
                          children: [
                            for (final (i, h) in r.people.indexed)
                              Positioned(
                                left: i * 16.0,
                                child: PersonInitial(h),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: VistaSpace.md),
                    ],
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: r.line),
                        style: VistaType.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The floating + in the lower right: starts a call by picking a position.
class _PlusButton extends StatelessWidget {
  const _PlusButton({required this.onTap});

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
          width: 56,
          height: 56,
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
