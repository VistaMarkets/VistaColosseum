import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../calls/calls_store.dart';
import '../home/home_feed.dart';
import '../live/market_prices.dart';
import '../market/trader_market_screen.dart';
import '../markets/markets_mock.dart';
import '../people/follow_state.dart';
import '../portfolio/portfolio_mock.dart';
import '../profile/profile_screen.dart';
import '../trade/asset_trade_screen.dart';
import '../trade/caller_play_screen.dart';
import '../trade/order_ticket.dart';
import '../watchlist/watchlist_state.dart';
import 'arena_mock.dart';
import 'debate_screen.dart';
import 'hub_call_card.dart';
import 'pick_position_screen.dart';
import 'take_card.dart';

/// A market's room (Figma 551:237, ARENA-HUB-02), opened from the Arena
/// hub's Your markets and Trending rows: the market and Follow room (which
/// adds it to your favourites, so it shows in Your markets), who is most
/// often right on it, then its calls (Top or New) or its debates, and a
/// bar to post a call on it from a position on it.
///
/// [roomKey] is a ticker ("ETH") or "@handle" for a trader's market.
class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key, required this.roomKey, this.onExplore});

  final String roomKey;
  final VoidCallback? onExplore;

  static Route<void> route(String roomKey, {VoidCallback? onExplore}) =>
      MaterialPageRoute(
        builder: (_) => RoomScreen(roomKey: roomKey, onExplore: onExplore),
      );

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  int _tab = 0; // Top, New, Debates

  bool get _trader => widget.roomKey.startsWith('@');
  String get _id => _trader ? widget.roomKey.substring(1) : widget.roomKey;

  MarketItem get _market => [
    ...MarketsMock.assets,
    ...MarketsMock.traders,
  ].firstWhere((m) => m.id == _id);

  String get _title =>
      _trader ? MarketsMock.traderCards[_id]?.symbol ?? _id : _id;

  bool _inRoom(Take t) => _trader ? t.handle == _id : t.ticker == _id;

  void _push(Route<void> route) => Navigator.of(context).push(route);

  ValueNotifier<List<String>> get _favs =>
      _trader ? WatchlistState.traders : WatchlistState.assets;

  void _toggleFollow() => _trader
      ? WatchlistState.toggleTrader(_id)
      : WatchlistState.toggleAsset(_id);

  void _trade() => _push(
    _trader ? TraderMarketScreen.route(_id) : AssetTradeScreen.route(_id),
  );

  Future<void> _post() async {
    final take = await Navigator.of(
      context,
    ).push(PickPositionScreen.route(onExplore: widget.onExplore, ticker: _id));
    if (take == null || !mounted) return;
    CallsStore.add(take);
    setState(() => _tab = 1);
  }

  /// The three most right on this market: from the asset's 30-day
  /// records (always three); for a trader's market, from its calls.
  List<(String, int?, int)> _mostRight(List<Take> calls) {
    final known = ArenaMock.mostRightIn[_id];
    if (!_trader && known != null) {
      return [for (final (h, pct, n) in known) (h, pct, n)];
    }
    return [for (final (h, n) in _fromCalls(calls)) (h, null, n)];
  }

  /// Who has called this market, most often right first.
  List<(String, int)> _fromCalls(List<Take> calls) {
    final counts = <String, int>{};
    for (final t in calls.where(_inRoom)) {
      counts[t.handle] = (counts[t.handle] ?? 0) + 1;
    }
    int pct(String h) =>
        int.tryParse((CallsStore.recordOf(h) ?? '').split('%').first) ?? 0;
    final list = counts.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => pct(b.$1).compareTo(pct(a.$1)));
    return list.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final m = _market;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ValueListenableBuilder(
              valueListenable: CallsStore.all,
              builder: (context, calls, _) {
                final debates = BattlesStore.all.value
                    .where((b) => !_trader && b.ticker == _id)
                    .toList();
                final top = [
                  for (final t in HomeFeed.forYou(calls))
                    if (_inRoom(t)) t,
                ];
                final fresh = [...top]
                  ..sort(
                    (a, b) =>
                        CallsStore.minutesAgo(a.age)
                            .compareTo(CallsStore.minutesAgo(b.age)),
                  );
                return ListView(
                  padding: EdgeInsets.only(bottom: 90 + bottom),
                  children: [
                    _header(m),
                    _MostRightHead(title: _title),
                    for (final (h, pct, n) in _mostRight(calls))
                      _PersonRow(
                        handle: h,
                        percentRight: pct,
                        calls: n,
                        title: _title,
                        onTap: () => _push(ProfileScreen.route(h)),
                        onMarket: () => _push(TraderMarketScreen.route(h)),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        VistaSpace.gutter + VistaSpace.xs,
                        VistaSpace.sm,
                        VistaSpace.gutter + VistaSpace.xs,
                        0,
                      ),
                      child: Text(
                        'By % right on settled $_title calls. '
                        'No ranks or badges.',
                        style: VistaType.chip.copyWith(
                          color: VistaColors.textMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    _Tabs(
                      labels: [
                        'Top',
                        'New',
                        if (!_trader) 'Debates (${debates.length})',
                      ],
                      selected: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                    if (_tab == 2)
                      for (final b in debates)
                        BattleTile.row(
                          battle: b,
                          onTap: () => _push(DebateScreen.route(b)),
                        )
                    else ...[
                      if ((_tab == 0 ? top : fresh).isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(VistaSpace.section),
                          child: Text(
                            'No calls on $_title yet.',
                            textAlign: TextAlign.center,
                            style: VistaType.body.copyWith(
                              color: VistaColors.textMuted,
                            ),
                          ),
                        ),
                      for (final t in _tab == 0 ? top : fresh)
                        HubCallCard(
                          take: t,
                          onCaller: () => _push(ProfileScreen.route(t.handle)),
                          onMarket: () =>
                              _push(TraderMarketScreen.route(t.handle)),
                          onDebate: Debates.of(t) == null
                              ? null
                              : () => _push(DebateScreen.route(Debates.of(t)!)),
                          onPosition: () {
                            if (t.call == null) return;
                            _push(
                              CallerPlayScreen.route(
                                CallsStore.postOf(t),
                                t.ticker,
                              ),
                            );
                          },
                          onJoin: () => showOrderTicket(
                            context,
                            symbol: t.ticker,
                            side: t.side,
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
            // Post a call on this market (needs a position on it); a trader's
            // market is traded rather than called.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: VistaColors.background.withValues(alpha: 0.96),
                padding: EdgeInsets.fromLTRB(
                  VistaSpace.gutter,
                  VistaSpace.md,
                  VistaSpace.gutter,
                  bottom > 0 ? bottom : VistaSpace.gutter,
                ),
                child: Semantics(
                  button: true,
                  excludeSemantics: true,
                  label: _trader ? 'Trade $_title' : 'Post a call on $_title',
                  child: VistaPressable(
                    scale: 0.98,
                    onTap: _trader ? _trade : _post,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: VistaColors.accent,
                        borderRadius: BorderRadius.circular(VistaRadius.pill),
                      ),
                      child: Text(
                        _trader ? 'Trade $_title' : 'Post a call on $_title',
                        style: VistaType.subhead.copyWith(
                          fontSize: 16,
                          color: Colors.white,
                        ),
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

  /// Back, the market and its price (Trade ›), Follow room.
  Widget _header(MarketItem m) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VistaSpace.sm,
        VistaSpace.md,
        VistaSpace.gutter,
        0,
      ),
      child: Row(
        children: [
          VistaIconButton(
            asset: VistaAssets.backSmall,
            semanticLabel: 'Back',
            iconSize: VistaSize.icon,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: VistaSpace.xs),
          if (_trader)
            PersonInitial(_id, size: 32)
          else
            VistaIcon(m.rowIcon, size: 32),
          const SizedBox(width: VistaSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_title room',
                  style: VistaType.title.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _trade,
                  // One line: shrinks a little on small phones.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: ValueListenableBuilder(
                      valueListenable: MarketPrices.of(m.id),
                      builder: (context, price, _) => Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '${MarketPrices.format(price, compact: true)} ',
                            ),
                            TextSpan(
                              text:
                                  '${m.changePct >= 0 ? '▲' : '▼'}'
                                  '${m.changePct.abs().toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: vistaChangeColor(m.changePct),
                              ),
                            ),
                            const TextSpan(
                              text: '  · Trade ›',
                              style: TextStyle(color: VistaColors.accent),
                            ),
                          ],
                        ),
                        style: VistaType.figures(VistaType.body),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _favs,
            builder: (context, favs, _) {
              final on = favs.contains(_id);
              return Semantics(
                button: true,
                toggled: on,
                label: on ? 'Following room' : 'Follow room',
                excludeSemantics: true,
                child: VistaPressable(
                  scale: 0.96,
                  onTap: _toggleFollow,
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(
                      horizontal: VistaSpace.xxl,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on
                          ? VistaColors.textMuted.withValues(alpha: 0.14)
                          : VistaColors.accent,
                      borderRadius: BorderRadius.circular(VistaRadius.pill),
                    ),
                    child: Text(
                      on ? 'Following' : 'Follow room',
                      style: VistaType.body.copyWith(
                        fontSize: 14,
                        color: on
                            ? VistaColors.textMuted
                            : VistaColors.onAccent,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MostRightHead extends StatelessWidget {
  const _MostRightHead({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VistaSpace.gutter + VistaSpace.xs,
        VistaSpace.section,
        VistaSpace.gutter + VistaSpace.xs,
        VistaSpace.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Most right in $title',
              style: VistaType.title.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '30 days',
            style: VistaType.bodyMedium.copyWith(color: VistaColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// One of the most right: who, their record and calls here, their own
/// market, Follow.
class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.handle,
    this.percentRight,
    required this.calls,
    required this.title,
    required this.onTap,
    required this.onMarket,
  });

  final String handle;

  /// % right on this market; their overall record when null.
  final int? percentRight;
  final int calls;
  final String title;
  final VoidCallback onTap;
  final VoidCallback onMarket;

  @override
  Widget build(BuildContext context) {
    final record = percentRight != null
        ? '$percentRight%'
        : CallsStore.recordOf(handle)?.split(' ').first;
    final market = MarketsMock.traders.where((m) => m.id == handle);
    final mine = handle == PortfolioMock.handle;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VistaSpace.gutter + VistaSpace.xs,
          vertical: VistaSpace.lg,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: VistaColors.hairline)),
        ),
        child: Row(
          children: [
            PersonInitial(handle, size: 40, ring: VistaColors.surfaceRaised),
            const SizedBox(width: VistaSpace.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: handle),
                        if (record != null)
                          TextSpan(
                            text: '  $record right',
                            style: const TextStyle(color: VistaColors.long),
                          ),
                        TextSpan(
                          text: ' · $calls $title call${calls == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: VistaColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    style: VistaType.body.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (market.isNotEmpty)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onMarket,
                      child: Padding(
                        padding: const EdgeInsets.only(top: VistaSpace.xxs),
                        child: ValueListenableBuilder(
                          valueListenable: MarketPrices.of(handle),
                          builder: (context, price, _) {
                            final ch = market.first.changePct;
                            return Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '${MarketsMock.traderCards[handle]?.symbol ?? handle} ',
                                    style: const TextStyle(
                                      color: VistaColors.textMuted,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '${MarketPrices.format(price, compact: true)} ',
                                  ),
                                  TextSpan(
                                    text:
                                        '${ch >= 0 ? '▲' : '▼'}${ch.abs().toStringAsFixed(1)}% · Open market ›',
                                    style: TextStyle(
                                      color: vistaChangeColor(ch),
                                    ),
                                  ),
                                ],
                              ),
                              style: VistaType.figures(VistaType.chip),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!mine) ...[
              const SizedBox(width: VistaSpace.md),
              // The app's Follow button, shared with profiles and lists.
              ValueListenableBuilder(
                valueListenable: FollowState.following,
                builder: (context, following, _) => VistaFollowButton(
                  following: following.contains(handle),
                  onPressed: () => FollowState.toggle(handle),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Top · New · Debates (n): underlined text tabs.
class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VistaSpace.gutter + VistaSpace.xs,
        VistaSpace.lg,
        VistaSpace.gutter + VistaSpace.xs,
        0,
      ),
      child: Row(
        children: [
          for (final (i, l) in labels.indexed) ...[
            if (i > 0) const SizedBox(width: VistaSpace.section),
            Semantics(
              button: true,
              selected: i == selected,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: SizedBox(
                  height: VistaSize.tapTarget,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l,
                        style: VistaType.tab.copyWith(
                          color: i == selected
                              ? VistaColors.textPrimary
                              : VistaColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: VistaSpace.sm),
                      Container(
                        width: 28,
                        height: 3,
                        decoration: BoxDecoration(
                          color: i == selected
                              ? VistaColors.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
