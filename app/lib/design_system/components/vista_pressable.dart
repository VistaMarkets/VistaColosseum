import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../tokens/vista_motion.dart';

/// A tappable that answers the finger: it settles to [scale] and 85%
/// opacity while pressed, then springs back. Use it for every control so
/// touches feel the same everywhere (buttons 0.97, rows 0.98, icons 0.90).
/// Without [onTap] it is inert and draws [child] as is.
class VistaPressable extends StatefulWidget {
  const VistaPressable({
    super.key,
    required this.onTap,
    required this.child,
    this.scale = 0.97,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double scale;

  @override
  State<VistaPressable> createState() => _VistaPressableState();
}

class _VistaPressableState extends State<VistaPressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final down = enabled && _down;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      child: AnimatedScale(
        scale: down ? widget.scale : 1,
        duration: down ? VistaMotion.pressIn : VistaMotion.pressOut,
        curve: down ? Curves.easeOut : VistaMotion.pop,
        child: AnimatedOpacity(
          opacity: down ? 0.85 : 1,
          duration: down ? VistaMotion.pressIn : VistaMotion.pressOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Shakes [child] sideways once each time [count] goes up: the answer to a
/// tap that can't go through (an order missing an amount, say). Pair it with
/// a heavy haptic.
class VistaShake extends StatelessWidget {
  const VistaShake({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(count),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(math.sin(t * math.pi * 6) * 6 * (1 - t), 0),
        child: child,
      ),
      child: child,
    );
  }
}
