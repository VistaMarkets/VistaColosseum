import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../calls/calls_store.dart';
import '../live/market_prices.dart';
import '../portfolio/series_chart.dart';
import 'leaderboard.dart';
import 'markets_mock.dart';

/// A trader market on the Explore Leaderboard, in the same chart card as
/// Assets: its place before the avatar (the top three in medal colours,
/// the avatar ringed to match), ticker over handle, live price with its
/// change over the selected [window], the chart over that window, then the
/// figure the [metric] chip ranks by, market cap and holders. Your own
/// market is outlined. Simulated history.
class LeaderboardCard extends StatelessWidget {
  const LeaderboardCard({
    super.key,
    required this.rank,
    required this.market,
    required this.metric,
    required this.window,
    required this.starred,
    required this.onStar,
    this.isYou = false,
    this.onPressed,
  });

  final int rank;
  final MarketItem market;

  /// The chip the board is ranked by (`MarketsMock.traderSorts`).
  final String metric;

  /// Index into [Leaderboard.windows].
  final int window;
  final bool starred;
  final VoidCallback onStar;
  final bool isYou;
  final VoidCallback? onPressed;

  String get name => market.name;

  static const medals = [
    Color(0xFFE8C14A), // gold
    Color(0xFFC3C8D0), // silver
    Color(0xFFCB8E5C), // bronze
  ];

  @override
  Widget build(BuildContext context) {
    final m = market;
    final card = MarketsMock.traderCards[m.id];
    final medal = rank <= 3 ? medals[rank - 1] : null;
    final v = Leaderboard.value(m, metric, window) ?? 0;
    final record = (CallsStore.recordOf(m.id) ?? '').split(' ').first;
    final holders = card?.holders ?? 0;
    return _MarketChartCard(
      market: m,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '$rank',
              style: VistaType.figures(VistaType.headline).copyWith(
                fontWeight: FontWeight.w700,
                color: medal ?? VistaColors.textMuted,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color(
                card?.avatar ?? VistaColors.surfaceRaised.toARGB32(),
              ),
              shape: BoxShape.circle,
              border: medal == null ? null : Border.all(color: medal, width: 2),
            ),
            child: Text(m.name[0].toUpperCase(), style: VistaType.subhead),
          ),
        ],
      ),
      title: card?.symbol ?? m.name,
      subtitle: [
        m.name,
        if (isYou) 'You',
        if (metric == 'Up and coming') '${card?.days ?? 0}d old',
      ].join(' · '),
      period: Leaderboard.windows[window].toLowerCase(),
      changePct: Leaderboard.value(m, 'Change', window),
      chartKey: 'explore/${m.id}/$window',
      highlight: isYou,
      starred: starred,
      onStar: onStar,
      onPressed: onPressed,
      // The ranked figure first, then cap and holders.
      foot: (strong) => [
        ...switch (metric) {
          'Most right' => [
            TextSpan(text: '${v.toInt()}%', style: strong),
            const TextSpan(text: ' right  ·  '),
          ],
          'Top P&L' => [
            TextSpan(
              text: Leaderboard.money(v),
              style: strong.copyWith(color: vistaChangeColor(v)),
            ),
            TextSpan(text: ' ${Leaderboard.periods[window]}  ·  '),
          ],
          'Up and coming' => [
            TextSpan(
              text: '+${v.toInt()}',
              style: strong.copyWith(color: VistaColors.long),
            ),
            TextSpan(text: window == 3 ? ' holders  ·  ' : ' new holders  ·  '),
          ],
          _ => [
            TextSpan(text: record, style: strong),
            const TextSpan(text: ' right  ·  '),
          ],
        },
        TextSpan(text: m.third, style: strong),
        const TextSpan(text: ' cap'),
        if (metric != 'Up and coming') ...[
          const TextSpan(text: '  ·  '),
          TextSpan(text: '$holders', style: strong),
          const TextSpan(text: ' holders'),
        ],
      ],
    );
  }
}

/// An asset perp in the Assets list, in the same card as trader markets:
/// ticker over the asset's name with its max leverage, live price with its
/// 24h change, favourite star; the day as a short chart; then open interest,
/// funding and how many calls people have made on it. Simulated history.
class AssetMarketCard extends StatelessWidget {
  const AssetMarketCard({
    super.key,
    required this.market,
    required this.starred,
    required this.onStar,
    this.onPressed,
  });

  final MarketItem market;
  final bool starred;
  final VoidCallback onStar;
  final VoidCallback? onPressed;

  String get name => market.name;

  @override
  Widget build(BuildContext context) {
    final m = market;
    return ValueListenableBuilder(
      valueListenable: CallsStore.all,
      builder: (context, all, _) {
        final calls = all.where((t) => t.ticker == m.id).length;
        return _MarketChartCard(
          market: m,
          leading: VistaIcon(m.rowIcon, size: 36),
          title: m.name,
          subtitle: MarketsMock.assetNames[m.id] ?? m.name,
          badge: m.badge,
          period: '24h',
          starred: starred,
          onStar: onStar,
          onPressed: onPressed,
          foot: (strong) => [
            const TextSpan(text: 'OI '),
            TextSpan(text: m.subline.replaceFirst('OI ', ''), style: strong),
            const TextSpan(text: '  ·  Funding '),
            TextSpan(text: m.third, style: strong),
            const TextSpan(text: '  ·  '),
            if (calls == 0)
              const TextSpan(text: 'No calls')
            else ...[
              TextSpan(text: '$calls', style: strong),
              TextSpan(text: ' call${calls == 1 ? '' : 's'}'),
            ],
          ],
        );
      },
    );
  }
}

