import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../live/market_prices.dart';
import '../portfolio/series_chart.dart';
import 'markets_mock.dart';

/// A trader market in the Traders Favorites rail (Figma 546:268,
/// TRADER-CARD-B): name and record, live price and change, a 7-day chart in
/// the app's line style with settled calls pinned on it, then holders,
/// market cap and open calls. Simulated history; not market data.
class TraderChartCard extends StatelessWidget {
  const TraderChartCard({
    super.key,
    required this.market,
    required this.width,
    this.onPressed,
  });

  final MarketItem market;
  final double width;
  final VoidCallback? onPressed;

  String get name => market.name;

  @override
  Widget build(BuildContext context) {
    final m = market;
    final stats = MarketsMock.traderStats[m.id];
    final open = m.sortValues['Open calls']?.toInt() ?? 0;
    final calls = m.subline; // "62 calls"
    final label = VistaType.caption.copyWith(color: VistaColors.textMuted);
    // The week's history, pinned to the live price at its end.
    final base = MarketPrices.base(m.id);
    final history = bridgeSeries(
      'explore/${m.id}',
      base / (1 + m.changePct / 100),
      base,
      n: 42,
    );

    Widget stat(String name, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: label),
          const SizedBox(height: VistaSpace.xxs),
          Text(value, style: VistaType.figures(VistaType.bodyStrong)),
        ],
      ),
    );

    return ValueListenableBuilder(
      valueListenable: MarketPrices.of(m.id),
      builder: (context, price, _) => Semantics(
        button: true,
        label:
            '${m.name}, ${MarketPrices.format(price, compact: true)}, '
            '${vistaChangeLabel(m.changePct)}'
            '${stats == null ? '' : ', ${stats.accuracy}% right'}',
        excludeSemantics: true,
        child: VistaPressable(
          scale: 0.98,
          onTap: onPressed,
          child: Container(
            width: width,
            padding: const EdgeInsets.fromLTRB(
              VistaSpace.gutter,
              VistaSpace.xxl,
              VistaSpace.gutter,
              VistaSpace.xxl,
            ),
            decoration: BoxDecoration(
              color: VistaColors.surface,
              borderRadius: BorderRadius.circular(VistaRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VistaIcon(m.railIcon, size: VistaSize.avatarLarge - 4),
                    const SizedBox(width: VistaSpace.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: VistaType.bodyStrong,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                if (stats != null)
                                  TextSpan(
                                    text: '${stats.accuracy}% right · ',
                                    style: TextStyle(
                                      color: stats.accuracy >= 55
                                          ? VistaColors.long
                                          : VistaColors.textMuted,
                                    ),
                                  ),
                                TextSpan(text: calls),
                              ],
                            ),
                            style: label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '★',
                      style: VistaType.body.copyWith(
                        color: VistaColors.favorite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VistaSpace.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      MarketPrices.format(price, compact: true),
                      style: VistaType.figures(VistaType.title),
                    ),
                    const SizedBox(width: VistaSpace.md),
                    Text(
                      vistaChangeLabel(m.changePct),
                      style: VistaType.figures(VistaType.label)
                          .copyWith(color: vistaChangeColor(m.changePct)),
                    ),
                  ],
                ),
                const SizedBox(height: VistaSpace.lg),
                SizedBox(
                  height: 96,
                  child: SeriesChart(
                    focus: endAt(history, price),
                    marks: stats?.marks ?? const [],
                  ),
                ),
                const SizedBox(height: VistaSpace.lg),
                Row(
                  children: [
                    if (stats != null) stat('Holders', '${stats.holders}'),
                    stat('Market cap', m.third),
                    stat(
                      'Open now',
                      open == 0 ? 'None' : '$open call${open == 1 ? '' : 's'}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
