import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../settings/settings_state.dart';

/// One swipeable page under the chart.
class ChartSheetPanel {
  const ChartSheetPanel(this.title, this.child);

  final String title;
  final Widget child;
}

/// Trading screen layout shared by trader markets and asset trade pages: a
/// header, a chart that resizes, the interval selector, a drag handle,
/// sideways-swiping panels with page dots, and Long / Short at the bottom.
///
/// Opens with the panels up on the first panel. Dragging the handle (or the
/// chart) down opens the chart full height; dragging up brings the panels

/// Settles a dragged panel: critically damped, carrying the fling's speed.
const _settleSpring = SpringDescription(mass: 1, stiffness: 500, damping: 45);

/// back. Builders receive `collapse`: 0 = chart open, 1 = panels up.
class ChartSheet extends StatefulWidget {
  const ChartSheet({
    super.key,
    required this.header,
    required this.chart,
    required this.panels,
    required this.intervals,
    required this.defaultInterval,
    required this.onNotBuilt,
    this.chartTypeAsset = VistaAssets.chartTypeToggle,
    this.onIntervalChanged,
    this.onChartType,
    this.onSide,
  });

  final Widget Function(double collapse) header;
  final Widget Function(double collapse) chart;
  final List<ChartSheetPanel> panels;
  final List<String> intervals;
  final int defaultInterval;
  final ValueChanged<String> onNotBuilt;

  /// Chart-type toggle art (line or candles selected).
  final String chartTypeAsset;

  /// Called with the new index when an interval is picked.
  final ValueChanged<int>? onIntervalChanged;

  /// Chart-type toggle tap; without it the toggle reports "not built".
  final VoidCallback? onChartType;

  /// Long or Short tapped: opens the order ticket on that side.
  final ValueChanged<TradeSide>? onSide;

  @override
  State<ChartSheet> createState() => _ChartSheetState();
}

/// Short chart height with the panels up (Figma).
const double _shortChart = 196;

/// Fixed rows between chart and panel: interval selector + handle row.
const double _selectorH = 44;
const double _handleH = 12;

class _ChartSheetState extends State<ChartSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheet = AnimationController(
    vsync: this,
    value: 1,
  );
  final _pages = PageController();
  int _page = 0;
  late int _interval = widget.defaultInterval;

  /// Distance the chart grows between the two states; set during layout.
  double _travel = 300;

  @override
  void dispose() {
    _sheet.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _onDrag(DragUpdateDetails d) {
    _sheet.value = (_sheet.value - d.primaryDelta! / _travel).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final target = v > 400
        ? 0.0
        : v < -400
        ? 1.0
        : _sheet.value.roundToDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      _settle(target);
      return;
    }
    if ((target - _sheet.value).abs() > 0.5) HapticFeedback.lightImpact();
    // The spring keeps the finger's speed, so a fast fling stays fast.
    _sheet
        .animateWith(
          SpringSimulation(_settleSpring, _sheet.value, target, -v / _travel),
        )
        // Land exactly on the page; a spring stops a hair short.
        .then((_) {
          if (mounted) _sheet.value = target;
        });
  }

  void _settle(double target) {
    final instant = MediaQuery.disableAnimationsOf(context);
    _sheet.animateTo(
      target,
      duration: instant ? Duration.zero : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _sheet,
          builder: (context, _) {
            final t = _sheet.value;
            return Column(
              children: [
                widget.header(t),
                Expanded(child: _body(t)),
                _tradeButtons(bottomInset),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(double t) {
    return LayoutBuilder(
      builder: (context, c) {
        // Chart-open padding (8 top, 14 bottom) folds away as panels rise.
        final padTop = lerpDouble(8, 0, t)!;
        final padBottom = lerpDouble(14, 0, t)!;
        final openChart = c.maxHeight - _selectorH - _handleH - 8 - 14;
        final shortChart = openChart < _shortChart ? openChart : _shortChart;
        _travel = (openChart - shortChart).clamp(1, double.infinity);
        final chartH = lerpDouble(openChart, shortChart, t)!;
        final panelH =
            c.maxHeight - _selectorH - _handleH - chartH - padTop - padBottom;

        return Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: _onDrag,
              onVerticalDragEnd: _onDragEnd,
              child: Column(
                children: [
                  // Full width: charts run edge to edge, their price axis
                  // keeping its own margin at the right.
                  Padding(
                    padding: EdgeInsets.only(top: padTop, bottom: padBottom),
                    child: SizedBox(height: chartH, child: widget.chart(t)),
                  ),
                  SizedBox(
                    height: _selectorH,
                    child: VistaIntervalSelector(
                      intervals: widget.intervals,
                      selectedIndex: _interval,
                      chartTypeAsset: widget.chartTypeAsset,
                      onChanged: (i) {
                        setState(() => _interval = i);
                        widget.onIntervalChanged?.call(i);
                      },
                      onMore: () => widget.onNotBuilt('More intervals'),
                      onIndicators: () => widget.onNotBuilt('Indicators'),
                      onChartType:
                          widget.onChartType ??
                          () => widget.onNotBuilt('Chart type'),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: t > 0.5 ? 'Expand chart' : 'Show panels',
                    onTap: () => _settle(t > 0.5 ? 0 : 1),
                    child: GestureDetector(
                      onTap: () => _settle(t > 0.5 ? 0 : 1),
                      child: const SizedBox(
                        height: _handleH,
                        width: double.infinity,
                        child: Center(child: VistaDragHandle()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: panelH.clamp(0, double.infinity),
              child: ClipRect(
                child: Opacity(
                  opacity: t,
                  child: IgnorePointer(
                    ignoring: t < 0.5,
                    // Nothing to lay out until there is room for the dots.
                    child: panelH < 16 ? const SizedBox.shrink() : _panels(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _panels() {
    final n = widget.panels.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: VistaSpace.xs),
          child: Semantics(
            label: 'Panel ${_page + 1} of $n, ${widget.panels[_page].title}',
            child: VistaPageDots(count: n, index: _page),
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pages,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              // Each page scrolls when the phone is too short to show it.
              for (final p in widget.panels)
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VistaSpace.gutter,
                    vertical: VistaSpace.lg,
                  ),
                  child: p.child,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tradeButtons(double bottomInset) {
    return Container(
      decoration: const BoxDecoration(
        color: VistaColors.background,
        border: Border(top: BorderSide(color: VistaColors.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(
        VistaSpace.gutter,
        VistaSpace.xl,
        VistaSpace.gutter,
        bottomInset > 0 ? bottomInset : VistaSpace.gutter,
      ),
      child: ValueListenableBuilder(
        valueListenable: DisplayPrefs.longOnRight,
        builder: (context, longOnRight, _) => VistaSidePair(
          longOnRight: longOnRight,
          long: VistaPillButton(
            label: 'Long',
            variant: VistaPillVariant.long,
            // Simulated only: the demo never places an order.
            onPressed: () => widget.onSide != null
                ? widget.onSide!(TradeSide.long)
                : widget.onNotBuilt('Long (simulated)'),
          ),
          short: VistaPillButton(
            label: 'Short',
            variant: VistaPillVariant.short,
            onPressed: () => widget.onSide != null
                ? widget.onSide!(TradeSide.short)
                : widget.onNotBuilt('Short (simulated)'),
          ),
        ),
      ),
    );
  }
}

/// Panel title with an optional trailing widget.
Widget chartSheetTitle(String text, [Widget? trailing]) => Row(
  children: [
    Expanded(child: Text(text, style: VistaType.headline)),
    ?trailing,
  ],
);
