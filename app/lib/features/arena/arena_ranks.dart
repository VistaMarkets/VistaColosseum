import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../calls/calls_store.dart';
import '../people/follow_state.dart';
import '../portfolio/portfolio_mock.dart';
import 'game_mock.dart';

/// Arena's Ranks tab: the leaderboard, this week (by return on settled
/// calls) or this season (by points). The top three on a podium, then the
/// table; your own row stays pinned at the bottom.
class ArenaRanks extends StatefulWidget {
  const ArenaRanks({
    super.key,
    required this.bottomPadding,
    required this.onTrader,
  });

  final double bottomPadding;
  final ValueChanged<String> onTrader;

  @override
  State<ArenaRanks> createState() => _ArenaRanksState();
}

class _ArenaRanksState extends State<ArenaRanks> {
  bool _season = false;

  @override
  Widget build(BuildContext context) {
    final ranked = GameMock.ranked(season: _season);
    final me = PortfolioMock.handle;
    final myPlace = GameMock.placeOf(me, season: _season);
    final mine = GameMock.of(me);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: VistaSpace.gutter),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VistaSpace.gutter,
                  VistaSpace.md,
                  VistaSpace.gutter,
                  0,
                ),
                child: Row(
                  children: [
                    VistaFilterChip(
                      label: 'This week',
                      accent: true,
                      selected: !_season,
                      onPressed: () => setState(() => _season = false),
                    ),
                    const SizedBox(width: VistaSpace.md),
                    VistaFilterChip(
                      label: GameMock.season,
                      accent: true,
                      selected: _season,
                      onPressed: () => setState(() => _season = true),
                    ),
                    const Spacer(),
                    Text(
                      'Ends in ${GameMock.seasonEndsIn}',
                      style: VistaType.caption.copyWith(
                        color: VistaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _Podium(
                top: ranked.take(3).toList(),
                season: _season,
                onTrader: widget.onTrader,
              ),
              for (final (i, s) in ranked.indexed.skip(3))
                _RankRow(
                  place: i + 1,
                  standing: s,
                  season: _season,
                  mine: s.handle == me,
                  onTap: () => widget.onTrader(s.handle),
                ),
            ],
          ),
        ),
        // Pinned when you're further down than the first screen shows.
        if (mine != null && myPlace > 7)
          Container(
            padding: EdgeInsets.only(bottom: widget.bottomPadding),
            decoration: const BoxDecoration(
              color: VistaColors.background,
              border: Border(top: BorderSide(color: VistaColors.hairline)),
            ),
            child: _RankRow(
              place: myPlace,
              standing: mine,
              season: _season,
              mine: true,
              pinned: true,
              onTap: () => widget.onTrader(me),
            ),
          ),
      ],
    );
  }
}

String _score(Standing s, bool season) => season
    ? '${s.points} pts'
    : '${s.weekPct >= 0 ? '+' : '−'}${s.weekPct.abs().toStringAsFixed(1)}%';

Color _scoreColor(Standing s, bool season) => season
    ? VistaColors.textPrimary
    : (s.weekPct >= 0 ? VistaColors.long : VistaColors.short);

class _Avatar extends StatelessWidget {
  const _Avatar(this.handle, {required this.size, required this.ring});

  final String handle;
  final double size;
  final Color ring;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: VistaColors.surfaceRaised,
      shape: BoxShape.circle,
      border: Border.all(color: ring, width: size > 50 ? 3 : 2),
    ),
    child: Text(
      handle[0].toUpperCase(),
      style: VistaType.subhead.copyWith(fontSize: size * 0.38, height: 1),
    ),
  );
}

/// The top three, first in the middle and raised.
class _Podium extends StatelessWidget {
  const _Podium({
    required this.top,
    required this.season,
    required this.onTrader,
  });

  final List<Standing> top;
  final bool season;
  final ValueChanged<String> onTrader;

  static const _medals = [
    Color(0xFFF2B35A),
    Color(0xFFC9CED6),
    Color(0xFFC98A5A),
  ];

  @override
  Widget build(BuildContext context) {
    if (top.length < 3) return const SizedBox.shrink();
    Widget spot(int i, double size, double lift) {
      final s = top[i];
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTrader(s.handle),
          child: Padding(
            padding: EdgeInsets.only(top: lift),
            child: Column(
              children: [
                Text(
                  '#${i + 1}',
                  style: VistaType.labelStrong.copyWith(color: _medals[i]),
                ),
                const SizedBox(height: VistaSpace.xs),
                _Avatar(s.handle, size: size, ring: _medals[i]),
                const SizedBox(height: VistaSpace.sm),
                Text(
                  s.handle,
                  style: VistaType.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  s.rank,
                  style: VistaType.caption.copyWith(color: s.tier.color),
                ),
                Text(
                  _score(s, season),
                  style: VistaType.figures(VistaType.subhead)
                      .copyWith(color: _scoreColor(s, season)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VistaSpace.gutter,
        VistaSpace.lg,
        VistaSpace.gutter,
        VistaSpace.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [spot(1, 52, 24), spot(0, 68, 0), spot(2, 52, 32)],
      ),
    );
  }
}

/// One place on the table: rank, face, handle and tier, record and
/// streak, the score, Follow.
class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.place,
    required this.standing,
    required this.season,
    required this.onTap,
    this.mine = false,
    this.pinned = false,
  });

  final int place;
  final Standing standing;
  final bool season;
  final bool mine;
  final bool pinned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = standing;
    final record = CallsStore.recordOf(s.handle);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VistaSpace.gutter + VistaSpace.xs,
          vertical: VistaSpace.lg,
        ),
        decoration: BoxDecoration(
          color: mine && !pinned ? VistaColors.accentTint : null,
          border: pinned
              ? null
              : const Border(bottom: BorderSide(color: VistaColors.hairline)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '#$place',
                style: VistaType.figures(VistaType.body)
                    .copyWith(color: VistaColors.textMuted),
              ),
            ),
            _Avatar(s.handle, size: 36, ring: s.tier.color),
            const SizedBox(width: VistaSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mine ? 'You · ${s.handle}' : s.handle,
                    style: VistaType.subhead,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        s.rank,
                        style: VistaType.caption.copyWith(color: s.tier.color),
                      ),
                      if (record != null)
                        Flexible(
                          child: Text(
                            ' · $record',
                            style: VistaType.caption.copyWith(
                              color: VistaColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (s.streak > 1) ...[
                        const SizedBox(width: VistaSpace.xs),
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 13,
                          color: VistaColors.favorite,
                        ),
                        Text(
                          '${s.streak}',
                          style: VistaType.caption.copyWith(
                            color: VistaColors.favorite,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              _score(s, season),
              style: VistaType.figures(VistaType.subhead)
                  .copyWith(color: _scoreColor(s, season)),
            ),
            if (!mine) ...[
              const SizedBox(width: VistaSpace.md),
              FollowChip(handle: s.handle),
            ],
          ],
        ),
      ),
    );
  }
}
