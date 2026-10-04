import 'package:flutter/widgets.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_typography.dart';

/// A figure whose changed digits roll to their new value (Figma 108:125,
/// "Live number · B — rolling digits").
///
/// When [text] changes, each digit that differs (aligned from the right)
/// rolls over 240ms: on a rise the old digit slides up and out while the new
/// one rises in from below in the positive colour; on a fall it rolls the
/// other way in the negative colour. The new digits then settle back to the
/// style's colour. Unchanged characters never move. Digits use tabular
/// figures so the number doesn't shift sideways as it ticks. With reduced
/// motion the new value simply replaces the old.
class VistaRollingNumber extends StatefulWidget {
  const VistaRollingNumber(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<VistaRollingNumber> createState() => _VistaRollingNumberState();
}

/// Numeric value of a formatted figure ("$12,480", "−$13", "+1.20%").
double? _valueOf(String s) {
  final negative = s.contains('−') || s.contains('-');
  final digits = s.replaceAll(RegExp(r'[^0-9.]'), '');
  final v = double.tryParse(digits);
  if (v == null) return null;
  return negative ? -v : v;
}

bool _isDigit(String c) => c.compareTo('0') >= 0 && c.compareTo('9') <= 0;

class _VistaRollingNumberState extends State<VistaRollingNumber>
    with TickerProviderStateMixin {
  /// 0 → 1 as changed digits roll (240ms, per the Figma timeline).
  late final AnimationController _roll = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  /// 1 → 0 as the new digits' tint fades back to the text colour.
  late final AnimationController _tint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  String _from = '';
  bool _up = true;

  @override
  void initState() {
    super.initState();
    _from = widget.text;
    _roll.value = 1;
  }

  @override
  void didUpdateWidget(VistaRollingNumber old) {
    super.didUpdateWidget(old);
    if (old.text == widget.text) return;
    final a = _valueOf(old.text), b = _valueOf(widget.text);
    _up = a == null || b == null || b >= a;
    _from = old.text;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _roll.value = 1;
      _tint.value = 0;
      return;
    }
    _roll.forward(from: 0);
    _tint.forward(from: 0);
  }

  @override
  void dispose() {
    _roll.dispose();
    _tint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = VistaType.figures(widget.style);
    final to = widget.text;
    // Right-align old and new so digits line up by place value.
    final pad = to.length - _from.length;
    final from = pad >= 0 ? ' ' * pad + _from : _from.substring(-pad);

    return Semantics(
      label: to,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: Listenable.merge([_roll, _tint]),
        builder: (context, _) {
          // At rest it is plain text; digit cells exist only mid-change.
          if (!_roll.isAnimating && !_tint.isAnimating) {
            return Text(to, style: base);
          }
          final p = Curves.easeInOut.transform(_roll.value);
          // Hold the tint while rolling, then ease it out.
          final fade = (_tint.value * 900 - 240).clamp(0, 660) / 660;
          final tint = Color.lerp(
            _up ? VistaColors.long : VistaColors.short,
            base.color,
            _tint.isAnimating ? Curves.easeIn.transform(fade) : 1,
          );
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              for (var i = 0; i < to.length; i++)
                _cell(to[i], from[i], p, base, tint),
            ],
          );
        },
      ),
    );
  }

  Widget _cell(
    String next,
    String prev,
    double p,
    TextStyle base,
    Color? tint,
  ) {
    final changed = next != prev && _isDigit(next) && _roll.value < 1;
    final settledTint = next != prev && _isDigit(next) ? tint : base.color;
    if (!changed) {
      return Text(next, style: base.copyWith(color: settledTint));
    }
    // A window one line tall: the laid-out new digit sets its size.
    final dir = _up ? 1.0 : -1.0;
    return ClipRect(
      child: Stack(
        children: [
          Opacity(opacity: 0, child: Text(next, style: base)),
          Positioned.fill(
            child: FractionalTranslation(
              translation: Offset(0, -dir * p),
              child: Text(prev.trim(), style: base),
            ),
          ),
          Positioned.fill(
            child: FractionalTranslation(
              translation: Offset(0, dir * (1 - p)),
              child: Text(next, style: base.copyWith(color: tint)),
            ),
          ),
        ],
      ),
    );
  }
}
