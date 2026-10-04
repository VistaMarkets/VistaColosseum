import 'package:flutter/painting.dart';

import 'vista_colors.dart';

/// Type scale. Figma uses SF Pro Rounded; the app ships Open Runde (OFL) so the
/// same face renders on iOS and Android.
abstract final class VistaType {
  static const String fontFamily = 'OpenRunde';

  /// Open Runde with fixed-width digits (Open Runde has no `tnum`), so
  /// numbers don't shift sideways as they tick and columns line up. Same
  /// shapes; only the digits' spacing differs.
  static const String numberFamily = 'OpenRundeTabular';

  /// [style] set in the number face, for prices, sizes and P/L.
  static TextStyle figures(TextStyle style) => style.copyWith(
    fontFamily: numberFamily,
    fontFeatures: _fixedSpacing,
  );

  /// Kerning off for numbers: the face's kern pairs (e.g. "1,") would
  /// otherwise make equal-width digits set at different widths.
  static const _fixedSpacing = [FontFeature.disable('kern')];

  static const TextStyle _base = TextStyle(
    fontFamily: fontFamily,
    color: VistaColors.textPrimary,
    height: 1.2,
  );

  /// 36 Bold — hero balance.
  static final TextStyle display = _base.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    fontFamily: numberFamily,
    fontFeatures: _fixedSpacing,
  );

  /// 20 Bold — headline numbers (price).
  /// Hero figures between display (36) and displayNumber (20): a market's
  /// price or cap (32), avatars' initials and big stats (26), headline
  /// changes (24).
  static final TextStyle displayLarge = _base.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontFamily: numberFamily,
    fontFeatures: _fixedSpacing,
  );
  static final TextStyle displayMedium = _base.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    fontFamily: numberFamily,
    fontFeatures: _fixedSpacing,
  );
  static final TextStyle displaySmall = _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: numberFamily,
    fontFeatures: _fixedSpacing,
  );

  static final TextStyle displayNumber = _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontFamily: numberFamily,
    fontFeatures: _fixedSpacing,
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
  /// 14pt list rows and ticket rows (between body 13 and subhead 15).
  static final TextStyle row = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static final TextStyle rowStrong = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle rowMedium = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static final TextStyle rowRegular = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

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
