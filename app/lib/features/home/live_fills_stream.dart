import 'package:flutter/widgets.dart';

import '../../design_system/design_system.dart';
import 'active_replay.dart';
import 'mock_trade_idea.dart';

/// Stack of recent fills over the chart, oldest on top and fading with age.
///
/// Motion: when [active], fills arrive one at a time at the bottom, rising
/// into place and pushing older fills up a row as each dims to its age's
/// opacity. The finished state is the static design.
class LiveFillsStream extends StatefulWidget {
  const LiveFillsStream({super.key, required this.fills, this.active = true});

  /// Oldest first.
  final List<LiveFill> fills;
  final bool active;

  @override
  State<LiveFillsStream> createState() => _LiveFillsStreamState();
}

/// Opacity by age: newest, one behind, two or more behind.
const List<double> _ageOpacity = [1, 0.65, 0.35];

/// Timeline, as fractions of the whole: first arrival, spacing, and how long
/// each arrival takes.
const double _firstArrival = 0.12;
const double _arrivalGap = 0.3;
const double _arrivalLength = 0.22;

/// Distance a fill rises as it arrives.
const double _rise = 10;

class _LiveFillsStreamState extends State<LiveFillsStream>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        ActiveReplay<LiveFillsStream> {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  @override
  AnimationController get replay => _clock;

  @override
  bool isActive(LiveFillsStream widget) => widget.active;

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  /// 0 → 1 as fill [i] arrives.
  double _arrived(int i) {
    final start = _firstArrival + _arrivalGap * i;
    final t = ((_clock.value - start) / _arrivalLength).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(t);
  }

  /// Opacity for a fill with [newer] (fractional) fills arrived after it.
  static double _opacityFor(double newer) {
    final last = _ageOpacity.length - 1;
    if (newer >= last) return _ageOpacity[last];
    final i = newer.floor();
    final f = newer - i;
    return _ageOpacity[i] + (_ageOpacity[i + 1] - _ageOpacity[i]) * f;
  }

  @override
  Widget build(BuildContext context) {
    final fills = widget.fills;
    return AnimatedBuilder(
      animation: _clock,
      builder: (context, _) {
        final arrived = [for (var i = 0; i < fills.length; i++) _arrived(i)];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < fills.length; i++) ...[
              if (i > 0) const SizedBox(height: VistaSpace.sm),
              _row(fills[i], arrived[i], arrived.skip(i + 1)),
            ],
          ],
        );
      },
    );
  }

  /// One fill, laid out in its final row and shifted down by however many
  /// newer fills have yet to arrive beneath it.
  Widget _row(LiveFill fill, double arrived, Iterable<double> newer) {
    if (arrived <= 0) {
      // Keep the row's space so the finished layout never jumps.
      return Visibility.maintain(visible: false, child: _pill(fill));
    }
    final newerArrived = newer.fold(0.0, (a, b) => a + b);
    final rowsBelow = newer.length - newerArrived;
    final opacity = arrived * _opacityFor(newerArrived);
    return Opacity(
      opacity: opacity,
      child: FractionalTranslation(
        // One row = the pill's own height plus the gap.
        translation: Offset(0, rowsBelow),
        child: Transform.translate(
          offset: Offset(0, rowsBelow * VistaSpace.sm + _rise * (1 - arrived)),
          child: _pill(fill),
        ),
      ),
    );
  }

  Widget _pill(LiveFill fill) => VistaActivityPill(
    avatarAsset: fill.avatar,
    message: fill.message,
    amount: fill.amount,
    side: fill.side,
  );
}
