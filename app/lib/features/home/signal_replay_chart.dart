import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../charting/charting.dart';
import '../../design_system/design_system.dart';
import '../settings/settings_state.dart';
import 'active_replay.dart';
import 'replay_timeline.dart';

/// Replay of price since the call, then the live market: dashed entry
/// baseline, gain/loss fills and event markers.
///
/// The price path is the one drawn in Figma, on a 360×403 canvas. The chart
/// stretches to the available size and markers are placed proportionally,
/// so it fills any phone without overflowing. Markers and labels keep their
/// pixel size so they stay round and legible.
///
/// Motion: whenever the chart becomes [active] (its card settles on screen, or
/// the app returns to the foreground) the line traces from the call to now.
/// A camera ([_Camera]) opens close on the first candle and pulls back as the
/// tip moves until the whole designed frame is in view.
/// A head dot rides the tip, the fills reveal behind it, and each event
/// marker pops in with a ring as the tip reaches it (with a haptic tick), its
/// label rising in just after. The breakout gets a double ring and a firmer
/// haptic. Timing is in [ReplayTimeline]. The finished frame is the design.
///
/// Then it stays live. Each [livePrice] tick eases the newest point to the
/// new price; every few ticks a new point starts and the chart glides one
/// step left so "now" stays at the right edge, the markers scrolling with
/// it. If the price runs toward the top or bottom, the chart eases its scale
/// around the call line so the line always stays in view.
///
/// With candles chosen in Settings › Display, the same path is drawn as
/// candles instead of the line and fills.
class SignalReplayChart extends StatefulWidget {
  const SignalReplayChart({
    super.key,
    this.active = true,
    this.frame,
    this.livePrice,
    this.callPrice = 2801.10,
    this.nowPrice = 2968.40,
  });

  /// Whether this chart is the one on screen. Becoming active replays the
  /// trace; becoming inactive resets it so the next visit replays too.
  final bool active;

  /// Receives the replay's progress each frame, so the card header can move
  /// its price and "% since call" in step with the tip.
  final ValueNotifier<ReplayFrame>? frame;

  /// The market's live price, followed once the replay has finished. Null
  /// keeps the chart on the replay's final frame.
  final ValueListenable<double>? livePrice;

  /// Prices at the call line and at the end of the replayed path, which
  /// together set the chart's price scale.
  final double callPrice;
  final double nowPrice;

  @override
  State<SignalReplayChart> createState() => _SignalReplayChartState();
}

const Size _canvas = Size(360, 403);
const double _entryY = 232.04;
const double _roomyScale = 0.8;

/// Vertices of the price line on the canvas, from the Figma vector.
const List<Offset> _line = [
  Offset(4, 232), Offset(11.4, 275.9), Offset(18.8, 295.2), //
  Offset(26.2, 310.3), Offset(33.6, 317), Offset(41, 321.4),
  Offset(48.4, 345.5), Offset(55.8, 373.5), Offset(63.2, 379),
  Offset(70.6, 355.3), Offset(78, 356.5), Offset(85.4, 342.1),
  Offset(92.9, 330.3), Offset(100.3, 333.2), Offset(107.7, 334.1),
  Offset(115.1, 318.5), Offset(122.5, 325), Offset(129.9, 331),
  Offset(137.3, 332.2), Offset(144.7, 331.5), Offset(152.1, 328.8),
  Offset(159.5, 333.4), Offset(166.9, 311.1), Offset(174.3, 287.9),
  Offset(181.7, 274.3), Offset(189.1, 259.1), Offset(196.5, 255.5),
  Offset(203.9, 225.8), Offset(211.3, 223.3), Offset(218.7, 226.2),
  Offset(226.1, 208.8), Offset(233.5, 208.2), Offset(240.9, 188.6),
  Offset(248.3, 193.6), Offset(255.7, 196.1), Offset(263.1, 168.9),
  Offset(270.6, 145.1), Offset(278, 145.2), Offset(285.4, 118.5),
  Offset(292.8, 125.3), Offset(300.2, 107.4), Offset(307.6, 81.7),
  Offset(315, 85.7), Offset(322.4, 86.2), Offset(329.8, 60.2),
  Offset(337.2, 62.3), Offset(344.6, 38.5), Offset(352, 24),
];

