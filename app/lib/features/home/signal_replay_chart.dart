import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/design_system.dart';
import 'active_replay.dart';

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
/// A head dot rides the tip, the fills reveal behind it, and each event marker
/// and label pops in as the tip reaches it. The finished frame is the static
/// design exactly.
class SignalReplayChart extends StatefulWidget {
  const SignalReplayChart({
    super.key,
    this.active = true,
    this.duration = const Duration(milliseconds: 1800),
  });

  /// Whether this chart is the one on screen. Becoming active replays the
  /// trace; becoming inactive resets it so the next visit replays too.
  final bool active;
  final Duration duration;

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

/// Canvas distance the tip travels past a point while its marker pops in.
const double _popDistance = 18;

class _SignalReplayChartState extends State<SignalReplayChart>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        ActiveReplay<SignalReplayChart> {
  late final AnimationController _trace = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _trace,
    curve: Curves.easeInOutCubic,
  );

  @override
  AnimationController get replay => _trace;

  @override
  bool isActive(SignalReplayChart widget) => widget.active;

  @override
  void dispose() {
    _trace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

        const funding = Offset(152.09, 328.8);
        const whale = Offset(248.34, 193.6);
        const breakout = Offset(329.79, 60.17);
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
            animation: _progress,
            builder: (context, _) {
              final t = _progress.value;
              final tip = _tipAt(t);
              double reached(Offset p) =>
                  ((tip.dx - p.dx) / _popDistance + 1).clamp(0.0, 1.0);
              final belowEntry = tip.dy > _entryY;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  layer(
                    VistaAssets.chartBaseline,
                    const Rect.fromLTWH(0, _entryY - 0.5, 360, 1),
                  ),
                  Positioned.fill(
                    child: ClipRect(
                      clipper: _RevealClipper(t >= 1 ? null : tip.dx * sx + 2),
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
                  marker(
                    VistaAssets.markerFunding,
                    funding,
                    12,
                    pop: reached(funding),
                  ),
                  if (roomy)
                    labelAbove(
                      funding,
                      const VistaTag(label: 'Funding flipped +'),
                      pop: reached(funding),
                    ),
                  marker(
                    VistaAssets.markerWhale,
                    whale,
                    12,
                    pop: reached(whale),
                  ),
                  if (roomy)
                    labelAbove(
                      whale,
                      const VistaTag(label: r'Whale long $4.2M'),
                      pop: reached(whale),
                    ),
                  marker(
                    VistaAssets.markerBreakoutHalo,
                    breakout,
                    26,
                    pop: reached(breakout),
                  ),
                  marker(
                    VistaAssets.markerBreakout,
                    breakout,
                    12,
                    pop: reached(breakout),
                  ),
                  labelAbove(
                    breakout,
                    const VistaTag(
                      label: r'Broke $2,950',
                      color: VistaColors.long,
                      textColor: VistaColors.onAccent,
                    ),
                    pop: reached(breakout),
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
      opacity: value,
      child: Transform.scale(
        scale: Curves.easeOutBack.transform(value),
        child: child,
      ),
    );
  }
}

/// Fades a label in while it rises 6px into place.
class _Rise extends StatelessWidget {
  const _Rise({required this.value, required this.child});

  final double value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (value >= 1) return child;
    if (value <= 0) return const SizedBox.shrink();
    return Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 6 * (1 - value)),
        child: child,
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
