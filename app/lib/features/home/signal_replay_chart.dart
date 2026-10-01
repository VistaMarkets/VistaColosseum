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
import 'replay_script.dart';
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
/// A dotted current-price line follows the tip, the fills reveal behind it,
/// and each event marker pops in with a ring as the tip reaches it (with a
/// haptic tick), its label rising in just after. The breakout gets a double ring and a firmer
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
    this.script = ReplayScript.figmaEth,
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

  /// The card's story: its price path, call line, call tag and events.
  final ReplayScript script;

  @override
  State<SignalReplayChart> createState() => _SignalReplayChartState();
}

const Size _canvas = Size(360, 403);
const double _roomyScale = 0.8;

/// Canvas step between points, and the x "now" sits at.
const double _step = 7.4;
const double _nowX = 352;

/// Points in every replay path.
const int _pathPoints = 48;

/// Live ticks per new point (and new candle).
const int _ticksPerPoint = 4;

/// Room kept above and below the line before the scale eases in.
const double _topRoom = 18;
const double _bottomRoom = 392;

/// When the tip reaches each event kind.
double _eventMs(ReplayEventKind kind) => switch (kind) {
  ReplayEventKind.funding => ReplayTimeline.funding,
  ReplayEventKind.whale => ReplayTimeline.whale,
  ReplayEventKind.payoff => ReplayTimeline.breakout,
};

/// Overshooting ease for marker pops: past full size and back.
const Curve _popCurve = Cubic(0.34, 1.8, 0.64, 1);

/// How the canvas is shown once live: scrolled left by [scroll] and, if the
/// price has run far, squeezed toward the call line by [scale].
class _View {
  const _View({this.scroll = 0, this.scale = 1});

  final double scroll;
  final double scale;

  Offset apply(Offset p, double entryY) =>
      Offset(p.dx - scroll, entryY + (p.dy - entryY) * scale);

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
  static _Camera at(ReplayScript script, double t) {
    if (t <= 0 || t >= 1) return identity;
    final tip = script.tipAt(t);
    final line = script.path;
    final entryY = script.entryY;
    // What has been revealed so far, always with the call line.
    var top = math.min(entryY, tip.dy);
    var bottom = math.max(entryY, tip.dy);
    final reached = (t * (line.length - 1)).floor();
    for (var i = 0; i <= reached; i++) {
      top = math.min(top, line[i].dy);
      bottom = math.max(bottom, line[i].dy);
    }
    final left = line.first.dx;
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

  ReplayScript get _s => widget.script;
  List<Offset> get _line => _s.path;
  double get _entryY => _s.entryY;

  // Live state: the path (the replay's, plus points added since), the
  // newest point's price height easing from → to, and the view doing the
  // same.
  late List<Offset> _path = [..._line];
  late double _fromY = _line.last.dy;
  late double _toY = _line.last.dy;
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
    final span = _s.nowPrice - _s.callPrice;
    if (span == 0) return _entryY;
    return _entryY - (price - _s.callPrice) / span * (_entryY - _line.last.dy);
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
      for (final e in _s.events) {
        final at = _eventMs(e.kind);
        if (_lastMs < at && ms >= at) {
          e.kind == ReplayEventKind.payoff
              ? HapticFeedback.mediumImpact()
              : HapticFeedback.selectionClick();
        }
      }
    }
    _lastMs = ms;

    final frame = widget.frame;
    if (frame == null) return;
    final tip = _s.tipAt(ReplayTimeline.progressAt(ms));
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