/// Canvas step between points, and the x "now" sits at.
const double _step = 7.4;
final double _nowX = _line.last.dx;

/// Live ticks per new point (and new candle).
const int _ticksPerPoint = 4;

/// Room kept above and below the line before the scale eases in.
const double _topRoom = 18;
const double _bottomRoom = 392;

/// Point on the line a fraction [t] of the way along its vertices.
Offset _tipAt(double t) {
  final pos = t.clamp(0.0, 1.0) * (_line.length - 1);
  final i = pos.floor();
  if (i >= _line.length - 1) return _line.last;
  return Offset.lerp(_line[i], _line[i + 1], pos - i)!;
}

/// Events: where each sits on the canvas and when the tip reaches it.
const _funding = (Offset(152.09, 328.8), ReplayTimeline.funding);
const _whale = (Offset(248.34, 193.6), ReplayTimeline.whale);
const _breakout = (Offset(329.79, 60.17), ReplayTimeline.breakout);

/// Overshooting ease for marker pops: past full size and back.
const Curve _popCurve = Cubic(0.34, 1.8, 0.64, 1);

/// How the canvas is shown once live: scrolled left by [scroll] and, if the
/// price has run far, squeezed toward the call line by [scale].
class _View {
  const _View({this.scroll = 0, this.scale = 1});

  final double scroll;
  final double scale;

  Offset apply(Offset p) =>
      Offset(p.dx - scroll, _entryY + (p.dy - _entryY) * scale);

  static _View lerp(_View a, _View b, double t) => _View(
    scroll: a.scroll + (b.scroll - a.scroll) * t,
    scale: a.scale + (b.scale - a.scale) * t,
  );
}

/// The replay's camera: maps the canvas so the part of the path revealed so
/// far fills the chart. It opens close on the first candle (big and wide)
/// and pulls back as the tip moves, until at the end it is exactly the
/// designed frame. The call line is always in frame, so the baseline and its
/// tag never leave the view; markers ride the camera and keep their size.
class _Camera {
  const _Camera(this.ax, this.bx, this.ay, this.by);

  static const identity = _Camera(0, 1, 0, 1);

  final double ax;
  final double bx;
  final double ay;
  final double by;

  Offset apply(Offset p) => Offset(ax + bx * p.dx, ay + by * p.dy);

  /// The camera when the tip has covered [t] of the path.
  static _Camera at(double t) {
    if (t <= 0 || t >= 1) return identity;
    final tip = _tipAt(t);
    // What has been revealed so far, always with the call line.
    var top = math.min(_entryY, tip.dy);
    var bottom = math.max(_entryY, tip.dy);
    final reached = (t * (_line.length - 1)).floor();
    for (var i = 0; i <= reached; i++) {
      top = math.min(top, _line[i].dy);
      bottom = math.max(bottom, _line[i].dy);
    }
    final left = _line.first.dx;
    var right = tip.dx;

    // Never closer than a few candles wide and a set height, so the first
    // candle is big without being absurd.
    if (right - left < _minSpanX) right = left + _minSpanX;
    if (bottom - top < _minSpanY) {
      final mid = (top + bottom) / 2;
      top = mid - _minSpanY / 2;
      bottom = mid + _minSpanY / 2;
    }

    // Early on the tip sits partway across, leaving room for what's next;
    // by the end it reaches the designed right edge.
    final lead = _leadStart + (1 - _leadStart) * t;
    final frameRight = _frameLeft + (_frameRight - _frameLeft) * lead;
    final bx = (frameRight - _frameLeft) / (right - left);
    final by = (_frameBottom - _frameTop) / (bottom - top);
    final fit = _Camera(_frameLeft - bx * left, bx, _frameTop - by * top, by);

    // The last stretch blends into the designed frame, which it ends on.
    final w = ((t - _blendFrom) / (1 - _blendFrom)).clamp(0.0, 1.0);
    final e = w * w * (3 - 2 * w);
    double mix(double a, double b) => a + (b - a) * e;
    return _Camera(
      mix(fit.ax, 0),
      mix(fit.bx, 1),
      mix(fit.ay, 0),
      mix(fit.by, 1),
    );
  }
}

