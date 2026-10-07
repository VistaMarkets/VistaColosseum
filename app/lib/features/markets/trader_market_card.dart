import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../live/market_prices.dart';
import '../portfolio/series_chart.dart';
import 'markets_mock.dart';

/// A trader market in the Traders list (Figma 546:300, compacted): avatar,
/// ticker over the trader's handle, live price with its 7-day change, favourite star;
/// the week as a short chart in the app's line style; then holders, market
/// cap and open calls on one line.
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

  static const double _chartHeight = 56;

  String get name => market.name;

  @override
  Widget build(BuildContext context) {
    final m = market;
    final card = MarketsMock.traderCards[m.id];
    final open = m.sortValues['Open calls']?.toInt() ?? 0;
    final base = MarketPrices.base(m.id);
    final history = bridgeSeries(
      'explore/${m.id}',
      base / (1 + m.changePct / 100),
      base,
      n: 42,
    );
    final muted = VistaType.meta.copyWith(color: VistaColors.textMuted);
    final strong = VistaType.figures(VistaType.meta)
        .copyWith(color: VistaColors.textPrimary, fontWeight: FontWeight.w600);

    return ValueListenableBuilder(
      valueListenable: MarketPrices.of(m.id),
      builder: (context, price, _) {
        final series = endAt(history, price);
        final up = m.changePct >= 0;
        return Semantics(
          button: true,
          label:
              '${card?.symbol ?? m.name}, ${m.name}, ${MarketPrices.format(price, compact: true)}, '
              '${vistaChangeLabel(m.changePct)} over 7 days',
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
                                card?.symbol ?? m.name,
                                style: VistaType.subhead.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                m.name,
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
                  const SizedBox(height: VistaSpace.md),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${card?.holders ?? 0}', style: strong),
                        const TextSpan(text: ' holders  ·  '),
                        TextSpan(text: m.third, style: strong),
                        const TextSpan(text: ' cap  ·  '),
                        if (open == 0)
                          const TextSpan(text: 'No open calls')
                        else ...[
                          TextSpan(text: '$open', style: strong),
                          TextSpan(text: ' open call${open == 1 ? '' : 's'}'),
                        ],
                      ],
                    ),
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