/// The shared card: header (leading, title over subtitle, price and change,
/// star), a 56pt chart in [SeriesChart]'s style with the live end dot, and
/// one line of figures.
class _MarketChartCard extends StatelessWidget {
  const _MarketChartCard({
    required this.market,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.period,
    required this.starred,
    required this.onStar,
    required this.foot,
    this.badge,
    this.onPressed,
    this.changePct,
    this.chartKey,
    this.highlight = false,
  });

  final MarketItem market;
  final Widget leading;

  /// The change over [period] when it isn't the market's own (a
  /// Leaderboard window); the chart follows it.
  final double? changePct;

  /// Seeds the chart's shape, so each window draws its own history.
  final String? chartKey;

  /// Outlines the card (your own market on the Leaderboard).
  final bool highlight;
  final String title;
  final String subtitle;
  final String? badge;

  /// What the change and chart cover: '7d' or '24h'.
  final String period;
  final bool starred;
  final VoidCallback onStar;
  final List<InlineSpan> Function(TextStyle strong) foot;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final m = market;
    final muted = VistaType.meta.copyWith(color: VistaColors.textMuted);
    final strong = VistaType.figures(VistaType.meta)
        .copyWith(color: VistaColors.textPrimary, fontWeight: FontWeight.w600);

    return ValueListenableBuilder(
      valueListenable: MarketPrices.of(m.id),
      builder: (context, price, _) {
        final change = changePct ?? m.changePct;
        final up = change >= 0;
        return Semantics(
          button: true,
          label:
              '$title, $subtitle, ${MarketPrices.format(price, compact: true)}, '
              '${vistaChangeLabel(change)} over $period',
          child: VistaPressable(
            scale: 0.98,
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.xl,
                VistaSpace.gutter,
                VistaSpace.xl,
              ),
              decoration: BoxDecoration(
                color: VistaColors.surface,
                borderRadius: BorderRadius.circular(VistaRadius.card),
                border: highlight
                    ? Border.all(color: VistaColors.accent, width: 1.5)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 36,
                    child: Row(
                      children: [
                        leading,
                        const SizedBox(width: VistaSpace.lg),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      title,
                                      style: VistaType.subhead.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (badge != null) ...[
                                    const SizedBox(width: VistaSpace.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: VistaColors.surfaceRaised,
                                        borderRadius: BorderRadius.circular(
                                          VistaRadius.sm,
                                        ),
                                      ),
                                      child: Text(
                                        badge!,
                                        style: VistaType.label.copyWith(
                                          color: VistaColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 1),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              MarketPrices.format(price, compact: true),
                              style: VistaType.figures(VistaType.headline),
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '${up ? '▲' : '▼'}'
                                        '${change.abs().toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: vistaChangeColor(change),
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' $period',
                                    style: const TextStyle(
                                      color: VistaColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              style: VistaType.figures(VistaType.label),
                            ),
                          ],
                        ),
                        VistaStarButton(
                          starred: starred,
                          onPressed: onStar,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VistaSpace.md),
                  MarketLineChart(
                    id: m.id,
                    changePct: change,
                    price: price,
                    height: 56,
                    seriesKey: chartKey,
                  ),
                  const SizedBox(height: VistaSpace.md),
                  Text.rich(
                    TextSpan(children: foot(strong)),
                    style: muted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A market's recent history in the app's line style ([SeriesChart]),
/// ending at the live [price] with a ringed dot: the period [changePct]
/// covers (24h for assets, 7 days for traders). Shared by the Explore cards
/// and the Favorites rail, so a market's line looks the same in both.
/// Simulated history; not market data.
class MarketLineChart extends StatelessWidget {
  const MarketLineChart({
    super.key,
    required this.id,
    required this.changePct,
    required this.price,
    required this.height,
    this.seriesKey,
  });

  final String id;

  /// Seeds the line's shape; defaults to the market's own.
  final String? seriesKey;
  final double changePct;
  final double price;
  final double height;

  @override
  Widget build(BuildContext context) {
    final base = MarketPrices.base(id);
    final series = endAt(
      bridgeSeries(
        seriesKey ?? 'explore/$id',
        base / (1 + changePct / 100),
        base,
        n: 42,
      ),
      price,
    );
    final lo = series.reduce(math.min);
    final hi = series.reduce(math.max);
    final pad = (hi - lo) * 0.12;
    final endY = canvasY(series.last, lo - pad, hi + pad) / 403 * height;
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: SeriesChart(focus: series)),
          Positioned(
            right: -6,
            top: endY - 6,
            child: _EndDot(up: price >= series.first),
          ),
        ],
      ),
    );
  }
}

/// The live end of the line: a dark ring with the side colour inside.
class _EndDot extends StatelessWidget {
  const _EndDot({required this.up});

  final bool up;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: VistaColors.background,
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: up ? VistaColors.long : VistaColors.short,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
