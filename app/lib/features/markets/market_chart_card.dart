import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../live/market_prices.dart';
import '../portfolio/portfolio_mock.dart';
import '../portfolio/series_chart.dart';
import 'leaderboard.dart';
import 'markets_mock.dart';

/// A trader market on the Explore Leaderboard, laid out like the Assets
/// All markets rows ([AssetMarketCard]) and the same for every chip: its
/// place (the top three in medal colours, the avatar ringed to match),
/// avatar, ticker over handle, a small line chart of the selected
/// [window], then market cap over its 24h change. Your own market is
/// outlined. Simulated history.
class LeaderboardCard extends StatelessWidget {
  const LeaderboardCard({
    super.key,
    required this.rank,
    required this.market,
    required this.metric,
    required this.window,
    this.isYou = false,
    this.onPressed,
  });

  final int rank;
  final MarketItem market;

  /// The chip the board is ranked by (`MarketsMock.traderSorts`).
  final String metric;

  /// Index into [Leaderboard.windows].
  final int window;
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
    // One card for every chip: market cap and its 24h change on the right.
    final day = Leaderboard.value(m, 'Change', 0) ?? m.changePct;
    final change = Leaderboard.value(m, 'Change', window) ?? m.changePct;
    // Your own market just says so; the handle is yours.
    final handle = isYou ? 'You' : m.name;
    final narrow = MediaQuery.sizeOf(context).width < 390;

