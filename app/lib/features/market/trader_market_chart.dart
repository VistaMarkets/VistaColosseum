import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/design_system.dart';

/// One exported chart state, in Figma units. The plot is 320 wide with price
/// labels in the 50pt gutter to its right.
class _ChartSpec {
  const _ChartSpec({
    required this.height,
    required this.lattice,
    required this.above,
    required this.aboveHeight,
    required this.below,
    required this.belowHeight,
    required this.baselineY,
    required this.lastY,
    required this.axisY,
    required this.grid,
  });

  final double height;
  final String lattice;
  final String above;
  final double aboveHeight;
  final String below;
  final double belowHeight;
  final double baselineY;
  final double lastY;
  final double axisY;

  /// Gridline y positions with their price label (null = unlabelled).
  final List<(double, String?)> grid;
}

const _tall = _ChartSpec(
  height: 506,
  lattice: VistaAssets.tmTallLattice,
  above: VistaAssets.tmTallClipAbove,
  aboveHeight: 382.501,
  below: VistaAssets.tmTallClipBelow,
  belowHeight: 111.499,
  baselineY: 376.5,
  lastY: 12.81,
  axisY: 486,
  grid: [
    (467, '0.4175'),
    (417, '0.4200'),
    (366, null),
    (316, '0.4250'),
    (265, '0.4275'),
    (215, '0.4300'),
    (164, '0.4325'),
    (114, '0.4350'),
    (63, '0.4375'),
    (13, null),
  ],
);

const _short = _ChartSpec(
  height: 196,
  lattice: VistaAssets.tmShortLattice,
  above: VistaAssets.tmShortClipAbove,
  aboveHeight: 141.058,
  below: VistaAssets.tmShortClipBelow,
  belowHeight: 42.942,
  baselineY: 135.06,
  lastY: 12.27,
  axisY: 176,
  grid: [
    (149, '0.4200'),
    (115, '0.4250'),
    (80, '0.4300'),
    (46, '0.4350'),
    (12, null),
  ],
);

const _plot = 320.0;

/// Time-axis ticks: tick x, label x, label.
const _ticks = [
  (24.92, 11.0, '00:00'),
  (104.67, 91.0, '04:00'),
  (184.41, 170.0, '08:00'),
  (264.16, 251.0, '12:00'),
];

/// Market-cap price chart for a trader market. [collapse] 0 shows the tall
/// "chart open" export, 1 the short "panels up" one; in between both are
/// drawn at the current height and crossfaded.
class TraderMarketChart extends StatelessWidget {
  const TraderMarketChart({super.key, required this.collapse});

  final double collapse;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = c.biggest;
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (collapse < 1)
                Opacity(
                  opacity: 1 - collapse,
                  child: _SpecLayers(spec: _tall, size: size),
                ),
              if (collapse > 0)
                Opacity(
                  opacity: collapse,
                  child: _SpecLayers(spec: _short, size: size),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SpecLayers extends StatelessWidget {
  const _SpecLayers({required this.spec, required this.size});

  final _ChartSpec spec;
  final Size size;

  @override
  Widget build(BuildContext context) {
    // Price axis only as wide as its widest tag, plus the edge margin, so
    // the plot runs from the left edge right up to it.
    final tagW =
        (TextPainter(
          text: TextSpan(text: '0.4400', style: VistaType.micro),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout()).width +
        8;
    final plotW = size.width - (4 + tagW + 6);
    final sx = plotW / _plot;
    final sy = size.height / spec.height;
    double y(double v) => v * sy;
    final axisLabel = VistaType.micro.copyWith(
      fontWeight: FontWeight.w500,
      color: VistaColors.textSecondary,
    );

    Widget layer(String asset, double left, double top, double w, double h) =>
        Positioned(
          left: left * sx,
          top: top,
          width: w * sx,
          height: h,
          child: SvgPicture.asset(asset, fit: BoxFit.fill),
        );

    Widget tag(String text, double lineY, Color bg, Color fg) => Positioned(
      left: plotW + 4,
      top: y(lineY) - 7.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text, style: VistaType.micro.copyWith(color: fg)),
      ),
    );

    return SizedBox.fromSize(
      size: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (gy, label) in spec.grid) ...[
            Positioned(
              left: 0,
              top: y(gy),
              width: plotW,
              height: 1,
              child: const ColoredBox(color: Color(0x0DFFFFFF)),
            ),
            if (label != null)
              Positioned(
                left: plotW + 8,
                top: y(gy) - 6,
                child: Text(label, style: axisLabel),
              ),
          ],
          layer(spec.lattice, 0, 0, _plot, size.height),
          layer(VistaAssets.tmBaseline, 0, y(spec.baselineY) - 1, _plot, 1),
          layer(spec.above, -5, -6, 330, y(spec.aboveHeight)),
          layer(spec.below, -5, y(spec.baselineY), 330, y(spec.belowHeight)),
          tag(
            '0.4220',
            spec.baselineY,
            VistaColors.surfaceRaised,
            VistaColors.textPrimary,
          ),
          layer(VistaAssets.tmLastPrice, 0, y(spec.lastY) - 1, _plot, 1),
          tag('0.4400', spec.lastY, VistaColors.long, VistaColors.ink),
          Positioned(
            left: plotW - 13,
            top: y(spec.lastY) - 7,
            child: const VistaIcon(VistaAssets.markerLiveHalo, size: 14),
          ),
          Positioned(
            left: plotW - 9.5,
            top: y(spec.lastY) - 3.5,
            child: const VistaIcon(VistaAssets.markerLive, size: 7),
          ),
          // Time axis.
          Positioned(
            left: 0,
            top: y(spec.axisY),
            width: plotW,
            height: 1,
            child: const ColoredBox(color: VistaColors.hairline),
          ),
          for (final (tickX, labelX, text) in _ticks) ...[
            Positioned(
              left: tickX * sx,
              top: y(spec.axisY),
              width: 1,
              height: 4,
              child: const ColoredBox(color: Color(0x26FFFFFF)),
            ),
            Positioned(
              left: labelX * sx,
              top: y(spec.axisY) + 5,
              child: Text(text, style: axisLabel),
            ),
          ],
        ],
      ),
    );
  }
}
