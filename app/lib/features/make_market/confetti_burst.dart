import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../design_system/design_system.dart';

/// Confetti pieces at rest in Figma 348:1189 (402×874 frame): centre x, y,
/// rotation in degrees, shape (0 = 9×4 bar, 1 = 6×6 dot, 2 = 4×10 bar) and
/// colour. Some sit past the frame edge on purpose.
const List<(double, double, double, int, Color)> _pieces = [
  (159.1, 358.8, -48.23, 0, VistaColors.long),
  (232.8, 300.8, 143.9, 1, VistaColors.short),
  (127.5, 41.9, -105.1, 2, VistaColors.accent),
  (111.8, 310.4, -7.33, 0, VistaColors.textPrimary),
  (337.5, 199.7, -81.25, 1, VistaColors.long),
  (101.6, 251.8, 56.42, 2, VistaColors.accent),
  (-75.1, 148.8, -30.93, 0, VistaColors.long),
  (-58.7, 263.2, 20.21, 1, VistaColors.short),
  (351.3, 171.4, -144.54, 2, VistaColors.accent),
  (250.6, 68.0, -147.82, 0, VistaColors.textPrimary),
  (241.7, 342.5, -21.05, 1, VistaColors.long),
  (350.7, 46.6, -18.46, 2, VistaColors.accent),
  (348.6, 227.1, -97.03, 0, VistaColors.long),
  (225.8, 292.7, 137.1, 1, VistaColors.short),
  (28.9, 200.9, 93.34, 2, VistaColors.accent),
  (335.2, 293.0, 117.08, 0, VistaColors.textPrimary),
  (398.1, 109.7, 9.86, 1, VistaColors.long),
  (107.8, 343.7, 174.35, 2, VistaColors.accent),
  (-15.0, 205.5, -126.97, 0, VistaColors.long),
  (-0.3, 297.2, 125.04, 1, VistaColors.short),
  (370.0, 317.8, -143.17, 2, VistaColors.accent),
  (322.0, 168.0, -31.03, 0, VistaColors.textPrimary),
  (39.7, 246.8, -92.61, 1, VistaColors.long),
  (-28.6, 106.4, 161.88, 2, VistaColors.accent),
  (381.5, 107.5, -60.86, 0, VistaColors.long),
  (353.8, 192.4, 62.03, 1, VistaColors.short),
  (409.1, 109.3, -67.96, 2, VistaColors.accent),
  (37.7, 241.4, 18.89, 0, VistaColors.textPrimary),
  (366.8, 307.3, 7.72, 1, VistaColors.long),
  (183.6, 40.9, 153.97, 2, VistaColors.accent),
  (22.0, 119.0, -85.24, 0, VistaColors.long),
  (57.3, 178.9, 171.04, 1, VistaColors.short),
  (296.5, 124.6, -25.18, 2, VistaColors.accent),
  (8.9, 208.7, 139.89, 0, VistaColors.textPrimary),
  (301.6, 250.7, 153.49, 1, VistaColors.long),
  (54.8, 275.6, -136.97, 2, VistaColors.accent),
  (459.9, 256.3, 102.65, 0, VistaColors.long),
  (390.8, 174.0, -67.32, 1, VistaColors.short),
  (32.4, 220.7, 172.08, 2, VistaColors.accent),
  (129.5, 45.7, 57.95, 0, VistaColors.textPrimary),
  (213.4, 98.5, -17.89, 1, VistaColors.long),
  (245.0, 290.1, -135.97, 2, VistaColors.accent),
];

/// "anim 2 (burst)": the pieces fly out from [origin] to their resting
/// spots, spinning into place, then drift down and fade. Plays once; draws
/// nothing with reduced motion.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, required this.origin});

  /// Burst centre in Figma frame units (the market image).
  final Offset origin;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_t.isAnimating && _t.value == 0) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _t.value = 1;
      } else {
        _t.forward();
      }
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) {
          final sx = c.maxWidth / 402;
          return AnimatedBuilder(
            animation: _t,
            builder: (context, _) {
              if (_t.value >= 1) return const SizedBox.shrink();
              // 0–35%: burst out; 35–100%: drift down and fade.
              final burst = Curves.easeOutCubic.transform(
                (_t.value / 0.35).clamp(0.0, 1.0),
              );
              final settle = ((_t.value - 0.35) / 0.65).clamp(0.0, 1.0);
              final fall = Curves.easeIn.transform(settle) * 60;
              final fade = 1 - Curves.easeIn.transform(settle);
              return Opacity(
                opacity: fade,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final (x, y, rot, kind, colour) in _pieces)
                      _piece(
                        Offset.lerp(widget.origin, Offset(x, y), burst)! * sx +
                            Offset(0, fall),
                        rot * burst,
                        kind,
                        colour,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _piece(Offset centre, double degrees, int kind, Color colour) {
    final (w, h, r) = switch (kind) {
      0 => (9.0, 4.0, 1.5),
      1 => (6.0, 6.0, 3.0),
      _ => (4.0, 10.0, 1.5),
    };
    return Positioned(
      left: centre.dx - w / 2,
      top: centre.dy - h / 2,
      child: Transform.rotate(
        angle: degrees * math.pi / 180,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: colour,
            borderRadius: BorderRadius.circular(r),
          ),
        ),
      ),
    );
  }
}