    return ValueListenableBuilder(
      valueListenable: MarketPrices.of(m.id),
      builder: (context, price, _) => Semantics(
        button: true,
        label:
            '#$rank ${card?.symbol ?? m.name}, $handle, ${m.third} cap, '
            '${vistaChangeLabel(day)} over 24h',
        child: VistaPressable(
          scale: 0.98,
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 59),
            padding: EdgeInsets.fromLTRB(
              VistaSpace.lg,
              VistaSpace.lg,
              VistaSpace.xl,
              VistaSpace.lg,
            ),
            decoration: BoxDecoration(
              color: VistaColors.surface,
              borderRadius: BorderRadius.circular(VistaRadius.card),
              border: isYou
                  ? Border.all(color: VistaColors.accent, width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: VistaType.figures(VistaType.body).copyWith(
                      fontWeight: FontWeight.w700,
                      color: medal ?? VistaColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: VistaSpace.sm),
                Container(
                  width: VistaSize.listLeading,
                  height: VistaSize.listLeading,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color(
                      card?.avatar ?? VistaColors.surfaceRaised.toARGB32(),
                    ),
                    shape: BoxShape.circle,
                    border: medal == null
                        ? null
                        : Border.all(color: medal, width: 1.5),
                  ),
                  child: Text(m.name[0].toUpperCase(), style: VistaType.body),
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
                        handle,
                        style: VistaType.chip.copyWith(
                          color: VistaColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: narrow ? 52 : 72,
                  child: MarketLineChart(
                    id: m.id,
                    changePct: change,
                    price: price,
                    height: 30,
                    seriesKey: 'explore/${m.id}/$window',
                  ),
                ),
                const SizedBox(width: VistaSpace.xl),
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: narrow ? 64 : 76),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        m.third,
                        style: VistaType.figures(VistaType.body)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${day >= 0 ? '▲' : '▼'}'
                        '${day.abs().toStringAsFixed(1)}% 24h',
                        style: VistaType.figures(VistaType.label)
                            .copyWith(color: vistaChangeColor(day)),
                      ),
                    ],
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

/// An asset perp in Explore's All markets: a compact row, the reference
/// list under the sections. Icon, ticker and leverage over the full name,
/// a small line chart of the day, live price with its 24h change, and the
/// favourite star.
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
    final narrow = MediaQuery.sizeOf(context).width < 390;
    return ValueListenableBuilder(
      valueListenable: MarketPrices.of(m.id),
      builder: (context, price, _) => Semantics(
        button: true,
        label:
            '${m.name}, ${MarketsMock.assetNames[m.id] ?? m.name}, '
            '${MarketPrices.format(price, compact: true)}, '
            '${vistaChangeLabel(m.changePct)} over 24h',
        child: VistaPressable(
          scale: 0.98,
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 59),
            padding: const EdgeInsets.fromLTRB(
              VistaSpace.xl,
              VistaSpace.lg,
              VistaSpace.xs,
              VistaSpace.lg,
            ),
            decoration: BoxDecoration(
              color: VistaColors.surface,
              borderRadius: BorderRadius.circular(VistaRadius.card),
            ),
            child: Row(
              children: [
                VistaIcon(m.rowIcon, size: VistaSize.listLeading),
                const SizedBox(width: VistaSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              m.name,
                              style: VistaType.subhead.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (m.badge != null) ...[
                            const SizedBox(width: VistaSpace.sm),
                            Text(
                              m.badge!,
                              style: VistaType.label.copyWith(
                                color: VistaColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        MarketsMock.assetNames[m.id] ?? m.name,
                        style: VistaType.chip.copyWith(
                          color: VistaColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: narrow ? 52 : 72,
                  child: MarketLineChart(
                    id: m.id,
                    changePct: m.changePct,
                    price: price,
                    height: 30,
                  ),
                ),
                const SizedBox(width: VistaSpace.xl),
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: narrow ? 64 : 76),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        MarketPrices.format(price, compact: true),
                        style: VistaType.figures(VistaType.subhead),
                      ),
                      Text(
                        '${m.changePct >= 0 ? '▲' : '▼'}'
                        '${m.changePct.abs().toStringAsFixed(1)}%',
                        style: VistaType.figures(VistaType.label)
                            .copyWith(color: vistaChangeColor(m.changePct)),
                      ),
                    ],
                  ),
                ),
                VistaStarButton(starred: starred, onPressed: onStar, size: 16),
              ],
            ),
          ),
        ),
      ),
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
    this.invert = false,
  });

  final String id;

  /// Flips the line, so up is green for a short (where a falling price is
  /// the gain).
  final bool invert;

  /// Seeds the line's shape; defaults to the market's own.
  final String? seriesKey;
  final double changePct;
  final double price;
  final double height;

  @override
  Widget build(BuildContext context) {
    final base = MarketPrices.base(id);
    final raw = endAt(
      bridgeSeries(
        seriesKey ?? 'explore/$id',
        base / (1 + changePct / 100),
        base,
        n: 42,
      ),
      price,
    );
    final series = invert ? [for (final v in raw) -v] : raw;
    final lo = series.reduce(math.min);
    final hi = series.reduce(math.max);
    final pad = (hi - lo) * 0.12;
    final endY = canvasY(series.last, lo - pad, hi + pad) / 403 * height;
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The 3pt line reads heavy on small charts (the Favorites rail,
          // the Leaderboard), so they draw it at 1.5pt.
          Positioned.fill(
            child: SeriesChart(focus: series, lineWidth: height < 40 ? 1.5 : 3),
          ),
          Positioned(
            right: -6,
            top: endY - 6,
            child: _EndDot(up: series.last >= series.first),
          ),
        ],
      ),
    );
  }
}

/// An open position's chart for its row (Portfolio, the position picker):
/// the app's line from the entry to the live price, flipped for a short so
/// green is always the gain. Simulated history.
class PositionLineChart extends StatelessWidget {
  const PositionLineChart({super.key, required this.position});

  final PortfolioPosition position;

  @override
  Widget build(BuildContext context) {
    final d = position.detail;
    final base = MarketPrices.base(d.symbol);
    if (base == 0 || d.entry == 0) return const SizedBox.shrink();
    return ValueListenableBuilder(
      valueListenable: MarketPrices.of(d.symbol),
      builder: (context, price, _) => MarketLineChart(
        id: d.symbol,
        // Starts at the entry, ends at the live price.
        changePct: (base / d.entry - 1) * 100,
        price: price,
        height: 30,
        seriesKey: 'position/${d.symbol}/${d.entry}',
        invert: position.side == TradeSide.short,
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
