import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/design_system.dart';
import '../live/live_feed.dart';
import 'portfolio_mock.dart';

/// "My portfolio" number and chart, swipeable to the user's own market cap.
///
/// A horizontal drag on the numbers or the chart moves between the two pages;
/// letting go settles on whichever is nearer (or the one flung towards). The
/// numbers slide and crossfade and the chart crossfades from the portfolio
/// line in focus to the market line in focus, following the finger.
///
/// Figma: portfolio page 174:110; market page and mid-swipe from the
/// "Swipe numbers" storyboard (160:110 → 160:146 → 160:180). The market-focus
/// chart gets the same fill and dot-grid treatment as the portfolio one — see
/// `tool/derive_market_focus_chart.py`.
class PortfolioPager extends StatefulWidget {
  const PortfolioPager({
    super.key,
    this.hasMarket = true,
    this.ticker = 'MAYA',
  });

  /// Without a market there is no market-cap page: the pager stays on the
  /// portfolio and ignores swipes.
  final bool hasMarket;

  /// The user's market ticker shown on the market-cap page.
  final String ticker;

  @override
  State<PortfolioPager> createState() => _PortfolioPagerState();
}

/// How far a page travels sideways between in-focus and gone.
const double _slide = 24;

/// Chart box size in Figma; layers are placed in these units.
const double _chartWidth = 370;
const double _chartHeight = 170;

/// Opacity of the outgoing page at progress 0 → 0.5 → 1 (Figma mid-swipe
/// shows 35% outgoing and 65% incoming).
double _outgoing(double p) =>
    p < 0.5 ? 1 - (p / 0.5) * 0.65 : 0.35 * (1 - (p - 0.5) / 0.5);
double _incoming(double p) => _outgoing(1 - p);

class _PortfolioPagerState extends State<PortfolioPager>
    with SingleTickerProviderStateMixin {
  /// 0 = portfolio in focus, 1 = market in focus.
  late final AnimationController _page = AnimationController(vsync: this);

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _onDrag(DragUpdateDetails d) {
    final width = context.size?.width ?? _chartWidth;
    _page.value = (_page.value - d.primaryDelta! / width).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final target = v < -300
        ? 1.0
        : v > 300
        ? 0.0
        : _page.value.roundToDouble();
    _settle(target);
  }

  void _settle(double target) {
    final instant = MediaQuery.disableAnimationsOf(context);
    _page.animateTo(
      target,
      duration: instant ? Duration.zero : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Swipe to switch between portfolio and market cap',
      onIncrease: () => _settle(1),
      onDecrease: () => _settle(0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: widget.hasMarket ? _onDrag : null,
        onHorizontalDragEnd: widget.hasMarket ? _onDragEnd : null,
        child: AnimatedBuilder(
          animation: _page,
          builder: (context, _) {
            final p = _page.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VistaSpace.gutter,
                  ),
                  child: SizedBox(
                    height: 86,
                    child: ClipRect(
                      child: Stack(
                        children: [
                          _slid(
                            dx: -_slide * p,
                            opacity: _outgoing(p),
                            child: _NumberPage(
                              caption: 'My portfolio',
                              dots: VistaAssets.pagerDots,
                              value: PortfolioMock.balance,
                              live: true,
                              change: PortfolioMock.change24h,
                            ),
                          ),
                          _slid(
                            dx: _slide * (1 - p),
                            opacity: _incoming(p),
                            child: _NumberPage(
                              caption: '\$${widget.ticker} market cap',
                              dots: VistaAssets.pagerDotsMarket,
                              value: PortfolioMock.marketCap,
                              change: PortfolioMock.marketCapChange24h,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: VistaSpace.sm),
                _Chart(progress: p, hasMarket: widget.hasMarket),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _slid({
    required double dx,
    required double opacity,
    required Widget child,
  }) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(dx, 0), child: child),
        ),
      ),
    );
  }
}

class _NumberPage extends StatelessWidget {
  const _NumberPage({
    required this.caption,
    required this.dots,
    required this.value,
    required this.change,
    this.live = false,
  });

  final String caption;
  final String dots;
  final String value;

  /// Roll the value with the live feed (the portfolio balance).
  final bool live;
  final String change;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                caption,
                style: VistaType.subheadMuted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: VistaSpace.md),
            // Page indicator.
            VistaIcon(dots, size: 16, height: 6),
          ],
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: live
              ? LiveUsd(
                  feedKey: 'portfolio',
                  base: parseUsd(value),
                  step: 9,
                  style: VistaType.display,
                )
              : Text(value, style: VistaType.display),
        ),
        const SizedBox(height: 3),
        Wrap(
          spacing: VistaSpace.xs,
          children: [
            Text(
              change,
              style: VistaType.bodyMedium.copyWith(color: VistaColors.long),
            ),
            Text('Last 24 hours', style: VistaType.bodyMedium),
          ],
        ),
      ],
    );
  }
}

/// Both chart states on one 370×170 box, crossfaded by [progress].
class _Chart extends StatelessWidget {
  const _Chart({required this.progress, required this.hasMarket});

  final double progress;

  /// Without a market there is no second line to show behind the portfolio.
  final bool hasMarket;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _chartHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
        child: LayoutBuilder(
          builder: (context, c) {
            final sx = c.maxWidth / _chartWidth;

            // A vector placed in Figma chart units; x stretches with width.
            Widget layer(String asset, Rect r) => Positioned(
              left: r.left * sx,
              top: r.top,
              width: r.width * sx,
              height: r.height,
              child: SvgPicture.asset(asset, fit: BoxFit.fill),
            );

            // Linear crossfade keeps the chart's weight mid-swipe; the
            // numbers use the steeper Figma fade since they overlap.
            final market = progress;
            final portfolio = 1 - progress;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                if (portfolio > 0)
                  Opacity(
                    opacity: portfolio,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        layer(
                          hasMarket
                              ? VistaAssets.portfolioChart
                              : VistaAssets.portfolioChartSolo,
                          const Rect.fromLTWH(-5, 0, 381, 176),
                        ),
                      ],
                    ),
                  ),
                if (market > 0)
                  Opacity(
                    opacity: market,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        layer(
                          VistaAssets.portfolioChartMarketFocus,
                          const Rect.fromLTWH(-5, 0, 381, 176),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
