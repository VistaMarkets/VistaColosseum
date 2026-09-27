import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/design_system.dart';

/// One hollow-candle bar in Figma canvas units (402×545 box): wick x, wick
/// top and height, body top and height, and direction.
typedef _Candle = (
  double x,
  double wickTop,
  double wickH,
  double bodyTop,
  double bodyH,
  bool up,
);

/// Candles as drawn in Figma 206:110 ("hollow candles"), 15m BTC.
const List<_Candle> _candles = [
  (18, 296.7, 120.596, 343.61, 58.948, false),
  (26, 365.4, 100.269, 402.56, 35.968, false),
  (35, 400.21, 99.787, 438.53, 23.002, false),
  (43, 426.34, 67.585, 461.22, 1.5, true),
  (51, 418.67, 61.611, 431, 30.215, true),
  (60, 377.11, 56.64, 412.67, 18.331, true),
  (68, 373.12, 86.545, 396.96, 15.711, true),
  (76, 361.51, 61.592, 367.77, 29.194, true),
  (85, 290.86, 109.708, 325.94, 41.832, true),
  (93, 275.38, 96.829, 321.85, 4.087, true),
  (101, 304.76, 78.054, 321.85, 18.315, false),
  (109, 332.39, 45.618, 340.16, 22.681, false),
  (118, 347.82, 74.951, 362.84, 12.176, false),
  (126, 335.97, 83.777, 373.12, 1.896, true),
  (134, 359.19, 74.672, 373.12, 32.175, false),
  (143, 366.85, 48.275, 388.33, 16.973, true),
  (151, 324.87, 82.077, 327.66, 60.662, true),
  (159, 293.81, 81.951, 327.66, 1.5, false),
  (168, 302.6, 46.734, 311.04, 17.634, true),
  (176, 292.47, 47.782, 311.04, 7.614, false),
  (184, 291.56, 60.638, 318.65, 2.267, false),
  (192, 274.73, 82.623, 320.92, 13.112, false),
  (201, 246.03, 120.322, 278.38, 55.644, true),
  (209, 234.87, 78.615, 260.6, 17.786, true),
  (217, 176.38, 120.298, 196.6, 64.003, true),
  (226, 166.7, 58.92, 196.6, 11.159, false),
  (234, 187.81, 62.914, 207.76, 2.482, false),
  (242, 147.35, 104.627, 153, 57.232, true),
  (251, 132.28, 58.639, 153, 30.089, false),
  (259, 132.34, 92.036, 183.09, 30.072, false),
  (267, 185.54, 50.912, 192.89, 20.274, true),
  (275, 169.91, 69.955, 176.93, 15.967, true),
  (284, 83.74, 138.281, 129.12, 47.808, true),
  (292, 40, 103.15, 78.78, 50.34, true),
  (300, 66.13, 64.144, 78.78, 47.62, false),
  (309, 94.97, 91.807, 126.4, 48.592, false),
  (317, 117.91, 92.11, 142.84, 32.15, true),
  (325, 97.9, 79.698, 142.84, 22.776, false),
  (334, 120.05, 59.532, 165.62, 7.939, false),
  (342, 168.75, 51.317, 168.9, 4.65, true),
];

const Size _canvas = Size(402, 545);
const _hGrid = [31.0, 104.0, 177.0, 250.0, 323.0, 396.0, 469.0];
const _vGrid = [51.0, 118.0, 184.0, 251.0, 317.0];
const _priceLabels = [
  (469.0, '67,000'),
  (396.0, '67,100'),
  (323.0, '67,200'),
  (250.0, '67,300'),
  (104.0, '67,500'),
  (31.0, '67,600'),
];
const _times = ['06:00', '08:00', '10:00', '12:00', '14:00'];
const double _lastY = 169;
const double _axisY = 508;

/// Hollow-candle price chart for an asset (Figma "TradeChart"). Drawn from
/// the design's candle geometry and stretched to the available size; labels
/// and the price tag keep their pixel size.
class CandleChart extends StatelessWidget {
  const CandleChart({super.key, required this.lastPrice});

