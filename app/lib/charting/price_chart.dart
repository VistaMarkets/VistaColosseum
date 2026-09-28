import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design_system/design_system.dart';
import 'candle.dart';
import 'price_scale.dart';
import 'time_marks.dart';

enum PlotMode { candles, line }

/// A price chart for a candle series: hollow candles (or a line), price
/// gridlines on round numbers, time labels on clock boundaries and a tag on
/// the last price. Laid out in proportion to the Figma "TradeChart" frame
/// (402×545) so it fits any phone width; the time strip keeps a fixed height.
class PriceChart extends StatelessWidget {
  const PriceChart({
    super.key,
    required this.candles,
    required this.period,
    this.revision = 0,
    this.mode = PlotMode.candles,
  });

  final List<Candle> candles;

  /// Time each candle covers; decides how the time axis is written.
  final Duration period;

  /// Changes whenever [candles] does, so the painter knows to redraw.
  final int revision;
  final PlotMode mode;

  // Figma frame geometry, as fractions of its 402pt width / 508pt plot.
  static const double _frameW = 402;
  static const double _plotLeft = 14 / _frameW;
  static const double _plotRight = 352 / _frameW;
  static const double _labelLeft = 356 / _frameW;
  static const double _tagLeft = 350 / _frameW;
  static const double _plotTop = 20 / 508;

  /// Strip under the plot for the time labels.
  static const double timeStrip = 37;

