import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../live/live_feed.dart';
import '../market/market_mock.dart';
import 'portfolio_mock.dart';
import 'series_chart.dart';

/// "My portfolio" number and chart, swipeable to the user's own market cap.
///
/// A horizontal drag on the numbers or the chart moves between the two pages;
/// letting go settles on whichever is nearer (or the one flung towards). The
/// numbers slide and crossfade and the chart crossfades from the portfolio
/// line in focus to the market line in focus, following the finger.
///
/// Figma: portfolio page 174:110; market page and mid-swipe from the
/// "Swipe numbers" storyboard (160:110 → 160:146 → 160:180).
///
/// The chart is drawn from the data: the balance over the chosen [span]
/// ending at the live balance, and the user's own cap
/// (`Scenario.ownCapCents`) over the same span. Each
/// page puts its own line in focus with the other muted behind it, and the
/// change under the number is measured over that span. Simulated history.
class PortfolioPager extends StatefulWidget {
  const PortfolioPager({
    super.key,
    this.hasMarket = true,
    this.ticker = 'MAYA',
    this.span = PortfolioMock.defaultSpan,
  });

  /// Index into [PortfolioMock.spans]: the window the chart and the change
  /// cover.
  final int span;

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

/// Chart box size in Figma.
const double _chartWidth = 370;
const double _chartHeight = 170;

/// What the balance moved by over each span (1h, 4h, 1D, 1W, 1M, All),
/// ending at today's figure. 1D is the design's +$91. Mock.
const _balanceMoves = [-15.0, 26.0, 91.0, 412.0, 937.0, 3920.0];

/// The user's cash in dollars, for the chart and its change line only; the
/// headline shows the stored cents.
double get _balance => Scenario.cashCents.value / 100;

/// The balance, live.
ValueListenable<double> get _liveBalance =>
    LiveFeed.watch('portfolio', _balance, 9);

/// "+$91 (0.73%)" for a move from [start] to [end].
String _change(double start, double end) {
  final d = end - start;
  final moved = '${d < 0 ? '−' : '+'}${formatUsd(d.abs())}';
  // No percentage of a start at or below zero.
  if (start <= 0) return moved;
  return '$moved (${(d.abs() / start * 100).toStringAsFixed(2)}%)';
}

/// Opacity of the outgoing page at progress 0 → 0.5 → 1 (Figma mid-swipe
/// shows 35% outgoing and 65% incoming).
double _outgoing(double p) =>
    p < 0.5 ? 1 - (p / 0.5) * 0.65 : 0.35 * (1 - (p - 0.5) / 0.5);
double _incoming(double p) => _outgoing(1 - p);

class _PortfolioPagerState extends State<PortfolioPager>
    with SingleTickerProviderStateMixin {
  /// 0 = portfolio in focus, 1 = market in focus.
  late final AnimationController _page = AnimationController(vsync: this);

  /// Rebuild on a swipe, or when the cash or the user's cap changes.
  late final _rebuild = Listenable.merge([
    _page,
    Scenario.cashCents,
    Scenario.ownCap,
  ]);

  /// Whether there is a cap page: the one gate for the page, the cap
  /// line, the swipes and their semantics.
  bool get _hasCap => widget.hasMarket && Scenario.ownCapCents != null;

  @override
  void didUpdateWidget(PortfolioPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset can unlist the market; there is then no cap page to stay on.
    if (!_hasCap) _page.value = 0;
  }

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
    // The gestures and semantics follow parent rebuilds; the builder below
    // re-reads the gate on ownCap. A bare pager whose cap changes while
    // mounted is unsupported (spec 12, Readers).
    final hasCap = _hasCap;
    return Semantics(
      label: hasCap ? 'Swipe to switch between portfolio and market cap' : null,
      onIncrease: hasCap ? () => _settle(1) : null,
      onDecrease: hasCap ? () => _settle(0) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: hasCap ? _onDrag : null,
        onHorizontalDragEnd: hasCap ? _onDragEnd : null,
        child: AnimatedBuilder(
          animation: _rebuild,
          builder: (context, _) {
            final p = _page.value;
            final cap = _hasCap ? Scenario.ownCapCents : null;
            final capSeries = _hasCap ? ownCapSeries(widget.span) : null;
            final capMove = _hasCap ? Scenario.ownCapMoveCents(widget.span) : 0;
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
                            child: ValueListenableBuilder(
                              valueListenable: _liveBalance,
                              builder: (context, live, _) {
                                final start =
                                    _balance - _balanceMoves[widget.span];
                                return _NumberPage(
                                  caption: 'My portfolio',
                                  dots: VistaAssets.pagerDots,
                                  value: formatCents(Scenario.cashCents.value),
                                  change: _change(start, live),
                                  up: live >= start,
                                  window: spanWindows[widget.span],
                                );
                              },
                            ),
                          ),
                          if (cap != null)
                            _slid(
                              dx: _slide * (1 - p),
                              opacity: _incoming(p),
                              child: _NumberPage(
                                caption: '\$${widget.ticker} market cap',
                                dots: VistaAssets.pagerDotsMarket,
                                value: formatCap(cap),
                                change: formatCapChange(cap - capMove, cap),
                                up: capMove >= 0,
                                window: spanWindows[widget.span],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: VistaSpace.sm),
                _Chart(progress: p, cap: capSeries, span: widget.span),
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
    required this.up,
    required this.window,
  });

  final String caption;
  final String dots;
  final String value;
  final String change;
  final bool up;

  /// The span the change covers, e.g. "Last 24 hours".
  final String window;

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
          child: VistaRollingNumber(value, style: VistaType.display),
        ),
        const SizedBox(height: 3),
        Wrap(
          spacing: VistaSpace.xs,
          children: [
            Text(
              change,
              style: VistaType.bodyMedium.copyWith(
                color: up ? VistaColors.long : VistaColors.short,
              ),
            ),
            Text(window, style: VistaType.bodyMedium),
          ],
        ),
      ],
    );
  }
}

/// Both chart states on one 370×170 box, crossfaded by [progress]: the
/// balance in focus with the market cap muted behind it, then the reverse.
class _Chart extends StatelessWidget {
  const _Chart({required this.progress, required this.cap, required this.span});

  final double progress;

  /// The user's cap over [span] (`ownCapSeries`); null without a cap, so
  /// there is no second line to show behind the portfolio.
  final List<double>? cap;
  final int span;

  @override
  Widget build(BuildContext context) {
    final cap = this.cap;
    final history = bridgeSeries(
      'portfolio/$span',
      _balance - _balanceMoves[span],
      _balance,
    );
    return SizedBox(
      height: _chartHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
        child: ValueListenableBuilder(
          valueListenable: _liveBalance,
          builder: (context, live, _) {
            final balance = endAt(history, live);
            // Linear crossfade keeps the chart's weight mid-swipe; the
            // numbers use the steeper Figma fade since they overlap.
            final market = progress;
            final portfolio = 1 - progress;
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                if (portfolio > 0)
                  Opacity(
                    opacity: portfolio,
                    child: SeriesChart(focus: balance, muted: cap),
                  ),
                if (market > 0 && cap != null)
                  Opacity(
                    opacity: market,
                    child: SeriesChart(focus: cap, muted: balance),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
