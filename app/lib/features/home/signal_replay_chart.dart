import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../charting/charting.dart';
import '../../design_system/design_system.dart';
import '../settings/settings_state.dart';
import 'active_replay.dart';
import 'replay_timeline.dart';

/// Replay of price since the call: dashed entry baseline, gain/loss fills and
/// event markers.
///
/// The price path is the static vector exported from Figma, drawn on a
/// 360×403 canvas. Layers stretch to the available size and markers are
/// placed proportionally, so the chart fills any phone without overflowing.
/// Markers and labels keep their pixel size so they stay round and legible.
///
/// Motion: whenever the chart becomes [active] (its card settles on screen, or
/// the app returns to the foreground) the line traces from the call to now.
/// A head dot rides the tip, the fills reveal behind it, and each event
/// marker pops in with a ring as the tip reaches it (with a haptic tick), its
/// label rising in just after. The breakout gets a double ring and a firmer
/// haptic. Timing is in [ReplayTimeline]. The finished frame is the static
/// design exactly.
///
/// With candles chosen in Settings › Display, the same path is drawn as
/// candles instead of the line and fills: one per segment of the path, each
/// appearing as the tip reaches it, with the forming candle's close riding
/// the tip.
class SignalReplayChart extends StatefulWidget {
  const SignalReplayChart({super.key, this.active = true, this.frame});

  /// Whether this chart is the one on screen. Becoming active replays the
  /// trace; becoming inactive resets it so the next visit replays too.
  final bool active;

  /// Receives the replay's progress each frame, so the card header can move
  /// its price and "% since call" in step with the tip.
  final ValueNotifier<ReplayFrame>? frame;

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

class _SignalReplayChartState extends State<SignalReplayChart>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        ActiveReplay<SignalReplayChart> {
  late final AnimationController _trace = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: ReplayTimeline.total ~/ 1),
  )..addListener(_onTick);

  /// Replay time last tick, to fire each event's haptic exactly once.
  double _lastMs = 0;

  double get _ms => _trace.value * ReplayTimeline.total;

  @override
  AnimationController get replay => _trace;

  @override
  bool isActive(SignalReplayChart widget) => widget.active;

  void _onTick() {
    final ms = _ms;
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
    _trace.dispose();
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

        Widget layer(String asset, Rect r) => Positioned(
          left: r.left * sx,
          top: r.top * sy,
          width: r.width * sx,
          height: r.height * sy,
          child: SvgPicture.asset(asset, fit: BoxFit.fill),
        );

        // Fixed-size marker centred on a canvas point.
        Widget marker(String asset, Offset c, double d, {double pop = 1}) =>
            Positioned(
              left: c.dx * sx - d / 2,
              top: c.dy * sy - d / 2,
              child: _Pop(
                value: pop,
                child: VistaIcon(asset, size: d),
              ),
            );

        // A ring sent out from a marker as it lands: grows to [reach] times
        // the marker and fades.
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

        final funding = _funding.$1;
        final whale = _whale.$1;
        final breakout = _breakout.$1;
        const entry = Offset(4, _entryY);

        // Static layers built once per layout, reused every frame.
        final lineLayers = Stack(
          clipBehavior: Clip.none,
          children: [
            layer(VistaAssets.chartDotLattice, Offset.zero & _canvas),
            layer(
              VistaAssets.chartAboveEntry,
              const Rect.fromLTWH(-5, -6, 370, 238.043),
            ),
            layer(
              VistaAssets.chartBelowEntry,
              const Rect.fromLTWH(-5, _entryY, 370, 176.957),
            ),
          ],
        );

        return ClipRect(
          child: AnimatedBuilder(
            animation: _trace,
            builder: (context, _) {
              final ms = _ms;
              final t = ReplayTimeline.progressAt(ms);
              final tip = _tipAt(t);
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
              final belowEntry = tip.dy > _entryY;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  layer(
                    VistaAssets.chartBaseline,
                    const Rect.fromLTWH(0, _entryY - 0.5, 360, 1),
                  ),
                  if (candles)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ReplayCandles(t: t, sx: sx, sy: sy),
                      ),
                    )
                  else
                    Positioned.fill(
                      child: ClipRect(
                        clipper: _RevealClipper(
                          t >= 1 ? null : tip.dx * sx + 2,
                        ),
                        child: lineLayers,
                      ),
                    ),
                  marker(VistaAssets.markerEntry, entry, 10),
                  Positioned(
                    left: 12,
                    top: _entryY * sy + 8,
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
                  // Live dot: rides the tip while tracing, rests at "now".
                  if (t > 0)
                    Positioned(
                      left: tip.dx * sx - 7,
                      top: tip.dy * sy - 7,
                      child: _LiveDot(
                        tint: belowEntry ? VistaColors.short : null,
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

/// The replay path as candles: segment i opens at vertex i and closes at
/// vertex i + 1, with wicks a little past the body. Candles appear as the
/// tip reaches them; the one being formed closes at the tip. Rising candles
/// are hollow, falling ones filled, as on the trade chart.
class _ReplayCandles extends CustomPainter {
  const _ReplayCandles({required this.t, required this.sx, required this.sy});

  final double t;
  final double sx;
  final double sy;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final pos = t.clamp(0.0, 1.0) * (_line.length - 1);
    final up = Paint()..color = VistaColors.long;
    final down = Paint()..color = VistaColors.short;
    final hollow = Paint()..color = VistaColors.background;
    final outline = Paint()
      ..color = VistaColors.long
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final slot = (_line[1].dx - _line[0].dx) * sx;
    final bodyW = math.max(2.0, slot * 0.6);

    for (var i = 0; i < _line.length - 1 && i < pos; i++) {
      final open = _line[i].dy;
      // Formed candles close on the next vertex; the forming one at the tip.
      final close = i + 1 <= pos ? _line[i + 1].dy : _tipAt(t).dy;
      // Canvas y grows downward, so a lower y is a higher price.
      final rising = close <= open;
      // Wicks reach past the body by a share of its size, deterministically.
      final reach = (open - close).abs() * 0.35 + 3 + (i % 3) * 1.5;
      final top = math.min(open, close);
      final bottom = math.max(open, close);
      final cx = (_line[i].dx + _line[i + 1].dx) / 2 * sx;

      canvas.drawRect(
        Rect.fromLTRB(
          cx - 0.5,
          (top - reach) * sy,
          cx + 0.5,
          (bottom + reach * 0.8) * sy,
        ),
        rising ? up : down,
      );
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
      old.t != t || old.sx != sx || old.sy != sy;
}

/// Clips to the left of [right]; null means no reveal clip.
class _RevealClipper extends CustomClipper<Rect> {
  const _RevealClipper(this.right);

  final double? right;

  @override
  Rect getClip(Size size) {
    final r = right;
    // Generous bounds so the layers' own overhang is only cut by the outer
    // chart clip, never by the reveal once finished.
    if (r == null) return const Rect.fromLTRB(-1e4, -1e4, 1e4, 1e4);
    return Rect.fromLTRB(-1e4, -1e4, r, 1e4);
  }

  @override
  bool shouldReclip(_RevealClipper old) => old.right != right;
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
