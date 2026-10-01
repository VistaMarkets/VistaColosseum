import 'package:flutter/painting.dart';

import 'vista_colors.dart';

/// Type scale. Figma uses SF Pro Rounded; the app ships Open Runde (OFL) so the
/// same face renders on iOS and Android.
abstract final class VistaType {
  static const String fontFamily = 'OpenRunde';

  static const TextStyle _base = TextStyle(
    fontFamily: fontFamily,
    color: VistaColors.textPrimary,
    height: 1.2,
  );

  /// 36 Bold — hero balance.
  static final TextStyle display = _base.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w700,
  );

  /// 20 Bold — headline numbers (price).
  static final TextStyle displayNumber = _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  /// 20 Semibold, tight leading — card question / thesis.
  static final TextStyle title = _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.15,
  );

  /// 17 Bold — asset ticker, pill button labels.
  static final TextStyle headline = _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );

  /// 17 Semibold — segmented tab labels.
  static final TextStyle tab = _base.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  /// 15 Semibold — list titles and profile handle.
  static final TextStyle subhead = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  /// 15 Medium — section captions ("My portfolio").
  static final TextStyle subheadMuted = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: VistaColors.textTertiary,
  );

  /// 15 Bold — selected bottom-nav label.
  static final TextStyle navLabel = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  /// 13 Semibold — handles and usernames.
  static final TextStyle body = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  /// 13 Bold — emphasised secondary numbers (change since call).
  static final TextStyle bodyStrong = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  /// 13 Medium — secondary figures and unselected segments.
  static final TextStyle bodyMedium = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  /// 13 Regular — muted descriptive text.
  static final TextStyle bodyRegular = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: VistaColors.textMuted,
  );

  /// 12 Semibold — activity pills.
  static final TextStyle chip = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  /// 11 Semibold — counts and small labels.
  static final TextStyle label = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  /// 11 Bold — badges and chart event labels.
  static final TextStyle labelStrong = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  /// 11 Regular — secondary descriptors (asset name).
  static final TextStyle caption = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: VistaColors.textSecondary,
  );

  /// 11 Medium — timestamps.
  static final TextStyle meta = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: VistaColors.textSecondary,
  );

  /// 10 Bold — dense chart annotations.
  static final TextStyle micro = _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );
}
