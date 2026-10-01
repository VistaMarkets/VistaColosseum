import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'vista_pressable.dart';

/// Renders an exported Figma vector at an explicit size.
class VistaIcon extends StatelessWidget {
  const VistaIcon(
    this.asset, {
    super.key,
    required this.size,
    this.height,
    this.color,
    this.semanticLabel,
  });

  final String asset;
  final double size;

  /// Height when the asset is not square; defaults to [size].
  final double? height;

  /// Recolours a single-colour glyph (e.g. selected vs unselected nav icon).
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: height ?? size,
      fit: BoxFit.contain,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}

/// Icon centred in a square tap target of at least 44×44.
class VistaIconButton extends StatelessWidget {
  const VistaIconButton({
    super.key,
    required this.asset,
    required this.semanticLabel,
    this.iconSize = 27,
    this.onPressed,
  });

  final String asset;
  final String semanticLabel;
  final double iconSize;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: VistaPressable(
        scale: 0.9,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 44,
          child: Center(child: VistaIcon(asset, size: iconSize)),
        ),
      ),
    );
  }
}
