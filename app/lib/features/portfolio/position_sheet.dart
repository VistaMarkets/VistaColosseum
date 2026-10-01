import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/design_system.dart';
import '../live/live_feed.dart';
import '../live/market_prices.dart';
import '../home/signal_replay_chart.dart';
import 'portfolio_mock.dart';
import 'series_chart.dart';

/// Slides the position sheet up from the bottom (Figma 104:110, "Position
/// sheet · as built → P/L-led, portfolio chart").
Future<void> showPositionSheet(BuildContext context, PortfolioPosition p) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: VistaColors.background,
    barrierColor: const Color(0x99000000),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (_) => PositionSheet(position: p),
  );
}

/// P/L-led detail for one open position: header, unrealised P/L, the chart
/// against entry with take-profit and stop-loss, time spans, adjustable
/// levels and Close.
class PositionSheet extends StatefulWidget {
  const PositionSheet({super.key, required this.position});

  final PortfolioPosition position;

  @override
  State<PositionSheet> createState() => _PositionSheetState();
}

class _PositionSheetState extends State<PositionSheet> {
  late double _tp = widget.position.detail.takeProfit;
  late double _sl = widget.position.detail.stopLoss;

  /// Levels as last saved; editing either turns Close into Edit.
  late double _savedTp = _tp;
  late double _savedSl = _sl;

  /// Tolerance for float drift from repeated nudges (a millionth of entry).
  double get _eps => _d.entry * 1e-6;

  bool get _edited =>
      (_tp - _savedTp).abs() > _eps || (_sl - _savedSl).abs() > _eps;
  int _span = PortfolioMock.defaultSpan;

  PositionDetail get _d => widget.position.detail;
  bool get _long => widget.position.side == TradeSide.long;

  /// One stepper press: 0.5% of entry.
  double get _step => _d.entry * 0.005;

  String _usd(double v) => formatUsd(v, decimals: _d.decimals);

  String _pct(double level) {
    final pct = (level - _d.entry) / _d.entry * 100;
    return '${pct >= 0 ? '+' : '−'}${pct.abs().toStringAsFixed(1)}%';
  }

