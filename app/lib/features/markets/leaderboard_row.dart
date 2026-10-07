import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../calls/calls_store.dart';
import 'markets_mock.dart';

/// One trader on the Explore Leaderboard: a flush row, not a chart card, so
/// it reads as a ranking rather than a market list. Place (the top three in
/// medal colours, their avatar ringed to match), avatar, ticker over handle,
/// and on the right the figure the selected chip ranks by. Your own row is
/// lifted. Mock figures.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.market,
    required this.metric,
    this.isYou = false,
    this.onPressed,
  });

  final int rank;
  final MarketItem market;

  /// The chip the board is ranked by (`MarketsMock.traderSorts`).
  final String metric;
  final bool isYou;
  final VoidCallback? onPressed;

  String get name => market.name;

  static const medals = [
    Color(0xFFE8C14A), // gold
    Color(0xFFC3C8D0), // silver
    Color(0xFFCB8E5C), // bronze
  ];

  static String _k(double v) =>
      '${v < 0 ? '−' : '+'}\$${(v.abs() / 1000).toStringAsFixed(1)}K';

  @override
  Widget build(BuildContext context) {
    final m = market;
    final card = MarketsMock.traderCards[m.id];
    final medal = rank <= 3 ? medals[rank - 1] : null;
    final pnl = card?.weekPnl ?? 0;
    final (value, caption, color) = switch (metric) {
      'Top P&L' => (_k(pnl), 'this week', vistaChangeColor(pnl)),
      'Up and coming' => (
        '+${card?.newHolders ?? 0}',
        'new holders',
        VistaColors.long,
      ),
      'Market cap' => (m.third, 'market cap', VistaColors.textPrimary),
      'Change' => (
        '${m.changePct >= 0 ? '▲' : '▼'}'
            '${m.changePct.abs().toStringAsFixed(1)}%',
        '7 days',
        vistaChangeColor(m.changePct),
      ),
      _ => (
        (CallsStore.recordOf(m.id) ?? '—').replaceFirst(' right', ''),
        'right',
        VistaColors.textPrimary,
      ),
    };
    final subtitle = [
      m.name,
      if (isYou) 'You',
      if (metric == 'Up and coming') '${card?.days ?? 0}d old',
    ].join(' · ');

    return Semantics(
      button: true,
      label: '#$rank ${card?.symbol ?? m.name}, $subtitle, $value $caption',
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.99,
        onTap: onPressed,
        child: Container(
          color: isYou ? VistaColors.surface : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: VistaSpace.gutter,
            vertical: VistaSpace.xl,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '$rank',
                  style: VistaType.figures(VistaType.headline).copyWith(
                    fontWeight: FontWeight.w700,
                    color: medal ?? VistaColors.textMuted,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(
                    card?.avatar ?? VistaColors.surfaceRaised.toARGB32(),
                  ),
                  shape: BoxShape.circle,
                  border: medal == null
                      ? null
                      : Border.all(color: medal, width: 2),
                ),
                child: Text(m.name[0].toUpperCase(), style: VistaType.subhead),
              ),
              const SizedBox(width: VistaSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card?.symbol ?? m.name,
                      style: VistaType.subhead.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: VistaType.chip.copyWith(
                        color: VistaColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: VistaSpace.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: VistaType.figures(VistaType.headline)
                        .copyWith(color: color),
                  ),
                  Text(
                    caption,
                    style: VistaType.meta.copyWith(
                      color: VistaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
