import 'package:flutter/painting.dart';

/// Colour tokens for the Vista dark theme.
///
/// Source: Figma file yIxjFkwJAwBa07RgSmVv1D — Home (301:102) and Portfolio
/// (174:110). The file defines no Figma variables, so these names are derived
/// from how each value is used in those frames.
abstract final class VistaColors {
  // Surfaces, darkest to lightest.
  static const Color background = Color(0xFF161616);
  static const Color surface = Color(0xFF1F1F1F);
  static const Color surfaceOverlay = Color(0xEB1F1F1F); // surface at 92%
  static const Color surfaceRaised = Color(0xFF333333);
  static const Color surfaceSelected = Color(0xFF858585);

  // Text.
  static const Color textPrimary = Color(0xFFF5F3FF);
  static const Color textSecondary = Color(0xFF8A8A91);
  static const Color textTertiary = Color(0xFFA3A3A3);
  static const Color textMuted = Color(0xFF858585);
  static const Color textInactive = Color(0x99FFFFFF); // white at 60%
  static const Color textFaint = Color(0x73FFFFFF); // white at 45%
  static const Color textPlaceholder = Color(0xFF5D5C5C);
  static const Color textChip = Color(0xFF999999); // unselected sort chips
  static const Color onAccent = Color(0xFFFFFFFF);

  /// Near-black text on light fills (e.g. "Make a call").
  static const Color ink = Color(0xFF0B0B0B);

  // Lines.
  static const Color divider = Color(0x33FFFFFF); // white at 20%
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
