import 'package:flutter/material.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_motion.dart';

/// Shows a bottom sheet the one way the app does: the same scrim, top
/// radius and rise (380ms easeOutQuint in, 240ms out). Pass [color] to have
/// the sheet draw its own surface and corners; otherwise the content draws
/// them. [scrollControlled] lets a tall sheet take the height it needs.
Future<T?> showVistaSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool scrollControlled = true,
  Color? color,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: scrollControlled,
    backgroundColor: color ?? Colors.transparent,
    barrierColor: VistaColors.scrim,
    shape: color == null
        ? null
        : const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(VistaRadius.sheet),
            ),
          ),
    clipBehavior: color == null ? null : Clip.antiAlias,
    sheetAnimationStyle: const AnimationStyle(
      duration: VistaMotion.sheetIn,
      reverseDuration: VistaMotion.sheetOut,
      curve: VistaMotion.sheet,
    ),
    builder: builder,
  );
}