  /// Price tag on the live line, e.g. "67,412".
  final String lastPrice;

  @override
  Widget build(BuildContext context) {
    final axis = VistaType.micro.copyWith(
      fontWeight: FontWeight.w500,
      color: VistaColors.textSecondary,
    );
    return LayoutBuilder(
      builder: (context, c) {
        final sx = c.maxWidth / _canvas.width;
        // The time axis keeps its 37pt strip at the bottom (as in Figma);
        // the price area above it stretches.
        final sy = (c.maxHeight - (_canvas.height - _axisY)) / _axisY;
        // Drop every other price label when rows get tight.
        final every = 73 * sy < 18 ? 2 : 1;
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _CandlePainter(sx, sy)),
              ),
              Positioned(
                left: 14 * sx,
                top: _lastY * sy - 1,
                width: 336 * sx,
                height: 1,
                child: SvgPicture.asset(
                  VistaAssets.tradeLastPrice,
                  fit: BoxFit.fill,
                ),
              ),
              for (var i = 0; i < _priceLabels.length; i += every)
                Positioned(
                  left: 356 * sx,
                  top: _priceLabels[i].$1 * sy - 6,
                  child: Text(_priceLabels[i].$2, style: axis),
                ),
              Positioned(
                left: 350 * sx,
                top: _lastY * sy - 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: VistaColors.long,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    lastPrice,
                    style: VistaType.micro.copyWith(color: VistaColors.ink),
                  ),
                ),
              ),
              for (var i = 0; i < _vGrid.length; i++)
                Positioned(
                  left: _vGrid[i] * sx - 20,
                  width: 40,
                  top: _axisY * sy + 8,
                  child: Text(
                    _times[i],
                    textAlign: TextAlign.center,
                    style: axis,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CandlePainter extends CustomPainter {
  _CandlePainter(this.sx, this.sy);

  final double sx;
  final double sy;

  @override
  void paint(Canvas canvas, Size size) {
    final vGrid = Paint()..color = const Color(0x0AFFFFFF);
    final hGrid = Paint()..color = const Color(0x0DFFFFFF);
    for (final x in _vGrid) {
      canvas.drawRect(Rect.fromLTWH(x * sx, 20 * sy, 1, 488 * sy), vGrid);
    }
    for (final y in _hGrid) {
      canvas.drawRect(Rect.fromLTWH(14 * sx, y * sy, 338 * sx, 1), hGrid);
    }

    final up = Paint()..color = VistaColors.long;
    final down = Paint()..color = VistaColors.short;
    final hollow = Paint()..color = VistaColors.background;
    final outline = Paint()
      ..color = VistaColors.long
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final (x, wickTop, wickH, bodyTop, bodyH, isUp) in _candles) {
      final colour = isUp ? up : down;
      canvas.drawRect(
        Rect.fromLTWH(x * sx, wickTop * sy, 1, wickH * sy),
        colour,
      );
      // Bodies keep a 1.5pt minimum so dojis stay visible.
      final h = (bodyH * sy).clamp(1.5, double.infinity);
      final body = RRect.fromRectAndRadius(
        Rect.fromLTWH((x - 2) * sx, bodyTop * sy, 5 * sx, h),
        const Radius.circular(1),
      );
      if (isUp) {
        canvas.drawRRect(body, hollow);
        canvas.drawRRect(body.deflate(0.5), outline);
      } else {
        canvas.drawRRect(body, colour);
      }
    }

    // Time axis.
    final rule = Paint()..color = VistaColors.hairline;
    canvas.drawRect(Rect.fromLTWH(14 * sx, _axisY * sy, 338 * sx, 1), rule);
    final tick = Paint()..color = const Color(0x26FFFFFF);
    for (final x in _vGrid) {
      canvas.drawRect(Rect.fromLTWH(x * sx, _axisY * sy, 1, 4), tick);
    }
  }

  @override
  bool shouldRepaint(_CandlePainter old) => old.sx != sx || old.sy != sy;
}
