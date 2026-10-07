import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../calls/calls_store.dart';
import '../home/home_feed.dart';
import '../live/market_prices.dart';
import '../markets/markets_mock.dart';
import '../portfolio/portfolio_mock.dart';
import '../watchlist/watchlist_state.dart';
import 'arena_mock.dart';
import 'game_mock.dart';

/// "$4.2K", "$880".
String compactUsd(double v) => v >= 1000
    ? '\$${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}K'
    : '\$${v.round()}';

/// The Arena tab's hub (Figma 559:205, ARENA-GAME-01): your season (rank,
/// streak, XP, today's quests, the top three → Ranks), the hottest battle
/// face to face, the next two battles, markets heating up with who just
/// went in, the hottest threads, then your markets. Calm last; stakes
/// first.
class ArenaHub extends StatelessWidget {
  const ArenaHub({
    super.key,
    required this.bottomPadding,
    required this.onRanks,
    required this.onRoom,
    required this.onThreads,
    required this.onDebate,
    required this.onAllDebates,
    required this.onNewCall,
    required this.onJoin,
    required this.takeItem,
  });

  final double bottomPadding;
  final VoidCallback onRanks;

  /// Opens Threads on a market's room (a ticker, or "@handle").
  final ValueChanged<String> onRoom;
  final VoidCallback onThreads;
  final ValueChanged<LiveBattle> onDebate;
  final VoidCallback onAllDebates;

  /// Start your own: the + flow.
  final VoidCallback onNewCall;
  final void Function(String ticker, TradeSide side) onJoin;

  /// A call row as Threads shows it, with Challenge.
  final Widget Function(Take take) takeItem;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: CallsStore.all,
      builder: (context, calls, _) => ValueListenableBuilder(
        valueListenable: BattlesStore.all,
        builder: (context, battles, _) {
          final ranked = [...battles]
            ..sort((a, b) => b.takes.compareTo(a.takes));
          final hero = ranked.isEmpty ? null : ranked.first;
          final rest = ranked.skip(1).toList();
          final closest = rest.isEmpty
              ? null
              : rest.reduce(
                  (a, b) =>
                      (a.longShare - 0.5).abs() <= (b.longShare - 0.5).abs()
                      ? a
                      : b,
                );
          final soonest = [
            for (final b in rest)
              if (!identical(b, closest)) b,
          ];
          soonest.sort((a, b) => a.minutesLeft.compareTo(b.minutesLeft));
          return ListView(
            padding: EdgeInsets.only(bottom: bottomPadding),
            children: [
              _SeasonStrip(onRanks: onRanks),
              if (hero != null) ...[
                _Head(
                  'Live battles',
                  trailing: 'See all',
                  onTrailing: onAllDebates,
                ),
                _BattleHero(
                  battle: hero,
                  calls: Debates.callsOn(hero, calls),
                  onOpen: () => onDebate(hero),
                  onBack: (side) => onJoin(hero.ticker, side),
                  onChallenge: onNewCall,
                ),
                if (closest != null)
                  _BattleRow(
                    icon: Icons.local_fire_department_rounded,
                    tag: 'Closest',
                    color: VistaColors.favorite,
                    battle: closest,
                    onTap: () => onDebate(closest),
                  ),
                if (soonest.isNotEmpty)
                  _BattleRow(
                    icon: Icons.timer_outlined,
                    tag: 'Ending soon',
                    color: VistaColors.short,
                    battle: soonest.first,
                    onTap: () => onDebate(soonest.first),
                  ),
              ],
              _Head('Heating up'),
              for (final h in _heating(calls).take(2))
                _HeatingRow(
                  heat: h,
                  onTap: () => onRoom(h.room),
                  onJoin: () => onJoin(h.latest.ticker, h.latest.side),
                ),
              _Head(
                'Hot threads',
                trailing: 'Threads ›',
                onTrailing: onThreads,
              ),
              for (final t in HomeFeed.forYou(calls).take(2)) takeItem(t),
              _Head('Your markets'),
              ValueListenableBuilder(
                valueListenable: WatchlistState.assets,
                builder: (context, favs, _) => Column(
                  children: [
                    for (final m in [
                      ...MarketsMock.assets.where((m) => favs.contains(m.id)),
                      ...MarketsMock.traders.where(
                        (m) => WatchlistState.isTrader(m.id),
                      ),
                    ].take(3))
                      _MarketRow(
                        market: m,
                        calls: calls,
                        onTap: () => onRoom(
                          MarketsMock.traders.contains(m) ? '@${m.id}' : m.id,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Markets by how many calls they have, busiest first, with the newest
  /// backed call on each.
  static List<_Heat> _heating(List<Take> calls) {
    final byTicker = <String, List<Take>>{};
    for (final t in calls) {
      if (MarketsMock.assets.any((m) => m.id == t.ticker)) {
        (byTicker[t.ticker] ??= []).add(t);
      }
    }
    final out = <_Heat>[];
    for (final MapEntry(key: ticker, value: list) in byTicker.entries) {
      final backed = list.where((t) => t.call != null).toList()
        ..sort(
          (a, b) =>
              CallsStore.minutesAgo(a.age)
                  .compareTo(CallsStore.minutesAgo(b.age)),
        );
      if (backed.isEmpty) continue;
      final usd = backed.fold<double>(0, (s, t) => s + t.call!.size);
      out.add(_Heat(ticker, list.length, usd, backed.first));
    }
    out.sort((a, b) => b.count.compareTo(a.count));
    return out;
  }
}

class _Heat {
  const _Heat(this.room, this.count, this.backedUsd, this.latest);

  final String room;
  final int count;
  final double backedUsd;
  final Take latest;
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
        VistaSpace.section,
        VistaSpace.gutter + VistaSpace.xs,
        VistaSpace.xs,
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: VistaType.title)),
          if (trailing != null)
            GestureDetector(
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
        ],
      ),
    );
  }
}

/// Initial in a circle, ringed in a colour (tier or side).
class _Face extends StatelessWidget {
  const _Face(this.handle, {this.size = 36, this.ring, this.ringWidth = 2});

  final String handle;
  final double size;
  final Color? ring;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: VistaColors.surfaceRaised,
        shape: BoxShape.circle,
        border: ring == null
            ? null
            : Border.all(color: ring!, width: ringWidth),
      ),
      child: Text(
        handle.isEmpty ? '' : handle[0].toUpperCase(),
        style: VistaType.subhead.copyWith(fontSize: size * 0.4, height: 1),
      ),
    );
  }
}

/// Overlapping faces.
class _Faces extends StatelessWidget {
  const _Faces(this.handles);