  /// Where each event label sits, as its offset from the marker. Placed
  /// payoff first, then whale, then funding: each takes the first free spot
  /// of just above, just below, a step higher, a step lower, free meaning
  /// clear of labels already placed, the call tag, the live-activity rows
  /// at the top left and the chart's edge (else the least crowded). Decided
  /// on the finished layout, so a label never moves mid-replay.
  Map<ReplayEventKind, double> _labelOffsets(
    Size size,
    double sx,
    double sy,
    TextScaler scaler,
  ) {
    double textWidth(String text, TextStyle style) => (TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout()).width;

    const labelHeight = 22.0;
    Rect rectFor(ReplayEvent e, double offset) {
      final c = _line[e.vertex];
      final w = textWidth(e.label, VistaType.labelStrong) + 14;
      // Matches the label's Align: its left edge slides with the point.
      final left = (size.width - w) * (c.dx / _canvas.width);
      return Rect.fromLTWH(left, c.dy * sy + offset, w, labelHeight);
    }

    final taken = <Rect>[
      Rect.fromLTWH(
        12,
        _entryY * sy + 8,
        textWidth(_s.callTag, VistaType.micro) + 12,
        18,
      ),
      // The live-activity rows over the chart's top left.
      Rect.fromLTRB(12, 16, math.max(12, size.width - 78), 108),
    ];
    double clash(Rect r) {
      var area = 0.0;
      if (r.top < 0) area += -r.top * r.width;
      if (r.bottom > size.height) area += (r.bottom - size.height) * r.width;
      for (final t in taken) {
        final o = r.intersect(t);
        if (o.width > 0 && o.height > 0) area += o.width * o.height;
      }
      return area;
    }

    const spots = [-34.0, 12.0, -58.0, 36.0];
    final placed = <ReplayEventKind, double>{};
    final order = [..._s.events]
      ..sort((a, b) => b.kind.index.compareTo(a.kind.index));
    for (final e in order) {
      var best = spots.first;
      var bestClash = double.infinity;
      for (final offset in spots) {
        final c = clash(rectFor(e, offset));
        if (c < bestClash) {
          best = offset;
          bestClash = c;
        }
        if (c == 0) break;
      }
      placed[e.kind] = best;
      taken.add(rectFor(e, best));
    }
    return placed;
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
        final labelAt = _labelOffsets(
          size,
          sx,
          sy,
          MediaQuery.textScalerOf(context),
        );

        return ClipRect(
          child: AnimatedBuilder(
            animation: Listenable.merge([_trace, _live]),
            builder: (context, _) {
              final ms = _ms;
              final t = ReplayTimeline.progressAt(ms);
              final live = _replayDone;
              final view = live ? _view : const _View();
              // While replaying, the camera; once live, the scrolling view.
              final camera = live ? _Camera.identity : _Camera.at(_s, t);
              Offset at(Offset p) =>
                  live ? view.apply(p, _entryY) : camera.apply(p);

              // The path as shown: the replay's through the camera while
              // tracing; once live, the whole path scrolled and scaled, its
              // newest point easing.
              final points = live
                  ? [
                      for (final p in _path.sublist(0, _path.length - 1)) at(p),
                      at(Offset(_path.last.dx, _lastY)),
                    ]
                  : [for (final p in _line) at(p)];
              final tip = live ? points.last : at(_s.tipAt(t));
              final entryY = at(Offset(0, _entryY)).dy;

              // Fixed-size marker centred on a canvas point.
              Widget marker(
                String asset,
                Offset c,
                double d, {
                double pop = 1,
                Color? tint,
              }) => Positioned(
                left: c.dx * sx - d / 2,
                top: c.dy * sy - d / 2,
                child: _Pop(
                  value: pop,
                  child: VistaIcon(asset, size: d, color: tint),
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

              // Label centred above (or below) a canvas point, kept inside
              // the chart.
              Widget labelAbove(
                Offset c,
                Widget child, {
                double pop = 1,
                double offset = -34,
              }) => Positioned(
                left: 0,
                right: 0,
                top: math.max(0, c.dy * sy + offset),
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

              final entry = at(Offset(4, _entryY));

              // Each event: its marker, a ring as it lands, and its label.
              // The payoff gets two wider rings and a tinted tag.
              List<Widget> event(ReplayEvent e) {
                final c = at(_line[e.vertex]);
                final ms0 = _eventMs(e.kind);
                final payoff = e.kind == ReplayEventKind.payoff;
                final tone = e.favourable
                    ? VistaColors.long
                    : VistaColors.short;
                return [
                  ring(
                    c,
                    12,
                    ringAt(ms0),
                    payoff ? tone : VistaColors.textPrimary,
                    payoff ? 4.5 : 3.2,
                  ),
                  if (payoff) ring(c, 12, ringAt(ms0 + 220), tone, 4.5),
                  marker(
                    switch (e.kind) {
                      ReplayEventKind.funding => VistaAssets.markerFunding,
                      ReplayEventKind.whale => VistaAssets.markerWhale,
                      ReplayEventKind.payoff => VistaAssets.markerBreakout,
                    },
                    c,
                    12,
                    pop: pop(ms0),
                    tint: payoff && !e.favourable ? tone : null,
                  ),
                  // Mid-chart labels drop on short phones; the payoff stays.
                  if (roomy || payoff)
                    labelAbove(
                      c,
                      payoff
                          ? VistaTag(
                              label: e.label,
                              color: tone,
                              textColor: VistaColors.onAccent,
                            )
                          : VistaTag(label: e.label),
                      pop: label(ms0),
                      offset: labelAt[e.kind] ?? -34,
                    ),
                ];
              }

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
                          : ReplayLinePainter(
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
                    child: VistaTag(label: _s.callTag, dense: true),
                  ),
                  for (final e in _s.events) ...event(e),
                  // Current price: a dotted line across the chart at the tip's
                  // level, green above the call line and red below it.
                  if (t > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: tip.dy * sy - 1,
                      height: 2,
                      child: CustomPaint(
                        painter: _PriceLine(
                          tip.dy > entryY
                              ? VistaColors.short
                              : VistaColors.long,
                        ),
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
/// as it scrolls, so they travel with the data. Shared with the share card,
/// which squashes the canvas and so spaces its lattice in screen points
/// ([screenLattice]) to keep the dots 14pt apart.
class ReplayLinePainter extends CustomPainter {
  const ReplayLinePainter({
    required this.points,
    required this.entryY,
    required this.revealX,
    required this.latticeShift,
    required this.sx,
    required this.sy,
    this.screenLattice = false,
    this.invert = false,
  });

  final List<Offset> points;
  final bool screenLattice;

  /// Red above the line and green below, for a short (where up is a loss).
  final bool invert;

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
      if (screenLattice) {
        for (var gx = 4 * sx; gx < size.width + 14; gx += 14) {
          for (var gy = 5.0; gy < size.height; gy += 14) {
            canvas.drawCircle(Offset(gx, gy), 1, dot);
          }
        }
      } else {
        for (var gx = 4 - shift; gx < _canvas.width + 14; gx += 14) {
          for (var gy = 5.0; gy < _canvas.height; gy += 14) {
            canvas.drawCircle(Offset(gx * sx, gy * sy), 1, dot);
          }
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

    final up = invert ? VistaColors.short : VistaColors.long;
    final down = invert ? VistaColors.long : VistaColors.short;
    canvas
      ..save()
      ..clipRect(above)
      ..drawPath(under, fill(up, true))
      ..drawPath(path, stroke(up))
      ..restore()
      ..save()
      ..clipRect(below)
      ..drawPath(over, fill(down, false))
      ..drawPath(path, stroke(down))
      ..restore()
      ..restore();
  }

  @override
  bool shouldRepaint(ReplayLinePainter old) =>
      !listEquals(old.points, points) ||
      old.entryY != entryY ||
      old.invert != invert ||
      old.revealX != revealX ||
      old.latticeShift != latticeShift ||
      old.sx != sx ||
      old.sy != sy ||
      old.screenLattice != screenLattice;
}

/// When the tip reaches each vertex of the path, in replay ms.
final List<double> _vertexMs = [
  for (var k = 0; k < _pathPoints; k++)
    ReplayTimeline.timeAt(k / (_pathPoints - 1)),
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

/// The current-price line: 2pt round dots every 6pt across the chart.
class _PriceLine extends CustomPainter {
  const _PriceLine(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cy = size.height / 2;
    for (var x = 1.0; x < size.width; x += 6) {
      canvas.drawCircle(Offset(x, cy), 1, paint);
    }
  }

  @override
  bool shouldRepaint(_PriceLine old) => old.color != color;
}
