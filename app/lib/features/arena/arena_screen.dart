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
import '../watchlist/watchlist_state.dart';
import 'arena_feed_screen.dart';
import 'arena_mock.dart';
import 'debate_screen.dart';
import 'pick_position_screen.dart';
import 'take_card.dart';

/// Arena tab (Figma 551:205, ARENA-HUB-01): the account bar, search, your
/// markets and what's trending as people-first rows (who is in, which way),
/// then the top calls with their top reply. A market's row opens its room,
/// and Calls › See all opens every call (`ArenaFeedScreen`). The + makes a
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
      if (m.id.toLowerCase() == s) return _feed(m.id);
    }
    for (final m in MarketsMock.traders) {
      final symbol = MarketsMock.traderCards[m.id]?.symbol.toLowerCase();
      if (m.id.toLowerCase().startsWith(s) || symbol == s) {
        return _feed('@${m.id}');
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
                    valueListenable: WatchlistState.assets,
                    builder: (context, favs, _) => ListView(
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
                        for (final r in _yourMarkets(calls, favs))
                          _RoomRow(room: r, onTap: () => _feed(r.key)),
                        _Head(
                          'Trending now',
                          trailing: 'See all',
                          onTrailing: _feed,
                        ),
                        for (final r in _trending(calls))
                          _RoomRow(room: r, onTap: () => _feed(r.key)),
                        _Head('Calls', trailing: 'See all', onTrailing: _feed),
                        for (final t in [
                          for (final t in HomeFeed.forYou(calls))
                            if (t.call != null) t,
                        ].take(2))
                          _HubCall(
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
                            onReplies: () => _feed(t.ticker),
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

  /// Your favourite assets (busiest first, two) and your first favourite
  /// trader market.
  static List<_Room> _yourMarkets(List<Take> calls, List<String> favs) {
    final assets = [
      for (final m in MarketsMock.assets)
        if (favs.contains(m.id)) _Room.asset(m, calls),
    ]..sort((a, b) => b.calls.compareTo(a.calls));
    final traders = [
      for (final m in MarketsMock.traders)
        if (WatchlistState.isTrader(m.id)) _Room.trader(m, calls),
    ];
    return [...assets.take(2), ...traders.take(1)];
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
  factory _Room.asset(MarketItem m, List<Take> calls, {Trend? trend}) {
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
  factory _Room.trader(MarketItem m, List<Take> calls, {Trend? trend}) {
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
    } else {
      people = const [];
      line = [_muted('Be the first to hold $symbol')];
    }
    return _Room(
      key: '@${m.id}',
      market: m,
      trader: m.id,
      title: symbol,
      sub: [m.id, ?record].join(' · '),
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

/// An initial in a filled circle (a person until avatars come from the
/// backend).
class _Initial extends StatelessWidget {
  const _Initial(this.handle, {this.size = 22, this.ring});

  final String handle;
  final double size;
  final Color? ring;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: VistaColors.surfaceRaised,
      shape: BoxShape.circle,
      border: Border.all(
        color: ring ?? VistaColors.background,
        width: size > 30 ? 2.5 : 2,
      ),
    ),
    child: Text(
      handle.isEmpty ? '' : handle[0].toUpperCase(),
      style: VistaType.labelStrong.copyWith(
        fontSize: size * 0.4,
        color: VistaColors.textPrimary,
        height: 1,
      ),
    ),
  );
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
                    _Initial(r.trader!, size: 36)
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
                              Positioned(left: i * 16.0, child: _Initial(h)),
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

/// A call on the hub (Figma call · @maya.eth): the caller and record, their
/// market, the position and debate badges, the call, its live position, like
/// / replies / counters / Join, then the top reply.
class _HubCall extends StatelessWidget {
  const _HubCall({
    required this.take,
    required this.onCaller,
    required this.onMarket,
    required this.onPosition,
    required this.onJoin,
    required this.onReplies,
    this.onDebate,
  });

  final Take take;
  final VoidCallback onCaller;
  final VoidCallback onMarket;
  final VoidCallback onPosition;
  final VoidCallback onJoin;
  final VoidCallback onReplies;
  final VoidCallback? onDebate;

  @override
  Widget build(BuildContext context) {
    final t = take;
    final c = t.call!;
    final thread = ArenaMock.threadOf(t);
    final record = t.accuracy.split(' ').first;
    final good = (int.tryParse(record.replaceAll('%', '')) ?? 0) >= 55;
    final muted = VistaType.bodyMedium.copyWith(color: VistaColors.textMuted);
    final market = MarketsMock.traders.where((m) => m.id == t.handle);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        VistaSpace.gutter + VistaSpace.xs,
        VistaSpace.gutter,
        VistaSpace.gutter + VistaSpace.xs,
        VistaSpace.lg,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: VistaColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: "${t.handle}'s profile",
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onCaller,
              child: _Initial(t.handle, size: 40, ring: t.side.color),
            ),
          ),
          const SizedBox(width: VistaSpace.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: onCaller,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: t.handle),
                              TextSpan(
                                text: '  $record right',
                                style: TextStyle(
                                  color: good
                                      ? VistaColors.long
                                      : VistaColors.textMuted,
                                ),
                              ),
                              TextSpan(text: ' · ${t.age}', style: muted),
                            ],
                          ),
                          style: VistaType.body.copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: VistaSpace.sm),
                    FollowChip(handle: t.handle),
                  ],
                ),
                if (market.isNotEmpty)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onMarket,
                    child: Padding(
                      padding: const EdgeInsets.only(top: VistaSpace.xs),
                      child: ValueListenableBuilder(
                        valueListenable: MarketPrices.of(t.handle),
                        builder: (context, price, _) {
                          final ch = market.first.changePct;
                          return Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${MarketsMock.traderCards[t.handle]?.symbol ?? t.handle} ',
                                  style: muted,
                                ),
                                TextSpan(
                                  text:
                                      '${MarketPrices.format(price, compact: true)} ',
                                ),
                                TextSpan(
                                  text:
                                      '${ch >= 0 ? '▲' : '▼'}${ch.abs().toStringAsFixed(1)}% ›',
                                  style: TextStyle(color: vistaChangeColor(ch)),
                                ),
                              ],
                            ),
                            style: VistaType.figures(VistaType.body),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: VistaSpace.sm),
                Wrap(
                  spacing: VistaSpace.sm,
                  runSpacing: VistaSpace.xs,
                  children: [
                    _Badge(
                      '${t.side.label.toUpperCase()} ${t.ticker} ${c.leverage}x',
                      t.side.color,
                    ),
                    if (t.battle != null)
                      GestureDetector(
                        onTap: onDebate,
                        child: _Badge('${t.battle!} ›', VistaColors.textMuted),
                      ),
                  ],
                ),
                const SizedBox(height: VistaSpace.sm),
                Text(
                  t.body,
                  style: VistaType.subheadMuted.copyWith(
                    fontWeight: FontWeight.w400,
                    color: VistaColors.textPrimary,
                    height: 21 / 15,
                  ),
                ),
                const SizedBox(height: VistaSpace.sm),
                BackedPositionCard(
                  post: c,
                  ticker: t.ticker,
                  onTap: onPosition,
                ),
                SizedBox(
                  height: VistaSize.tapTarget,
                  child: Row(
                    children: [
                      // Gives way (shrinks a little) before the Join pill.
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              children: [
                                TakeAgreeButton(take: t),
                                if (thread != null) ...[
                                  const SizedBox(width: VistaSpace.md),
                                  _Count(
                                    Icons.chat_bubble_outline_rounded,
                                    thread.replies,
                                  ),
                                  const SizedBox(width: VistaSpace.lg),
                                  _Count(
                                    Icons.swap_horiz_rounded,
                                    thread.counters,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: VistaSpace.sm),
                      VistaJoinPill(side: t.side, onTap: onJoin),
                    ],
                  ),
                ),
                if (thread?.top case final r?) _TopReply(reply: r),
                if (thread != null && thread.replies > 0)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onReplies,
                    child: SizedBox(
                      height: 36,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'View all ${thread.replies} replies ›',
                          style: VistaType.body.copyWith(
                            color: VistaColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color == VistaColors.textMuted
          ? VistaColors.surfaceRaised
          : color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(VistaRadius.sm),
    ),
    child: Text(label, style: VistaType.labelStrong.copyWith(color: color)),
  );
}

class _Count extends StatelessWidget {
  const _Count(this.icon, this.count);

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: VistaColors.textMuted),
      const SizedBox(width: 5),
      Text(
        '$count',
        style: VistaType.bodyMedium.copyWith(color: VistaColors.textMuted),
      ),
    ],
  );
}

/// The top reply under a call: who, their record and badge, what they said.
class _TopReply extends StatelessWidget {
  const _TopReply({required this.reply});

  final Reply reply;

  @override
  Widget build(BuildContext context) {
    final r = reply;
    final counter = r.counter;
    final side = counter == null
        ? null
        : (counter.startsWith('LONG') ? VistaColors.long : VistaColors.short);
    final record = CallsStore.recordOf(r.handle)?.split(' ').first;
    return Padding(
      padding: const EdgeInsets.only(top: VistaSpace.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Initial(r.handle, size: 26, ring: side ?? VistaColors.surfaceRaised),
          const SizedBox(width: VistaSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: r.handle),
                            if (record != null)
                              TextSpan(
                                text: '  $record right',
                                style: const TextStyle(color: VistaColors.long),
                              ),
                          ],
                        ),
                        style: VistaType.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: VistaSpace.sm),
                    _Badge(
                      counter == null ? 'No position' : 'COUNTER · $counter',
                      side ?? VistaColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: VistaSpace.xs),
                Text(
                  r.body,
                  style: VistaType.rowRegular.copyWith(
                    color: VistaColors.textPrimary,
                    height: 19 / 14,
                  ),
                ),
              ],
            ),
          ),
        ],
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
