import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'tokens/vista_colors.dart';
import 'tokens/vista_typography.dart';

/// App-wide Material theme built from the Vista tokens.
abstract final class VistaTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: VistaColors.accent,
      onPrimary: VistaColors.onAccent,
      secondary: VistaColors.long,
      error: VistaColors.short,
      surface: VistaColors.background,
      onSurface: VistaColors.textPrimary,
      surfaceContainer: VistaColors.surface,
      surfaceContainerHigh: VistaColors.surfaceRaised,
      outline: VistaColors.divider,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: VistaColors.background,
      fontFamily: VistaType.fontFamily,
      splashFactory: NoSplash.splashFactory,
      // One page transition everywhere: the iOS slide, with its edge swipe.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final p in TargetPlatform.values)
            p: const CupertinoPageTransitionsBuilder(),
        },
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VistaColors.surfaceRaised,
        contentTextStyle: VistaType.body,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
