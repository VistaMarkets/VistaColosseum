import 'package:flutter/painting.dart';

/// Colour tokens for the Vista dark theme.
///
/// Source: Figma file yIxjFkwJAwBa07RgSmVv1D — Home (301:102) and Portfolio
/// (174:110). The file defines no Figma variables, so these names are derived
/// from how each value is used in those frames.
abstract final class VistaColors {
  // Surfaces, darkest to lightest. Neutral greys with a slight cool tint
  // (blue a few points over red) so they sit with the blue/green brand.
  // Was #161616 / #1F1F1F / #333333 / #858585 in Figma.
  static const Color background = Color(0xFF16171A);
  // One clear step above the page so cards read as cards (Figma's #1F1F1F
  // was ~3% lighter than the page and cards blended in).
  static const Color surface = Color(0xFF24262B);
  static const Color surfaceOverlay = Color(0xEB24262B); // surface at 92%
  static const Color surfaceRaised = Color(0xFF33363D);

  /// The nav's selected pill: dark enough that its white label reads at
  /// ~8:1 (the Figma #858585 gave 3.7:1).
  static const Color surfaceSelected = Color(0xFF4A4E57);

  // Text.
  static const Color textPrimary = Color(0xFFF5F3FF);
  static const Color textSecondary = Color(0xFFA0A2A9);
  static const Color textTertiary = Color(0xFFB0B2B8);

  /// Quiet text. Light enough for small text on cards and chips (~5:1 on
  /// surface, ~4.5:1 on surfaceRaised); Figma's #858585 fell below that.
  static const Color textMuted = Color(0xFF9A9CA2);
  static const Color textInactive = Color(0x99FFFFFF); // white at 60%
  static const Color textFaint = Color(0x73FFFFFF); // white at 45%
  static const Color textPlaceholder = Color(0xFF5E6068);
  static const Color textChip = Color(0xFFA0A2A8); // unselected sort chips
  static const Color onAccent = Color(0xFFFFFFFF);

  /// Near-black text on light fills (e.g. "Make a call").
  static const Color ink = Color(0xFF0B0B0B);

  // Lines.
  static const Color divider = Color(0x33FFFFFF); // white at 20%

  /// Behind every bottom sheet: black at 45%.
  static const Color scrim = Color(0x73000000);
  static const Color hairline = Color(0x14FFFFFF); // white at 8%

  // Brand and trade direction.
  static const Color accent = Color(0xFF5AA6DE);
  static const Color accentTint = Color(0x385AA6DE); // accent at 22%

  /// Favourite stars.
  static const Color favorite = Color(0xFFF2B35A);

  /// Fee earnings and open (unsettled) calls.
  static const Color fees = Color(0xFF9685E0);
  static const Color long = Color(0xFF34D399);
  static const Color short = Color(0xFFF16082);
}