  @override
  Widget build(BuildContext context) {
    final axis = VistaType.micro.copyWith(
      fontWeight: FontWeight.w500,
      color: VistaColors.textSecondary,
    );
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final axisY = math.max(0.0, c.maxHeight - timeStrip);
        final plot = Rect.fromLTRB(
          w * _plotLeft,
          axisY * _plotTop,
          w * _plotRight,
          axisY,
        );
        if (candles.isEmpty || plot.height < 8) return const SizedBox.shrink();

        final scale = PriceScale.fit(candles);
        final (ticks, step) = roundTicks(scale.min, scale.max);
        final last = candles.last;
        final lastY = scale.yFor(last.close, plot);
        final slot = plot.width / candles.length;
        final marks = timeMarks([for (final k in candles) k.time], slot);
        final tickDecimals = decimalsFor(step);
        final tagDecimals = last.close >= 1000
            ? 0
            : last.close >= 1
            ? 2
            : 4;
        // Drop every other price label when rows get tight, and any that
        // would sit under the last-price tag.
        final gap = ticks.length > 1
            ? scale.yFor(ticks[0], plot) - scale.yFor(ticks[1], plot)
            : double.infinity;
        final every = gap < 18 ? 2 : 1;

        return ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _PlotPainter(
                      candles: candles,
                      revision: revision,
                      mode: mode,
                      scale: scale,
                      plot: plot,
                      ticks: ticks,
                      marks: marks,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: plot.left,
                top: lastY - 1,
                width: w * (_tagLeft - _plotLeft),
                height: 1,
                child: SvgPicture.asset(
                  VistaAssets.tradeLastPrice,
                  fit: BoxFit.fill,
                ),
              ),
              for (var i = 0; i < ticks.length; i += every)
                if ((scale.yFor(ticks[i], plot) - lastY).abs() > 12)
                  Positioned(
                    left: w * _labelLeft,
                    top: scale.yFor(ticks[i], plot) - 6,
                    child: Text(
                      groupDigits(ticks[i], tickDecimals),
                      style: axis,
                    ),
                  ),
              Positioned(
                left: w * _tagLeft,
                top: lastY - 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: last.rising ? VistaColors.long : VistaColors.short,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    groupDigits(last.close, tagDecimals),
                    style: VistaType.micro.copyWith(color: VistaColors.ink),
                  ),
                ),
              ),
              for (final i in marks)
                Positioned(
                  left: (plot.left + slot * (i + 0.5) - 24).clamp(0.0, w - 48),
                  width: 48,
                  top: axisY + 8,
                  child: Text(
                    timeLabel(candles[i].time, period),
                    textAlign: TextAlign.center,
                    maxLines: 1,
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

class _PlotPainter extends CustomPainter {
  _PlotPainter({
    required this.candles,
    required this.revision,
    required this.mode,
    required this.scale,
    required this.plot,
    required this.ticks,
    required this.marks,
  });

  final List<Candle> candles;
  final int revision;
  final PlotMode mode;
  final PriceScale scale;
  final Rect plot;
  final List<double> ticks;
  final List<int> marks;

  @override
  void paint(Canvas canvas, Size size) {
    final slot = plot.width / candles.length;
    double x(int i) => plot.left + slot * (i + 0.5);
    double y(double p) => scale.yFor(p, plot);

    // Grid: a rule per price tick, a column per time label.
    final rows = Paint()..color = const Color(0x0DFFFFFF);
    for (final t in ticks) {
      canvas.drawRect(Rect.fromLTWH(plot.left, y(t), plot.width, 1), rows);
    }
    final cols = Paint()..color = const Color(0x0AFFFFFF);
    for (final i in marks) {
      canvas.drawRect(Rect.fromLTWH(x(i), plot.top, 1, plot.height), cols);
    }

    if (mode == PlotMode.candles) {
      _candles(canvas, slot, x, y);
    } else {
      _line(canvas, x, y);
    }

    // Time axis rule with a small tick under each label.
    canvas.drawRect(
      Rect.fromLTWH(plot.left, plot.bottom, plot.width, 1),
      Paint()..color = VistaColors.hairline,
    );
    final tick = Paint()..color = const Color(0x26FFFFFF);
    for (final i in marks) {
      canvas.drawRect(Rect.fromLTWH(x(i), plot.bottom, 1, 4), tick);
    }
  }

  void _candles(
    Canvas canvas,
    double slot,
    double Function(int) x,
    double Function(double) y,
  ) {
    final bodyW = math.max(1.5, slot * 0.6);
    final up = Paint()..color = VistaColors.long;
    final down = Paint()..color = VistaColors.short;
    final hollow = Paint()..color = VistaColors.background;
    final outline = Paint()
      ..color = VistaColors.long
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < candles.length; i++) {
      final k = candles[i];
      final cx = x(i);
      canvas.drawRect(
        Rect.fromLTRB(cx - 0.5, y(k.high), cx + 0.5, y(k.low)),
        k.rising ? up : down,
      );
      // Rising candles are hollow; bodies keep 1.5pt so dojis stay visible.
      final top = y(math.max(k.open, k.close));
      final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - bodyW / 2,
          top,
          bodyW,
          math.max(1.5, y(math.min(k.open, k.close)) - top),
        ),
        const Radius.circular(1),
      );
      if (k.rising) {
        canvas.drawRRect(body, hollow);
        canvas.drawRRect(body.deflate(0.5), outline);
      } else {
        canvas.drawRRect(body, down);
      }
    }
  }

  void _line(Canvas canvas, double Function(int) x, double Function(double) y) {
    final colour = candles.last.close >= candles.first.open
        ? VistaColors.long
        : VistaColors.short;
    final path = Path()..moveTo(x(0), y(candles.first.close));
    for (var i = 1; i < candles.length; i++) {
      path.lineTo(x(i), y(candles[i].close));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    final head = Offset(x(candles.length - 1), y(candles.last.close));
    canvas.drawCircle(head, 5, Paint()..color = VistaColors.background);
    canvas.drawCircle(head, 3, Paint()..color = colour);
  }

  @override
  bool shouldRepaint(_PlotPainter old) =>
      old.revision != revision ||
      !identical(old.candles, candles) ||
      old.mode != mode ||
      old.plot != plot ||
      old.scale.min != scale.min ||
      old.scale.max != scale.max;
}