  final List<String> handles;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22.0 + (handles.length - 1) * 16,
      height: 22,
      child: Stack(
        children: [
          for (final (i, h) in handles.indexed)
            Positioned(
              left: i * 16.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: VistaColors.background, width: 2),
                ),
                child: _Face(h, size: 18, ring: GameMock.tierColor(h)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color, {this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(VistaRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 2),
          ],
          Text(label, style: VistaType.labelStrong.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Your season: rank and streak, place, XP to the next division, today's
/// quests, and the top three leading to Ranks.
class _SeasonStrip extends StatelessWidget {
  const _SeasonStrip({required this.onRanks});

  final VoidCallback onRanks;

  @override
  Widget build(BuildContext context) {
    final me = GameMock.of(PortfolioMock.handle)!;
    final place = GameMock.placeOf(me.handle, season: true);
    final top = GameMock.ranked(season: true).take(3).map((s) => s.handle);
    final muted = VistaType.caption.copyWith(color: VistaColors.textMuted);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VistaSpace.gutter,
        VistaSpace.md,
        VistaSpace.gutter,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(VistaSpace.xl),
        decoration: BoxDecoration(
          color: VistaColors.surface,
          borderRadius: BorderRadius.circular(VistaRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: me.tier.color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: me.tier.color, width: 2.5),
                  ),
                  child: Text(
                    '${me.tier.label[0]}${me.division}',
                    style: VistaType.labelStrong.copyWith(color: me.tier.color),
                  ),
                ),
                const SizedBox(width: VistaSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            me.rank,
                            style: VistaType.subhead.copyWith(
                              color: me.tier.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: VistaSpace.md),
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: VistaColors.favorite,
                          ),
                          Text('${me.streak} streak', style: VistaType.body),
                        ],
                      ),
                      Text(
                        '#$place this season · ends in ${GameMock.seasonEndsIn}',
                        style: muted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Ranks',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onRanks,
                    child: SizedBox(
                      height: VistaSize.tapTarget,
                      child: Row(
                        children: [
                          _Faces(top.toList()),
                          const SizedBox(width: VistaSpace.sm),
                          Text(
                            'Ranks ›',
                            style: VistaType.body.copyWith(
                              color: VistaColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VistaSpace.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: GameMock.xp / GameMock.xpToNext,
                minHeight: 6,
                backgroundColor: VistaColors.surfaceRaised,
                color: me.tier.color,
              ),
            ),
            const SizedBox(height: VistaSpace.xs),
            Text(
              '${GameMock.xp} / ${GameMock.xpToNext} XP to ${GameMock.nextRank}',
              style: muted,
            ),
            const SizedBox(height: VistaSpace.md),
            Wrap(
              spacing: VistaSpace.sm,
              runSpacing: VistaSpace.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Today', style: muted),
                for (final q in GameMock.quests)
                  _Chip(
                    q.done ? q.label : '${q.label} +${q.xp}',
                    q.done ? VistaColors.long : VistaColors.textMuted,
                    icon: q.done ? Icons.check_rounded : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The hottest battle, face to face: the biggest backed call on each side,
/// money on each side, back a side, or start your own.
class _BattleHero extends StatelessWidget {
  const _BattleHero({
    required this.battle,
    required this.calls,
    required this.onOpen,
    required this.onBack,
    required this.onChallenge,
  });

  final LiveBattle battle;
  final List<Take> calls;
  final VoidCallback onOpen;
  final ValueChanged<TradeSide> onBack;
  final VoidCallback onChallenge;

  @override
  Widget build(BuildContext context) {
    final b = battle;
    List<Take> side(TradeSide s) =>
        calls.where((t) => t.call != null && t.side == s).toList()
          ..sort((x, y) => y.call!.size.compareTo(x.call!.size));
    final longs = side(TradeSide.long), shorts = side(TradeSide.short);
    double sum(List<Take> l) => l.fold(0, (s, t) => s + t.call!.size);
    final longUsd = sum(longs), shortUsd = sum(shorts);
    final muted = VistaType.caption.copyWith(color: VistaColors.textMuted);

    Widget face(Take? t, TradeSide s) {
      final color = s == TradeSide.long ? VistaColors.long : VistaColors.short;
      if (t == null) {
        return Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Icon(Icons.add_rounded, color: color),
            ),
            const SizedBox(height: VistaSpace.xs),
            Text('Open seat', style: VistaType.body),
            Text(s.label.toUpperCase(), style: muted.copyWith(color: color)),
          ],
        );
      }
      final g = GameMock.of(t.handle);
      return Column(
        children: [
          _Face(t.handle, size: 56, ring: g?.tier.color ?? color, ringWidth: 3),
          const SizedBox(height: VistaSpace.xs),
          Text(
            t.handle,
            style: VistaType.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${g?.rank ?? 'Unranked'} · ${t.accuracy.split(' ').first}',
            style: muted.copyWith(color: g?.tier.color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: VistaSpace.xs),
          _Chip(s.label.toUpperCase(), color),
        ],
      );
    }

    final long = longs.isEmpty ? null : longs.first;
    final short = shorts.isEmpty ? null : shorts.first;
    String name(Take? t, String fallback) => t?.handle ?? fallback;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
      child: Semantics(
        button: true,
        label: 'Battle: ${b.question}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onOpen,
          child: Container(
            padding: const EdgeInsets.all(VistaSpace.gutter),
            decoration: BoxDecoration(
              color: VistaColors.surface,
              borderRadius: BorderRadius.circular(VistaRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: VistaColors.short,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: VistaSpace.sm),
                    Text(
                      'LIVE · ${b.ticker}',
                      style: VistaType.labelStrong.copyWith(
                        color: VistaColors.short,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.timer_outlined,
                      size: 15,
                      color: VistaColors.textPrimary,
                    ),
                    const SizedBox(width: VistaSpace.xs),
                    Text(b.timeLeft, style: VistaType.body),
                  ],
                ),
                const SizedBox(height: VistaSpace.md),
                Text(b.question, style: VistaType.title),
                const SizedBox(height: VistaSpace.lg),
                Row(
                  children: [
                    Expanded(child: face(long, TradeSide.long)),
                    Text(
                      'VS',
                      style: VistaType.title.copyWith(
                        color: VistaColors.textMuted,
                      ),
                    ),
                    Expanded(child: face(short, TradeSide.short)),
                  ],
                ),
                const SizedBox(height: VistaSpace.lg),
                Row(
                  children: [
                    Text(
                      '${compactUsd(longUsd)} long',
                      style: VistaType.figures(VistaType.subhead)
                          .copyWith(color: VistaColors.long),
                    ),
                    Expanded(
                      child: Text(
                        '${compactUsd(longUsd + shortUsd)} on the line',
                        textAlign: TextAlign.center,
                        style: muted,
                      ),
                    ),
                    Text(
                      '${compactUsd(shortUsd)} short',
                      style: VistaType.figures(VistaType.subhead)
                          .copyWith(color: VistaColors.short),
                    ),
                  ],
                ),
                const SizedBox(height: VistaSpace.lg),
                Row(
                  children: [
                    Expanded(
                      child: VistaPillButton(
                        label: 'Back ${name(long, 'long')}',
                        variant: VistaPillVariant.long,
                        onPressed: () => onBack(TradeSide.long),
                      ),
                    ),
                    const SizedBox(width: VistaSpace.md),
                    Expanded(
                      child: VistaPillButton(
                        label: 'Back ${name(short, 'short')}',
                        variant: VistaPillVariant.short,
                        onPressed: () => onBack(TradeSide.short),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onChallenge,
                  child: SizedBox(
                    height: VistaSize.tapTarget,
                    child: Center(
                      child: Text(
                        'Challenge someone ›',
                        style: VistaType.subhead.copyWith(
                          color: VistaColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A battle as one line: why it's here, the question, the split.
class _BattleRow extends StatelessWidget {
  const _BattleRow({
    required this.icon,
    required this.tag,
    required this.color,
    required this.battle,
    required this.onTap,
  });

  final IconData icon;
  final String tag;
  final Color color;
  final LiveBattle battle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = battle;
    final long = (b.longShare * 100).round();
    return Semantics(
      button: true,
      label: '$tag: ${b.question}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: VistaSize.tapTarget + 8),
          padding: const EdgeInsets.symmetric(
            horizontal: VistaSpace.gutter + VistaSpace.xs,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: VistaColors.hairline)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: VistaSpace.xs),
              Text(tag, style: VistaType.body.copyWith(color: color)),
              const SizedBox(width: VistaSpace.md),
              Expanded(
                child: Text(
                  '${b.ticker} · ${b.label}',
                  style: VistaType.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: VistaSpace.md),
              Text(
                '$long / ${100 - long} · ${b.timeLeft}',
                style: VistaType.caption.copyWith(color: VistaColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A market heating up: its calls and money, and who just went in, with
/// Join on their side.
class _HeatingRow extends StatelessWidget {
  const _HeatingRow({
    required this.heat,
    required this.onTap,
    required this.onJoin,
  });

  final _Heat heat;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final h = heat;
    final t = h.latest;
    final c = t.call!;
    final m = MarketsMock.assets.firstWhere((m) => m.id == h.room);
    final flames = math.min(3, math.max(1, h.count ~/ 3));
    final sideColor = t.side.color;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          VistaSpace.gutter + VistaSpace.xs,
          VistaSpace.xl,
          VistaSpace.gutter + VistaSpace.xs,
          VistaSpace.md,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: VistaColors.hairline)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                VistaIcon(m.rowIcon, size: 36),
                const SizedBox(width: VistaSpace.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(m.name, style: VistaType.headline),
                          const SizedBox(width: VistaSpace.sm),
                          for (var i = 0; i < flames; i++)
                            const Icon(
                              Icons.local_fire_department_rounded,
                              size: 16,
                              color: VistaColors.favorite,
                            ),
                        ],
                      ),
                      Text(
                        '${h.count} calls · ${compactUsd(h.backedUsd)} backed',
                        style: VistaType.caption.copyWith(
                          color: VistaColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: MarketPrices.of(m.id),
                  builder: (context, price, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        MarketPrices.format(price, compact: true),
                        style: VistaType.figures(VistaType.subhead),
                      ),
                      Text(
                        vistaChangeLabel(m.changePct),
                        style: VistaType.figures(VistaType.label)
                            .copyWith(color: vistaChangeColor(m.changePct)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: VistaSpace.sm),
            Row(
              children: [
                const SizedBox(width: 48),
                _Faces([t.handle]),
                const SizedBox(width: VistaSpace.sm),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: t.handle,
                          style: const TextStyle(
                            color: VistaColors.textPrimary,
                          ),
                        ),
                        const TextSpan(text: ' went '),
                        TextSpan(
                          text:
                              '${compactUsd(c.size)} '
                              '${t.side.label.toLowerCase()} ${c.leverage}x',
                          style: TextStyle(color: sideColor),
                        ),
                        TextSpan(text: ' · ${t.age}'),
                      ],
                    ),
                    style: VistaType.caption.copyWith(
                      color: VistaColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: VistaSpace.sm),
                VistaJoinPill(side: t.side, onTap: onJoin),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One of your markets: the callers split as a ring around its icon, its
/// calls, live price. Opens its room in Threads.
class _MarketRow extends StatelessWidget {
  const _MarketRow({
    required this.market,
    required this.calls,
    required this.onTap,
  });

  final MarketItem market;
  final List<Take> calls;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = market;
    final trader = MarketsMock.traders.contains(m);
    final on = calls
        .where((t) => trader ? t.handle == m.id : t.ticker == m.id)
        .toList();
    final backed = on.where((t) => t.call != null).toList();
    final longShare = backed.isEmpty
        ? 0.5
        : backed.where((t) => t.side == TradeSide.long).length / backed.length;
    final title = trader
        ? MarketsMock.traderCards[m.id]?.symbol ?? m.name
        : m.name;
    return Semantics(
      button: true,
      label: '$title room',
      child: GestureDetector(
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
              SizedBox(
                width: 44,
                height: 44,
                child: CustomPaint(
                  painter: _SplitRing(longShare),
                  child: Center(
                    child: trader
                        ? _Face(m.id, size: 34)
                        : VistaIcon(m.rowIcon, size: 34),
                  ),
                ),
              ),
              const SizedBox(width: VistaSpace.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: VistaType.headline),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${(longShare * 100).round()}% long',
                            style: TextStyle(
                              color: longShare >= 0.5
                                  ? VistaColors.long
                                  : VistaColors.short,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' · ${on.length} call${on.length == 1 ? '' : 's'}',
                          ),
                        ],
                      ),
                      style: VistaType.caption.copyWith(
                        color: VistaColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder(
                valueListenable: MarketPrices.of(m.id),
                builder: (context, price, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      MarketPrices.format(price, compact: true),
                      style: VistaType.figures(VistaType.subhead),
                    ),
                    Text(
                      vistaChangeLabel(m.changePct),
                      style: VistaType.figures(VistaType.label)
                          .copyWith(color: vistaChangeColor(m.changePct)),
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

/// A thin ring: green for the long share of callers, red for the rest.
class _SplitRing extends CustomPainter {
  const _SplitRing(this.longShare);

  final double longShare;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.0;
    const gap = 0.12;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    Paint p(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final long = 2 * math.pi * longShare.clamp(0.0, 1.0);
    if (long > gap) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + gap / 2,
        long - gap,
        false,
        p(VistaColors.long),
      );
    }
    if (2 * math.pi - long > gap) {
      canvas.drawArc(
        rect,
        -math.pi / 2 + long + gap / 2,
        2 * math.pi - long - gap,
        false,
        p(VistaColors.short),
      );
    }
  }

  @override
  bool shouldRepaint(_SplitRing old) => old.longShare != longShare;
}
