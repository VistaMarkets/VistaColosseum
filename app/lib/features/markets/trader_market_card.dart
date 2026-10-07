import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../live/market_prices.dart';
import '../portfolio/series_chart.dart';
import 'markets_mock.dart';

/// A trader market in the Traders list (Figma 546:300): avatar, name and
/// market cap, favourite star; live price with its 7-day change; the week
/// as a chart in the app's line style; holders, market cap and open calls.
/// Simulated history; not market data.
class TraderMarketCard extends StatelessWidget {
  const TraderMarketCard({
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

  static const double _chartHeight = 96;

  String get name => market.name;

  /// "26,100,000" from a cap in millions.
  static String _grouped(double millions) {
    final digits = (millions * 1000000).round().toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  @override
  Widget build(BuildContext context) {
    final m = market;
    final card = MarketsMock.traderCards[m.id];
    final capM = m.sortValues['Market cap'] ?? 0;
    final open = m.sortValues['Open calls']?.toInt() ?? 0;
    final base = MarketPrices.base(m.id);
    final history = bridgeSeries(
      'explore/${m.id}',
      base / (1 + m.changePct / 100),
      base,
      n: 42,
    );
    final label = VistaType.meta.copyWith(color: VistaColors.textMuted);
    final value = VistaType.figures(VistaType.row);

    Widget stat(String name, String text) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: label),
          const SizedBox(height: VistaSpace.xxs),
          Text(text, style: value),
        ],
      ),
    );

    return ValueListenableBuilder(
      valueListenable: MarketPrices.of(m.id),
      builder: (context, price, _) {
        final series = endAt(history, price);
        final up = m.changePct >= 0;
        return Semantics(
          button: true,
          label:
              '${m.name}, ${MarketPrices.format(price, compact: true)}, '
              '${vistaChangeLabel(m.changePct)} over 7 days',
          child: VistaPressable(
            scale: 0.98,
            onTap: onPressed,
            child: Container(
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
                  SizedBox(
                    height: 36,
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Color(
                              card?.avatar ??
                                  VistaColors.surfaceRaised.toARGB32(),
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            m.name[0].toUpperCase(),
                            style: VistaType.subhead,
                          ),
                        ),
                        const SizedBox(width: VistaSpace.lg),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                style: VistaType.subhead.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Market cap: ${_grouped(capM)}',
                                style: VistaType.chip.copyWith(
                                  color: VistaColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        VistaStarButton(
                          starred: starred,
                          onPressed: onStar,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        MarketPrices.format(price, compact: true),
                        style: VistaType.figures(VistaType.displayMedium),
                      ),
                      const SizedBox(width: VistaSpace.md),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '${up ? '▲' : '▼'}'
                                  '${m.changePct.abs().toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: vistaChangeColor(m.changePct),
                              ),
                            ),
                            TextSpan(
                              text: ' 7d',
                              style: TextStyle(
                                color: VistaColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        style: VistaType.figures(VistaType.row),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: _chartHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(child: SeriesChart(focus: series)),
                        _EndDot(series: series, up: price >= series.first),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      stat('Holders', '${card?.holders ?? 0}'),
                      stat('Market cap', m.third),
                      stat(
                        'Open now',
                        open == 0
                            ? 'None'
                            : '$open call${open == 1 ? '' : 's'}',
                      ),
                    ],
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

/// The live end of the line: a dark ring with the side colour inside, at
/// the height [SeriesChart] draws the last point.
class _EndDot extends StatelessWidget {
  const _EndDot({required this.series, required this.up});

  final List<double> series;
  final bool up;

  @override
  Widget build(BuildContext context) {
    final lo = series.reduce(math.min);
    final hi = series.reduce(math.max);
    final pad = (hi - lo) * 0.12;
    final y =
        canvasY(series.last, lo - pad, hi + pad) /
        403 *
        TraderMarketCard._chartHeight;
    return Positioned(
      right: -6,
      top: y - 6,
      child: Container(
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
      ),
    );
  }
}
