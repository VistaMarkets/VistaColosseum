import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../calls/calls_store.dart';
import 'markets_mock.dart';

/// The Leaderboard's time windows; 7d is the default.
const leaderboardWindows = ['24h', '7d', '30d', 'All'];

/// One trader on the Explore Leaderboard: a flush row, not a chart card, so
/// it reads as a ranking rather than a market list. Place (the top three in
/// medal colours, their avatar ringed to match), avatar, ticker over handle,
/// and on the right the figure the selected chip ranks by over [window].
/// Your own row is lifted. Mock figures.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.rank,
    required this.market,
    required this.metric,
    this.window = 1,
    this.isYou = false,
    this.onPressed,
  });

  final int rank;
  final MarketItem market;

  /// The chip the board is ranked by (`MarketsMock.traderSorts`).
  final String metric;

  /// Index into [leaderboardWindows].
  final int window;
  final bool isYou;
  final VoidCallback? onPressed;

  String get name => market.name;

  static const medals = [
    Color(0xFFE8C14A), // gold
    Color(0xFFC3C8D0), // silver
    Color(0xFFCB8E5C), // bronze
  ];

  /// A steady 0.6–1.4 per trader and window, so other windows reorder the
  /// board without random churn. Mock.
  static double _jitter(String id, int window) {
    var h = 0;
    for (final c in '$window/$id'.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    h = ((h ^ (h >> 13)) * 0x5bd1e995) & 0x7fffffff;
    h ^= h >> 15;
    return 0.6 + (h % 1000) / 1000 * 0.8;
  }

  /// What [metric] is for [m] over [window]: the figure shown and ranked
  /// by. The mock's own figures are the 7d ones (and the all-time record
  /// for Most right); other windows are derived. Null when unknown.
  static double? value(MarketItem m, String metric, int window) {
    final c = MarketsMock.traderCards[m.id];
    final j = _jitter(m.id, window);
    switch (metric) {
      case 'Most right':
        final pct = double.tryParse(
          (CallsStore.recordOf(m.id) ?? '').split('%').first,
        );
        if (pct == null || window == 3) return pct;
        return (pct + (j - 1) * 20).roundToDouble().clamp(35, 95);
      case 'Top P&L':
        if (c == null) return null;
        const scale = [1 / 6, 1.0, 3.5, 12.0];
        return c.weekPnl * scale[window] * (window == 1 ? 1 : j);
      case 'Up and coming':
        if (c == null) return null;
        return switch (window) {
          0 => (c.newHolders / 7 * j).roundToDouble(),
          1 => c.newHolders.toDouble(),
          // Every market here is under 30 days old.
          _ => c.holders.toDouble(),
        };
      case 'Change':
        const scale = [0.25, 1.0, 2.5, 6.0];
        return m.changePct * scale[window] * (window == 1 ? 1 : j);
      default:
        return m.sortValues[metric];
    }
  }

  static String _k(double v) =>
      '${v < 0 ? '−' : '+'}\$${(v.abs() / 1000).toStringAsFixed(1)}K';

  @override
  Widget build(BuildContext context) {
    final m = market;
    final card = MarketsMock.traderCards[m.id];
    final medal = rank <= 3 ? medals[rank - 1] : null;
    final v = value(m, metric, window) ?? 0;
    final period = const ['today', 'this week', 'this month', 'all time'];
    final (text, caption, color) = switch (metric) {
      'Top P&L' => (_k(v), period[window], vistaChangeColor(v)),
      'Up and coming' => (
        '+${v.toInt()}',
        window == 3 ? 'holders' : 'new holders',
        VistaColors.long,
      ),
      'Market cap' => (m.third, 'market cap', VistaColors.textPrimary),
      'Change' => (
        '${v >= 0 ? '▲' : '▼'}${v.abs().toStringAsFixed(1)}%',
        const ['24 hours', '7 days', '30 days', 'all time'][window],
        vistaChangeColor(v),
      ),
      _ => ('${v.toInt()}%', 'right', VistaColors.textPrimary),
    };
    final subtitle = [
      m.name,
      if (isYou) 'You',
      if (metric == 'Up and coming') '${card?.days ?? 0}d old',
    ].join(' · ');

    return Semantics(
      button: true,
      label: '#$rank ${card?.symbol ?? m.name}, $subtitle, $text $caption',
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
                    text,
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