/// The designed frame the path fills (canvas units), and camera limits.
const double _frameLeft = 4;
const double _frameRight = 352;
const double _frameTop = 24;
const double _frameBottom = 379;
const double _minSpanX = 6 * _step;
const double _minSpanY = 96;
const double _leadStart = 0.62;
const double _blendFrom = 0.72;

class _SignalReplayChartState extends State<SignalReplayChart>
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        ActiveReplay<SignalReplayChart> {
  late final AnimationController _trace =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: ReplayTimeline.total ~/ 1),
        )
        ..addListener(_onTick)
        // The header switches to the live price as the replay ends; the
        // chart's newest point eases there at the same moment.
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _follow(tick: false);
        });

  /// Eases each live update (newest point, scroll and scale) into place.
  late final AnimationController _live = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 1,
  );

  /// Replay time last tick, to fire each event's haptic exactly once.
  double _lastMs = 0;

  // Live state: the path (the replay's, plus points added since), the
  // newest point's price height easing from → to, and the view doing the
  // same.
  List<Offset> _path = [..._line];
  double _fromY = _line.last.dy;
  double _toY = _line.last.dy;
  _View _fromView = const _View();
  _View _toView = const _View();
  int _ticks = 0;

  double get _ms => _trace.value * ReplayTimeline.total;
  double get _ease => Curves.easeOutCubic.transform(_live.value);
  double get _lastY => _fromY + (_toY - _fromY) * _ease;
  _View get _view => _View.lerp(_fromView, _toView, _ease);
  bool get _replayDone => _trace.value >= 1 && !_trace.isAnimating;

  @override
  AnimationController get replay => _trace;

  @override
  bool isActive(SignalReplayChart widget) => widget.active;

  @override
  void initState() {
    super.initState();
    widget.livePrice?.addListener(_onPrice);
  }

  @override
  void didUpdateWidget(SignalReplayChart old) {
    super.didUpdateWidget(old);
    if (old.livePrice != widget.livePrice) {
      old.livePrice?.removeListener(_onPrice);
      widget.livePrice?.addListener(_onPrice);
    }
  }

  /// Back to the replay's path, for the next run.
  void _resetLive() {
    _path = [..._line];
    _fromY = _toY = _line.last.dy;
    _fromView = _toView = const _View();
    _ticks = 0;
    _live.value = 1;
  }

  /// Canvas height for a price: the call sits on the entry line and
  /// [SignalReplayChart.nowPrice] where the replayed path ends.
  double _yFor(double price) {
    final span = widget.nowPrice - widget.callPrice;
    if (span == 0) return _entryY;
    return _entryY -
        (price - widget.callPrice) / span * (_entryY - _line.last.dy);
  }

  void _onPrice() => _follow(tick: true);

  /// Eases the newest point to the live price. A [tick] counts toward
  /// opening the next point; catching up as the replay ends does not.
  void _follow({required bool tick}) {
    final feed = widget.livePrice;
    if (feed == null || !widget.active || !_replayDone) return;
    // Continue from wherever the last update's easing has got to.
    final y = _yFor(feed.value);
    final nowY = _lastY;
    _fromView = _view;
    if (tick) _ticks++;
    if (tick && _ticks % _ticksPerPoint == 0) {
      // The newest point is settled; a new one opens at its price.
      _path = [
        ..._path.sublist(0, _path.length - 1),
        Offset(_path.last.dx, nowY),
        Offset(_path.last.dx + _step, nowY),
      ];
    } else {
      _path = [
        ..._path.sublist(0, _path.length - 1),
        Offset(_path.last.dx, nowY),
      ];
    }
    _fromY = nowY;
    _toY = y;

    // Keep "now" at the right edge, and every visible point in view.
    final scroll = math.max(0.0, _path.last.dx - _nowX);
    var highest = y;
    var lowest = y;
    for (final p in _path) {
      if (p.dx - scroll < -_step) continue;
      highest = math.min(highest, p.dy);
      lowest = math.max(lowest, p.dy);
    }
    var scale = 1.0;
    if (highest < _topRoom) {
      scale = math.min(scale, (_entryY - _topRoom) / (_entryY - highest));
    }
    if (lowest > _bottomRoom) {
      scale = math.min(scale, (_bottomRoom - _entryY) / (lowest - _entryY));
    }
    _toView = _View(scroll: scroll, scale: scale);
    _live.forward(from: 0);
  }

  void _onTick() {
    final ms = _ms;
    // A replay starting over (or a reset) begins from the designed path.
    if (ms < _lastMs && _ticks > 0) _resetLive();
    if (_trace.isAnimating && ms > _lastMs) {
      for (final (_, at) in [_funding, _whale]) {
        if (_lastMs < at && ms >= at) HapticFeedback.selectionClick();
      }
      if (_lastMs < _breakout.$2 && ms >= _breakout.$2) {
        HapticFeedback.mediumImpact();
      }
    }
    _lastMs = ms;

    final frame = widget.frame;
    if (frame == null) return;
    final tip = _tipAt(ReplayTimeline.progressAt(ms));
    final tracing = _trace.isAnimating && ms < ReplayTimeline.trace;
    _publish(
      frame,
      ReplayFrame(
        replaying: tracing,
        priceFraction: tracing
            ? (_entryY - tip.dy) / (_entryY - _line.last.dy)
            : 1,
        // Only after a replay actually ran, not on a reset or reduced motion.
        finale: _trace.isAnimating
            ? ReplayTimeline.phase(
                ms,
                ReplayTimeline.trace,
                ReplayTimeline.finale,
              )
            : 0,
      ),
    );
  }

  /// A replay can start or reset mid-build (when a card becomes active);
  /// the header listening to [frame] then updates just after the frame.
  void _publish(ValueNotifier<ReplayFrame> frame, ReplayFrame value) {
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) {
        if (mounted) frame.value = value;
      });
    } else {
      frame.value = value;
    }
  }

  @override
  void dispose() {
    widget.livePrice?.removeListener(_onPrice);
    _trace.dispose();
    _live.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: DisplayPrefs.chartMode,
      builder: (context, mode, _) => _chart(mode == PlotMode.candles),
    );
  }

  Widget _chart(bool candles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final sx = size.width / _canvas.width;
        final sy = size.height / _canvas.height;
        // On short phones the canvas squashes but labels don't; drop the
        // mid-chart annotations (markers stay) so labels never collide.
        final roomy = sy >= _roomyScale;

        return ClipRect(
          child: AnimatedBuilder(
            animation: Listenable.merge([_trace, _live]),
            builder: (context, _) {
              final ms = _ms;
              final t = ReplayTimeline.progressAt(ms);
              final live = _replayDone;
              final view = live ? _view : const _View();
              // While replaying, the camera; once live, the scrolling view.
              final camera = live ? _Camera.identity : _Camera.at(t);
              Offset at(Offset p) => live ? view.apply(p) : camera.apply(p);

              // The path as shown: the replay's through the camera while
              // tracing; once live, the whole path scrolled and scaled, its
              // newest point easing.
              final points = live
                  ? [
                      for (final p in _path.sublist(0, _path.length - 1)) at(p),
                      at(Offset(_path.last.dx, _lastY)),
                    ]
                  : [for (final p in _line) at(p)];
              final tip = live ? points.last : at(_tipAt(t));
              final entryY = at(const Offset(0, _entryY)).dy;

              // Fixed-size marker centred on a canvas point.
              Widget marker(
                String asset,
                Offset c,
                double d, {
                double pop = 1,
              }) => Positioned(
                left: c.dx * sx - d / 2,
                top: c.dy * sy - d / 2,
                child: _Pop(
                  value: pop,
                  child: VistaIcon(asset, size: d),
                ),
              );

              // A ring sent out from a marker as it lands: grows to [reach]
              // times the marker and fades.
              Widget ring(
                Offset c,
                double d,
                double value,
                Color color,
                double reach,
              ) {
                if (value <= 0 || value >= 1) return const SizedBox.shrink();
                final e = Curves.easeOutCubic.transform(value);
                final size = d * (1 + (reach - 1) * e);
                return Positioned(
                  left: c.dx * sx - size / 2,
                  top: c.dy * sy - size / 2,
                  child: IgnorePointer(
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: 0.7 * (1 - e)),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                );
              }

              // Label centred above a canvas point, kept inside the chart.
              Widget labelAbove(Offset c, Widget child, {double pop = 1}) =>
                  Positioned(
                    left: 0,
                    right: 0,
                    top: math.max(0, c.dy * sy - 34),
                    child: Align(
                      alignment: Alignment((c.dx / _canvas.width) * 2 - 1, 0),
                      child: _Rise(value: pop, child: child),
                    ),
                  );

              // Marker pop, its ring, and its label, from when the tip lands.
              double pop(double at) =>
                  ReplayTimeline.phase(ms, at, ReplayTimeline.pop);
              double ringAt(double at) =>
                  ReplayTimeline.phase(ms, at, ReplayTimeline.ring);
              double label(double at) => ReplayTimeline.phase(
                ms,
                at + ReplayTimeline.labelDelay,
                ReplayTimeline.label,
              );

              final funding = at(_funding.$1);
              final whale = at(_whale.$1);
              final breakout = at(_breakout.$1);
              final entry = at(const Offset(4, _entryY));

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: entryY * sy - 0.5,
                    height: 1,
                    child: SvgPicture.asset(
                      VistaAssets.chartBaseline,
                      fit: BoxFit.fill,
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: candles
                          ? _ReplayCandles(
                              points: points,
                              ms: live ? ReplayTimeline.total : ms,
                              zoomY: camera.by * view.scale,
                              sx: sx,
                              sy: sy,
                            )
                          : _ReplayLine(
                              points: points,
                              entryY: entryY,
                              revealX: live || t >= 1 ? null : tip.dx,
                              latticeShift: view.scroll,
                              sx: sx,
                              sy: sy,
                            ),
                    ),
                  ),
                  if (entry.dx > -6) marker(VistaAssets.markerEntry, entry, 10),
                  Positioned(
                    left: 12,
                    top: entryY * sy + 8,
                    child: const VistaTag(
                      label: r'Called $2,801.10 · 5h ago',
                      dense: true,
                    ),
                  ),
                  ring(
                    funding,
                    12,
                    ringAt(_funding.$2),
                    VistaColors.textPrimary,
                    3.2,
                  ),
                  marker(
                    VistaAssets.markerFunding,
                    funding,
                    12,
                    pop: pop(_funding.$2),
                  ),
                  if (roomy)
                    labelAbove(
                      funding,
                      const VistaTag(label: 'Funding flipped +'),
                      pop: label(_funding.$2),
                    ),
                  ring(
                    whale,
                    12,
                    ringAt(_whale.$2),
                    VistaColors.textPrimary,
                    3.2,
                  ),
                  marker(
                    VistaAssets.markerWhale,
                    whale,
                    12,
                    pop: pop(_whale.$2),
                  ),
                  if (roomy)
                    labelAbove(
                      whale,
                      const VistaTag(label: r'Whale long $4.2M'),
                      pop: label(_whale.$2),
                    ),
                  // The breakout is the payoff: two rings, wider and green.
                  ring(
                    breakout,
                    12,
                    ringAt(_breakout.$2),
                    VistaColors.long,
                    4.5,
                  ),
                  ring(
                    breakout,
                    12,
                    ringAt(_breakout.$2 + 220),
                    VistaColors.long,
                    4.5,
                  ),
                  marker(
                    VistaAssets.markerBreakoutHalo,
                    breakout,
                    26,
                    pop: pop(_breakout.$2),
                  ),
                  marker(
                    VistaAssets.markerBreakout,
                    breakout,
                    12,
                    pop: pop(_breakout.$2),
                  ),
                  labelAbove(
                    breakout,
                    const VistaTag(
                      label: r'Broke $2,950',
                      color: VistaColors.long,
                      textColor: VistaColors.onAccent,
                    ),
                    pop: label(_breakout.$2),
                  ),
                  // Live dot: rides the tip while tracing, then "now".
                  if (t > 0)
                    Positioned(
                      left: tip.dx * sx - 7,
                      top: tip.dy * sy - 7,
                      child: _LiveDot(
                        tint: tip.dy > _entryY ? VistaColors.short : null,
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// The line in the app's line style: a 3pt stroke with an 18% fill, green
/// above the call line and red below it, and a 1pt dot lattice on a 14pt
/// grid inside the filled area. Points are in canvas units. [revealX] cuts
/// it off at the tracing tip; [latticeShift] moves the dots with the path
/// as it scrolls, so they travel with the data.
class _ReplayLine extends CustomPainter {
  const _ReplayLine({
    required this.points,
    required this.entryY,
    required this.revealX,
    required this.latticeShift,
    required this.sx,
    required this.sy,
  });

  final List<Offset> points;

  /// The call line's height, in canvas units, as the camera shows it.
  final double entryY;
  final double? revealX;
  final double latticeShift;
  final double sx;
  final double sy;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    Offset px(Offset p) => Offset(p.dx * sx, p.dy * sy);
    final pts = [for (final p in points) px(p)];
    final base = entryY * sy;
    final top = 24 * sy;
    final bottom = 379 * sy;
    final path = Path()..addPolygon(pts, false);
    final under = Path.from(path)
      ..lineTo(pts.last.dx, size.height + 10)
      ..lineTo(pts.first.dx, size.height + 10)
      ..close();
    final over = Path.from(path)
      ..lineTo(pts.last.dx, -10)
      ..lineTo(pts.first.dx, -10)
      ..close();
    final above = Rect.fromLTRB(-20, -20, size.width + 20, base);
    final below = Rect.fromLTRB(-20, base, size.width + 20, size.height + 20);

    canvas.save();
    if (revealX != null) {
      canvas.clipRect(Rect.fromLTRB(-20, -20, revealX! * sx + 2, 1e4));
    }

    // Dot lattice inside the filled area only.
    final dot = Paint()..color = const Color(0x2EFFFFFF);
    final shift = latticeShift % 14;
    for (final (area, band) in [(under, above), (over, below)]) {
      canvas
        ..save()
        ..clipRect(band)
        ..clipPath(area);
      for (var gx = 4 - shift; gx < _canvas.width + 14; gx += 14) {
        for (var gy = 5.0; gy < _canvas.height; gy += 14) {
          canvas.drawCircle(Offset(gx * sx, gy * sy), 1, dot);
        }
      }
      canvas.restore();
    }

    Paint fill(Color c, bool fromTop) => Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          c.withValues(alpha: fromTop ? 0.18 : 0),
          c.withValues(alpha: fromTop ? 0 : 0.18),
        ],
      ).createShader(Rect.fromLTRB(0, top, size.width, bottom));
    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas
      ..save()
      ..clipRect(above)
      ..drawPath(under, fill(VistaColors.long, true))
      ..drawPath(path, stroke(VistaColors.long))
      ..restore()
      ..save()
      ..clipRect(below)
      ..drawPath(over, fill(VistaColors.short, false))
      ..drawPath(path, stroke(VistaColors.short))
      ..restore()
      ..restore();
  }

  @override
  bool shouldRepaint(_ReplayLine old) =>
      !listEquals(old.points, points) ||
      old.entryY != entryY ||
      old.revealX != revealX ||
      old.latticeShift != latticeShift ||
      old.sx != sx ||
      old.sy != sy;
}

/// When the tip reaches each vertex of the path, in replay ms.
final List<double> _vertexMs = [
  for (var k = 0; k < _line.length; k++)
    ReplayTimeline.timeAt(k / (_line.length - 1)),
];

/// The replay path as candles: segment i opens at vertex i and closes at
/// vertex i + 1, with wicks a little past the body. Rising candles are
/// hollow, falling ones filled, as on the trade chart.
///
/// Each candle grows in over [ReplayTimeline.candleGrow] from the moment the
/// tip reaches it, so the newest few are still growing in a wave behind the
/// live dot:
/// - the body opens out from half width and stretches from its open
///   towards its close, fast at first and settling;
/// - once the body is mostly there, the wicks spring out a touch past full
///   length and settle back.
/// A candle's colour is fixed by where it will close, so it never flickers
/// between red and green while growing.
class _ReplayCandles extends CustomPainter {
  const _ReplayCandles({
    required this.points,
    required this.ms,
    required this.zoomY,
    required this.sx,
    required this.sy,
  });

  /// The path, in canvas units; points past the replay's are live and
  /// already fully grown (their close eases with the live price).
  final List<Offset> points;
  final double ms;

  /// Vertical zoom the path is shown at, so wick lengths scale with it.
  final double zoomY;
  final double sx;
  final double sy;

  @override
  void paint(Canvas canvas, Size size) {
    final up = Paint()..color = VistaColors.long;
    final down = Paint()..color = VistaColors.short;
    final hollow = Paint()..color = VistaColors.background;
    final outline = Paint()
      ..color = VistaColors.long
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < points.length - 1; i++) {
      // Off the left edge once the live chart has scrolled.
      if (points[i + 1].dx < -_step) continue;
      final grow = i < _vertexMs.length - 1
          ? ReplayTimeline.phase(ms, _vertexMs[i], ReplayTimeline.candleGrow)
          : 1.0;
      // Candles start in order, so the first unstarted one ends the pass.
      if (grow <= 0) break;

      final open = points[i].dy;
      final target = points[i + 1].dy;
      // Canvas y grows downward, so a lower y is a higher price.
      final rising = target <= open;
      final stretch = Curves.easeOutCubic.transform(grow);
      final close = open + (target - open) * stretch;
      final widen = Curves.easeOutCubic.transform(math.min(1, grow / 0.4));
      // A candle takes 60% of its slot, however far the camera is in.
      final fullW = math.max(2.0, (points[i + 1].dx - points[i].dx) * sx * 0.6);
      final bodyW = fullW * (0.5 + 0.5 * widen);
      final flick = Curves.easeOutBack.transform(
        ((grow - 0.3) / 0.7).clamp(0.0, 1.0),
      );
      // Wicks reach past the body by a share of its size, deterministically.
      final reach =
          ((target - open).abs() * 0.35 + (3 + (i % 3) * 1.5) * zoomY) * flick;
      final top = math.min(open, close);
      final bottom = math.max(open, close);
      final cx = (points[i].dx + points[i + 1].dx) / 2 * sx;
      final colour = rising ? up : down;

      if (reach > 0) {
        canvas.drawRect(
          Rect.fromLTRB(
            cx - 0.5,
            (top - reach) * sy,
            cx + 0.5,
            (bottom + reach * 0.8) * sy,
          ),
          colour,
        );
      }
      final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - bodyW / 2,
          top * sy,
          bodyW,
          math.max(1.5, (bottom - top) * sy),
        ),
        const Radius.circular(1),
      );
      if (rising) {
        canvas
          ..drawRRect(body, hollow)
          ..drawRRect(body.deflate(0.5), outline);
      } else {
        canvas.drawRRect(body, down);
      }
    }
  }

  @override
  bool shouldRepaint(_ReplayCandles old) =>
      !listEquals(old.points, points) ||
      old.ms != ms ||
      old.zoomY != zoomY ||
      old.sx != sx ||
      old.sy != sy;
}

