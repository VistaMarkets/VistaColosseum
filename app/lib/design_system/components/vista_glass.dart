import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';

/// A floating frosted-glass pill (the nav, the bottom search): whatever
/// scrolls underneath is blurred and tinted with the card colour, so it
/// shows as a soft wash rather than legible text; a hairline edge and a
/// soft shadow lift it off the page. Nothing else sits behind it.
class VistaGlass extends StatelessWidget {
  const VistaGlass({
    super.key,
    required this.child,
    this.height,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;

  static final _radius = BorderRadius.circular(VistaRadius.pill);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: VistaColors.surface.withValues(alpha: 0.82),
              borderRadius: _radius,
              border: Border.all(color: VistaColors.hairline),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
