import 'package:flutter/animation.dart';

/// Motion standards: one set of durations and curves for the whole app.
abstract final class VistaMotion {
  /// A control pressing down, and springing back.
  static const pressIn = Duration(milliseconds: 90);
  static const pressOut = Duration(milliseconds: 160);

  /// Small state changes: colour, underline, chip selection.
  static const state = Duration(milliseconds: 180);

  /// Sheets rising and falling.
  static const sheetIn = Duration(milliseconds: 380);
  static const sheetOut = Duration(milliseconds: 240);

  /// A live value easing to its new figure (charts, levels).
  static const live = Duration(milliseconds: 450);

  /// How long a confirmed action shows its result before the sheet closes.
  static const confirmHold = Duration(milliseconds: 450);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const sheet = Curves.easeOutQuint;

  /// Small pops only (a like, a marker).
  static const pop = Curves.easeOutBack;
}
