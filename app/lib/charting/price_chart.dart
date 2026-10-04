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
/// the last price. The plot runs from the left edge up to the price axis,
/// which is only as wide as its widest label or tag, so there is no dead
/// space either side; the time strip keeps a fixed height.
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

  /// Headroom above the plot, as a fraction of its height (Figma 20 / 508).
  static const double _plotTop = 20 / 508;

  /// Gap between the plot and a tag; tag text inset; room kept at the
  /// screen edge so axis text never reads as clipped.
  static const double _tagGap = 2;
  static const double _tagPad = 5;
  static const double _edge = 6;

  /// Room at the end of a line for the live dot's halo.
  static const double _headRoom = 7;

  /// Horizontal centre of point [i] of [n]: candles sit in equal slots; a
  /// line runs from the plot's left edge to just short of its right one.
  static double xAt(int i, int n, Rect plot, PlotMode mode) {
    if (mode == PlotMode.line) {
      if (n < 2) return plot.right - _headRoom;
      return plot.left + i * (plot.width - _headRoom) / (n - 1);
    }
    final slot = plot.width / n;
    return plot.left + slot * (i + 0.5);
  }

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
        if (candles.isEmpty || axisY < 8) return const SizedBox.shrink();

        final scale = PriceScale.fit(candles);
        final (ticks, step) = roundTicks(scale.min, scale.max);
        final last = candles.last;
        final tagDecimals = last.close >= 1000
            ? 0
            : last.close >= 1
            ? 2
            : 4;
        // Sub-dollar prices keep the tag's four places on the axis too.
        final tickDecimals = last.close < 1
            ? math.max(decimalsFor(step), tagDecimals)
            : decimalsFor(step);
        final tickText = [for (final t in ticks) groupDigits(t, tickDecimals)];
        final tagStyle = VistaType.micro;
        final scaler = MediaQuery.textScalerOf(context);
        double widthOf(String text, TextStyle style) => (TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout()).width;
        // The axis is as wide as its widest text (labels share the tags'
        // text inset), plus the gap to the plot and the edge margin.
        final textW = [
          for (final t in tickText) widthOf(t, axis),
          widthOf(groupDigits(last.close, tagDecimals), tagStyle),
          widthOf(groupDigits(candles.first.open, tagDecimals), tagStyle),
        ].reduce(math.max);
        final gutter = _tagGap + _tagPad * 2 + textW + _edge;
        final plot = Rect.fromLTRB(0, axisY * _plotTop, w - gutter, axisY);
        final lastY = scale.yFor(last.close, plot);
        final slot = plot.width / candles.length;
        final marks = timeMarks([for (final k in candles) k.time], slot);
        double xAt(int i) => PriceChart.xAt(i, candles.length, plot, mode);
        // Drop every other price label when rows get tight, and any that
        // would sit under the last-price tag.
        final gap = ticks.length > 1
            ? scale.yFor(ticks[0], plot) - scale.yFor(ticks[1], plot)
            : double.infinity;
        final every = gap < 18 ? 2 : 1;
        final line = mode == PlotMode.line;
        // Line mode reads against where the window opened: green above,
        // red below, as on the other line charts in the app.
        final open = candles.first.open;
        final baseY = scale.yFor(open, plot);
        final up = line ? last.close >= open : last.rising;
        final showBaseTag = line && (baseY - lastY).abs() > 16;
        bool clearOfTags(double ty) =>
            (ty - lastY).abs() > 12 &&
            !(showBaseTag && (ty - baseY).abs() < 12);

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
              // Line mode paints its own last-price line in the side colour.
              if (!line)
                Positioned(
                  left: plot.left,
                  top: lastY - 1,
                  width: plot.width + _tagGap,
                  height: 1,
                  child: SvgPicture.asset(
                    VistaAssets.tradeLastPrice,
                    fit: BoxFit.fill,
                  ),
                ),
              for (var i = 0; i < ticks.length; i += every)
                if (clearOfTags(scale.yFor(ticks[i], plot)))
                  Positioned(
                    left: plot.right + _tagGap + _tagPad,
                    top: scale.yFor(ticks[i], plot) - 6,
                    child: Text(tickText[i], style: axis),
                  ),
              if (showBaseTag)
                _tag(
                  plot.right + _tagGap,
                  baseY,
                  groupDigits(open, tagDecimals),
                  VistaColors.surfaceRaised,
                  VistaColors.textPrimary,
                ),
              _tag(
                plot.right + _tagGap,
                lastY,
                groupDigits(last.close, tagDecimals),
                up ? VistaColors.long : VistaColors.short,
                VistaColors.ink,
              ),
              for (final i in marks)
                Positioned(
                  left: (xAt(i) - 24).clamp(0.0, w - 48),
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

Widget _tag(double left, double y, String text, Color bg, Color fg) =>
    Positioned(
      left: left,
      top: y - 8,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PriceChart._tagPad,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text, style: VistaType.micro.copyWith(color: fg)),
      ),
    );

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
    double x(int i) => PriceChart.xAt(i, candles.length, plot, mode);
    double y(double p) => scale.yFor(p, plot);

    // Grid: a rule per price tick, a column per time label.
    final rows = Paint()..color = const Color(0x0DFFFFFF);
    for (final t in ticks) {
      canvas.drawRect(Rect.fromLTWH(plot.left, y(t), plot.width, 1), rows);
    }
    final cols = Paint()..color = const Color(0x0AFFFFFF);
    for (final i in mode == PlotMode.candles ? marks : const <int>[]) {
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

  /// The app's line chart style (as on the trader market chart): a 3pt
  /// line and 18% fill, green above the window open and red below it, a dot
  /// lattice inside the fill, a dashed baseline at the open, a dashed
  /// last-price line and the live dot with its halo.
  void _line(Canvas canvas, double Function(int) x, double Function(double) y) {
    final points = [
      for (var i = 0; i < candles.length; i++)
        Offset(x(i), y(candles[i].close)),
    ];
    final baseY = y(candles.first.open).clamp(plot.top, plot.bottom);
    final path = Path()..addPolygon(points, false);
    final under = Path.from(path)
      ..lineTo(points.last.dx, plot.bottom)
      ..lineTo(points.first.dx, plot.bottom)
      ..close();
    final over = Path.from(path)
      ..lineTo(points.last.dx, plot.top)
      ..lineTo(points.first.dx, plot.top)
      ..close();

    // Dot lattice: 1pt dots on a 14pt grid, only inside the filled area
    // between the line and the baseline (above it where the line is up,
    // below it where the line is down).
    final above = Rect.fromLTRB(0, 0, plot.right + 6, baseY);
    final below = Rect.fromLTRB(0, baseY, plot.right + 6, plot.bottom + 6);
    final dot = Paint()..color = const Color(0x2EFFFFFF);
    for (final (area, band) in [(under, above), (over, below)]) {
      canvas
        ..save()
        ..clipRect(band)
        ..clipPath(area);
      for (var gx = plot.left + 7; gx < plot.right; gx += 14) {
        for (var gy = plot.top + 5; gy < plot.bottom; gy += 14) {
          canvas.drawCircle(Offset(gx, gy), 1, dot);
        }
      }
      canvas.restore();
    }

    _dashed(canvas, baseY, VistaColors.textMuted, 2, 3);

    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Paint fill(Color c, double from, double to) =>
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              c.withValues(alpha: 0.18 * from),
              c.withValues(alpha: 0.18 * to),
            ],
          ).createShader(plot);

    // Above the open: green, filled down from the line.
    canvas
      ..save()
      ..clipRect(above)
      ..drawPath(under, fill(VistaColors.long, 1, 0))
      ..drawPath(path, stroke(VistaColors.long))
      ..restore();
    // Below it: red, filled up from the line.
    canvas
      ..save()
      ..clipRect(below)
      ..drawPath(over, fill(VistaColors.short, 0, 1))
      ..drawPath(path, stroke(VistaColors.short))
      ..restore();

    final head = points.last;
    final side = head.dy <= baseY ? VistaColors.long : VistaColors.short;
    _dashed(canvas, head.dy, side.withValues(alpha: 0.5), 3, 3);
    canvas
      ..drawCircle(head, 7, Paint()..color = side.withValues(alpha: 0.25))
      ..drawCircle(head, 3.5, Paint()..color = side);
  }

  void _dashed(Canvas canvas, double y, Color color, double dash, double gap) {
    final paint = Paint()..color = color;
    for (var dx = plot.left; dx < plot.right; dx += dash + gap) {
      canvas.drawRect(
        Rect.fromLTWH(dx, y - 0.5, math.min(dash, plot.right - dx), 1),
        paint,
      );
    }
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
