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
