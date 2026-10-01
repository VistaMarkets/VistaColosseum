import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../design_system/design_system.dart';
import '../home/signal_replay_chart.dart';

/// What each time span covers, for "+$91 (0.73%) Last 24 hours".
const spanWindows = [
  'Past hour',
  'Past 4 hours',
  'Last 24 hours',
  'Past week',
  'Past month',
  'All time',
];

/// A repeatable walk of [n] values from [start] to [end]: a random walk
/// pinned to both ends (a Brownian bridge) over the straight drift. The
/// same [seed] always gives the same shape. Simulated history.
List<double> bridgeSeries(String seed, double start, double end, {int n = 48}) {
  final rng = math.Random(
    seed.codeUnits.fold<int>(11, (h, c) => (h * 31 + c) & 0x7fffffff),
  );
  double gaussian() {
    final u = 1 - rng.nextDouble();
    return math.sqrt(-2 * math.log(u)) *
        math.cos(2 * math.pi * rng.nextDouble());
  }

  final walk = <double>[0];
  for (var k = 1; k < n; k++) {
    walk.add(walk.last + gaussian());
  }
  final bridge = [
    for (var k = 0; k < n; k++) walk[k] - walk.last * k / (n - 1),
  ];
  final peak = bridge.map((v) => v.abs()).reduce(math.max);
  final move = end - start;
  final swing = math.max(move.abs() * 0.6, start.abs() * 0.0015);
  return [
    for (var k = 0; k < n; k++)
      start + move * k / (n - 1) + (peak == 0 ? 0 : bridge[k] / peak * swing),
  ];
}

/// Moves [series] so it ends at [live], easing the shift in along the way so
/// the history keeps its shape and only the recent end follows the feed.
List<double> endAt(List<double> series, double live) {
  final shift = live - series.last;
  final n = series.length;
  return [for (var k = 0; k < n; k++) series[k] + shift * k / (n - 1)];
}

/// Maps a price to its height on the shared 360×403 line canvas (y 24..379
/// is the plot band [ReplayLinePainter] fills over).
double canvasY(double v, double lo, double hi) {
  if (hi == lo) return 201.5;
  return 379 - (v - lo) / (hi - lo) * (379 - 24);
}

/// A line chart in the app's line style for a value over time: [focus]
/// green above its starting value and red below, with the dot lattice in
/// the fill; [muted] (if any) is a second series drawn as a quiet grey line
/// on its own scale behind it; a dashed line marks the start and a dotted
/// line the current value.
class SeriesChart extends StatelessWidget {
  const SeriesChart({super.key, required this.focus, this.muted});

  final List<double> focus;
  final List<double>? muted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final sx = c.maxWidth / 360;
        final sy = c.maxHeight / 403;
        List<Offset> pointsOf(List<double> s) {
          final lo = s.reduce(math.min);
          final hi = s.reduce(math.max);
          // A little air above and below the line.
          final pad = (hi - lo) * 0.12;
          return [
            for (var k = 0; k < s.length; k++)
              Offset(
                k / (s.length - 1) * 360,
                canvasY(s[k], lo - pad, hi + pad),
              ),
          ];
        }

        final points = pointsOf(focus);
        final startY = points.first.dy;
        final nowY = points.last.dy;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (muted != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _MutedLine(pointsOf(muted!), sx, sy),
                ),
              ),
            Positioned.fill(
              child: CustomPaint(
                painter: LevelLine(startY * sy, VistaColors.textMuted),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: ReplayLinePainter(
                  points: points,
                  entryY: startY,
                  revealX: null,
                  latticeShift: 0,
                  sx: sx,
                  sy: sy,
                  screenLattice: true,
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: LevelLine(
                  nowY * sy,
                  nowY <= startY ? VistaColors.long : VistaColors.short,
                  dotted: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A horizontal level across the chart at [y]: grey 2-on-3 dashes (a
/// baseline), or [dotted] round dots (the current value).
class LevelLine extends CustomPainter {
  const LevelLine(this.y, this.color, {this.dotted = false});

  final double y;
  final Color color;
  final bool dotted;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    if (dotted) {
      for (var x = 1.0; x < size.width; x += 6) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    } else {
      for (var x = 0.0; x < size.width; x += 5) {
        canvas.drawRect(Rect.fromLTWH(x, y - 0.5, 2, 1), paint);
      }
    }
  }

  @override
  bool shouldRepaint(LevelLine old) =>
      old.y != y || old.color != color || old.dotted != dotted;
}

class _MutedLine extends CustomPainter {
  const _MutedLine(this.points, this.sx, this.sy);

  final List<Offset> points;
  final double sx;
  final double sy;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addPolygon([
        for (final p in points) Offset(p.dx * sx, p.dy * sy),
      ], false);
    canvas.drawPath(
      path,
      Paint()
        ..color = VistaColors.textMuted.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_MutedLine old) =>
      old.points != points || old.sx != sx || old.sy != sy;
}

/// Builds from a live value, easing to each new figure (450ms) rather than
/// jumping on the tick, inside a repaint boundary so the rest of the screen
/// doesn't repaint with it. For live charts.
class EasedValue extends StatelessWidget {
  const EasedValue({
    super.key,
    required this.listenable,
    required this.builder,
  });

  final ValueListenable<double> listenable;
  final Widget Function(BuildContext context, double value) builder;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder(
        valueListenable: listenable,
        builder: (context, live, _) => TweenAnimationBuilder<double>(
          tween: Tween(end: live),
          duration: VistaMotion.live,
          curve: VistaMotion.enter,
          builder: (context, eased, _) => builder(context, eased),
        ),
      ),
    );
  }
}