  /// Moves a level, keeping take-profit on the winning side of entry and
  /// stop-loss on the losing side.
  void _nudge({required bool takeProfit, required int dir}) {
    HapticFeedback.selectionClick();
    setState(() {
      final winAbove = _long;
      if (takeProfit) {
        final next = _tp + dir * _step;
        if (winAbove ? next > _d.entry : next < _d.entry) _tp = next;
      } else {
        final next = _sl + dir * _step;
        if (winAbove ? next < _d.entry : next > _d.entry) _sl = next;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.position;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.92;
    const gap = SizedBox(height: VistaSpace.xxl);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          VistaSpace.gutter,
          VistaSpace.lg,
          VistaSpace.gutter,
          bottomInset > 0 ? bottomInset : 34,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: VistaColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            gap,
            Row(
              children: [
                _d.avatar != null
                    ? VistaIcon(_d.avatar!, size: 36)
                    : SizedBox.square(
                        dimension: 36,
                        child: FittedBox(
                          child: VistaListRow.initial(p.initial ?? '?'),
                        ),
                      ),
                const SizedBox(width: VistaSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title, style: VistaType.tab),
                      Text(
                        '${p.side.label} ${p.leverage}x · opened ${_d.opened}',
                        style: VistaType.bodyRegular.copyWith(
                          color: VistaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            gap,
            Text('Unrealised P/L', style: VistaType.subheadMuted),
            const SizedBox(height: 3),
            Text(_d.pnl, style: VistaType.display.copyWith(color: p.pnlColor)),
            const SizedBox(height: 3),
            Row(
              children: [
                Text(
                  p.pnlPercent,
                  style: VistaType.bodyMedium.copyWith(color: p.pnlColor),
                ),
                const SizedBox(width: VistaSpace.xs),
                Text(_d.size, style: VistaType.bodyMedium),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                // The live price keeps cents even when levels don't.
                // The market's one live price.
                ValueListenableBuilder(
                  valueListenable: MarketPrices.of(_d.symbol),
                  builder: (context, price, _) => Text(
                    '${_d.symbol} ${formatUsd(price, decimals: _d.decimals < 2 ? 2 : _d.decimals)}',
                    style: VistaType.body,
                  ),
                ),
                const SizedBox(width: VistaSpace.sm),
                Text('· entry ${_usd(_d.entry)}', style: VistaType.bodyRegular),
              ],
            ),
            gap,
            SizedBox(
              height: 180,
              child: _PositionChart(
                symbol: _d.symbol,
                span: _span,
                long: _long,
                entry: _d.entry,
                takeProfit: _tp,
                stopLoss: _sl,
                // The scale holds the levels as saved, so nudging one moves
                // its line rather than rescaling the chart.
                scaleLevels: (_d.takeProfit, _d.stopLoss),
                tpLabel: 'TP ${_usd(_tp)}',
                entryLabel: 'Entry ${_usd(_d.entry)}',
                slLabel: 'SL ${_usd(_sl)}',
              ),
            ),
            gap,
            VistaSpanSelector(
              labels: PortfolioMock.spans,
              selectedIndex: _span,
              onChanged: (i) => setState(() => _span = i),
            ),
            gap,
            _level(
              'Take profit',
              VistaColors.long,
              _tp,
              onMinus: () => _nudge(takeProfit: true, dir: -1),
              onPlus: () => _nudge(takeProfit: true, dir: 1),
            ),
            const SizedBox(height: VistaSpace.lg),
            const VistaHairline(),
            const SizedBox(height: VistaSpace.lg),
            _level('Entry', VistaColors.textMuted, _d.entry),
            const SizedBox(height: VistaSpace.lg),
            const VistaHairline(),
            const SizedBox(height: VistaSpace.lg),
            _level(
              'Stop loss',
              VistaColors.short,
              _sl,
              onMinus: () => _nudge(takeProfit: false, dir: -1),
              onPlus: () => _nudge(takeProfit: false, dir: 1),
            ),
            gap,
            // Close, or Edit once take profit / stop loss has changed.
            Semantics(
              button: true,
              label: _edited
                  ? 'Save take profit and stop loss'
                  : 'Close position',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _edited ? _saveEdits : _close,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _edited ? VistaColors.accent : VistaColors.short,
                    borderRadius: BorderRadius.circular(VistaRadius.pill),
                  ),
                  child: Text(
                    _edited ? 'Edit' : 'Close',
                    style: VistaType.headline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveEdits() {
    // Simulated only: the new levels live in this sheet.
    setState(() {
      _savedTp = _tp;
      _savedSl = _sl;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Take profit and stop loss updated (simulated)'),
        ),
      );
  }

  void _close() {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    // Simulated only: nothing is closed anywhere.
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Close position (simulated) — not in the demo yet'),
        ),
      );
  }

  Widget _level(
    String label,
    Color color,
    double value, {
    VoidCallback? onMinus,
    VoidCallback? onPlus,
  }) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: VistaType.body.copyWith(color: color)),
          ),
          Text(
            _usd(value),
            style: VistaType.subhead.copyWith(fontWeight: FontWeight.w400),
          ),
          const SizedBox(width: VistaSpace.md),
          // Entry has no steppers; an invisible copy keeps its price in line.
          Visibility(
            visible: onMinus != null,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_pct(value), style: VistaType.bodyRegular),
                // Two 44pt targets around the 30pt circles, overhanging the
                // 30pt row so levels keep Figma's spacing.
                SizedBox(
                  width: VistaSize.tapTarget * 2,
                  height: 30,
                  child: OverflowBox(
                    minHeight: VistaSize.tapTarget,
                    maxHeight: VistaSize.tapTarget,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VistaStepButton(
                          glyph: '−',
                          semanticLabel: 'Lower $label',
                          onPressed: onMinus ?? () {},
                        ),
                        VistaStepButton(
                          glyph: '+',
                          semanticLabel: 'Raise $label',
                          onPressed: onPlus ?? () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The market's price over the chosen [span], ending at its live price,
/// against the entry, take-profit and stop-loss lines on the same price
/// scale. The line is the app's line style split at entry: green on the
/// winning side, red on the losing side (flipped for a short); a dotted
/// line marks the current price. Simulated history.
class _PositionChart extends StatelessWidget {
  const _PositionChart({
    required this.symbol,
    required this.span,
    required this.long,
    required this.entry,
    required this.takeProfit,
    required this.stopLoss,
    required this.scaleLevels,
    required this.tpLabel,
    required this.entryLabel,
    required this.slLabel,
  });

  final String symbol;
  final int span;
  final bool long;
  final double entry;
  final double takeProfit;
  final double stopLoss;
  final (double, double) scaleLevels;
  final String tpLabel;
  final String entryLabel;
  final String slLabel;

  /// Where the window starts relative to today's price, per span (1h, 4h,
  /// 1D, 1W, 1M); All starts at entry. Mock.
  static const _spanMoves = [0.002, -0.004, 0.012, 0.035, 0.07];

  /// Lines stay inside the chart with room for their labels.
  static const double _minY = 4;
  static const double _maxY = 176;

  @override
  Widget build(BuildContext context) {
    final label = VistaType.label;
    const move = Duration(milliseconds: 180);
    final base = MarketPrices.base(symbol);
    final history = bridgeSeries(
      '$symbol/$span',
      span >= _spanMoves.length ? entry : base * (1 - _spanMoves[span]),
      base,
    );
    return ValueListenableBuilder(
      valueListenable: MarketPrices.of(symbol),
      builder: (context, live, _) {
        final series = endAt(history, live);
        // One price scale for the line and the levels, with some air.
        final all = [...series, entry, scaleLevels.$1, scaleLevels.$2];
        final lo = all.reduce(math.min);
        final hi = all.reduce(math.max);
        final pad = (hi - lo) * 0.06;
        double y(double price) {
          final f = (price - (lo - pad)) / ((hi + pad) - (lo - pad));
          return (_maxY - f * (_maxY - _minY)).clamp(_minY, _maxY);
        }

        final entryY = y(entry);
        final nowY = y(live);
        final winning = long ? live >= entry : live <= entry;
        return LayoutBuilder(
          builder: (context, c) {
            final sx = c.maxWidth / 360;
            final sy = c.maxHeight / 403;
            final points = [
              for (var k = 0; k < series.length; k++)
                Offset(k / (series.length - 1) * 360, y(series[k]) / sy),
            ];

            // A dotted level line with its label: below the line when it's
            // in the top half, above it in the bottom half.
            List<Widget> level(
              double lineY,
              String asset,
              String text,
              Color tone,
            ) {
              final below = lineY < entryY;
              return [
                AnimatedPositioned(
                  duration: move,
                  curve: Curves.easeOut,
                  left: 0,
                  width: c.maxWidth,
                  top: lineY - 1.5,
                  height: 1.5,
                  child: SvgPicture.asset(asset, fit: BoxFit.fill),
                ),
                AnimatedPositioned(
                  duration: move,
                  curve: Curves.easeOut,
                  left: 0,
                  top: below ? lineY + 3 : lineY - 16,
                  child: Text(text, style: label.copyWith(color: tone)),
                ),
              ];
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: LevelLine(entryY, VistaColors.textMuted),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: ReplayLinePainter(
                      points: points,
                      entryY: entryY / sy,
                      revealX: null,
                      latticeShift: 0,
                      sx: sx,
                      sy: sy,
                      screenLattice: true,
                      invert: !long,
                    ),
                  ),
                ),
                ...level(
                  y(takeProfit),
                  VistaAssets.positionTpLine,
                  tpLabel,
                  VistaColors.long,
                ),
                ...level(
                  y(stopLoss),
                  VistaAssets.positionSlLine,
                  slLabel,
                  VistaColors.short,
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: LevelLine(
                      nowY,
                      winning ? VistaColors.long : VistaColors.short,
                      dotted: true,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: entryY + 3,
                  child: Text(
                    entryLabel,
                    style: label.copyWith(color: VistaColors.textMuted),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
