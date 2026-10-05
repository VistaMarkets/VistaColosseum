/// Spacing scale (logical pixels).
abstract final class VistaSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;
  static const double xxl = 14;

  /// Horizontal page gutter.
  static const double gutter = 16;
}

/// Corner radii.
abstract final class VistaRadius {
  static const double hairline = 2;
  static const double sm = 6;
  static const double md = 8;
  static const double card = 20;

  /// Top corners of a bottom sheet.
  static const double sheet = 24;
  static const double pill = 999;
}

/// Component sizes shared across screens.
abstract final class VistaSize {
  /// Minimum tap target (iOS HIG 44pt; Android's 48dp is met by 46+ rows).
  static const double tapTarget = 44;
  static const double pillButton = 46;
  static const double railButton = 52;
  static const double navBar = 64;
  static const double navItem = 48;
  static const double icon = 24;
  static const double actionIcon = 27;
  static const double avatarLarge = 40;
  static const double avatar = 32;
  static const double listLeading = 30;
  static const double avatarSmall = 22;
  static const double avatarXs = 18;
}
