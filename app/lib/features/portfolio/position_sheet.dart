import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/design_system.dart';
import '../live/live_feed.dart';
import 'portfolio_mock.dart';

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
                Text(
                  '${_d.symbol} ${formatUsd(_d.price, decimals: _d.decimals < 2 ? 2 : _d.decimals)}',
                  style: VistaType.body,
                ),
                const SizedBox(width: VistaSpace.sm),
                Text('· entry ${_usd(_d.entry)}', style: VistaType.bodyRegular),
              ],
            ),
            gap,
            SizedBox(
              height: 180,
              child: _PositionChart(
                long: _long,
                tp: 'TP ${_usd(_tp)}',
                entry: 'Entry ${_usd(_d.entry)}',
                sl: 'SL ${_usd(_sl)}',
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
            Semantics(
              button: true,
              label: 'Close position',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: VistaColors.short,
                    borderRadius: BorderRadius.circular(VistaRadius.pill),
                  ),
                  child: Text('Close', style: VistaType.headline),
                ),
              ),
            ),
          ],
        ),
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

/// Price since entry against the take-profit, entry and stop-loss lines
/// (static Figma vectors on a 370×180 box; x stretches). On a short the
/// stop-loss sits above entry and take-profit below.
class _PositionChart extends StatelessWidget {
  const _PositionChart({
    required this.long,
    required this.tp,
    required this.entry,
    required this.sl,
  });

  final bool long;
  final String tp;
  final String entry;
  final String sl;

  @override
  Widget build(BuildContext context) {
    final label = VistaType.label;
    return LayoutBuilder(
      builder: (context, c) {
        final sx = c.maxWidth / 370;
        Widget layer(
          String asset,
          double left,
          double top,
          double w,
          double h,
        ) => Positioned(
          left: left * sx,
          top: top,
          width: w * sx,
          height: h,
          child: SvgPicture.asset(asset, fit: BoxFit.fill),
        );
        final (topLine, topLabel, topColor) = long
            ? (VistaAssets.positionTpLine, tp, VistaColors.long)
            : (VistaAssets.positionSlLine, sl, VistaColors.short);
        final (bottomLine, bottomLabel, bottomColor) = long
            ? (VistaAssets.positionSlLine, sl, VistaColors.short)
            : (VistaAssets.positionTpLine, tp, VistaColors.long);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            layer(VistaAssets.positionLattice, 0, 0, 370, 180),
            layer(topLine, 0, 21.31 - 1.5, 370, 1.5),
            layer(bottomLine, 0, 158.69 - 1.5, 370, 1.5),
            layer(VistaAssets.marketBaseline, 0, 103.74 - 1, 370, 1),
            layer(VistaAssets.positionClipAbove, -5, 0, 380, 103.737),
            layer(VistaAssets.positionClipBelow, -5, 103.74, 380, 82.263),
            Positioned(
              left: c.maxWidth - 6.5,
              top: 34.85,
              child: const VistaIcon(VistaAssets.marketLiveHalo, size: 13),
            ),
            Positioned(
              left: c.maxWidth - 3.5,
              top: 37.85,
              child: const VistaIcon(VistaAssets.markerLive, size: 7),
            ),
            Positioned(
              left: 0,
              top: 24.31,
              child: Text(topLabel, style: label.copyWith(color: topColor)),
            ),
            Positioned(
              left: 0,
              top: 106.74,
              child: Text(
                entry,
                style: label.copyWith(color: VistaColors.textMuted),
              ),
            ),
            Positioned(
              left: 0,
              top: 142.69,
              child: Text(
                bottomLabel,
                style: label.copyWith(color: bottomColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