/// Scales a marker in with a slight overshoot as [value] goes 0 → 1.
class _Pop extends StatelessWidget {
  const _Pop({required this.value, required this.child});

  final double value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (value >= 1) return child;
    if (value <= 0) return const SizedBox.shrink();
    return Opacity(
      opacity: Curves.easeOut.transform(math.min(1, value * 2)),
      child: Transform.scale(scale: _popCurve.transform(value), child: child),
    );
  }
}

/// Fades a label in while it rises 10px and grows into place.
class _Rise extends StatelessWidget {
  const _Rise({required this.value, required this.child});

  final double value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (value >= 1) return child;
    if (value <= 0) return const SizedBox.shrink();
    final e = Curves.easeOutCubic.transform(value);
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - e)),
        child: Transform.scale(scale: 0.85 + 0.15 * e, child: child),
      ),
    );
  }
}

/// The live-price marker (halo + dot); [tint] recolours it below the entry.
class _LiveDot extends StatelessWidget {
  const _LiveDot({this.tint});

  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final filter = tint == null
        ? null
        : ColorFilter.mode(tint!, BlendMode.srcIn);
    return SizedBox.square(
      dimension: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            VistaAssets.markerLiveHalo,
            width: 14,
            height: 14,
            colorFilter: filter,
          ),
          SvgPicture.asset(
            VistaAssets.markerLive,
            width: 7,
            height: 7,
            colorFilter: filter,
          ),
        ],
      ),
    );
  }
}
