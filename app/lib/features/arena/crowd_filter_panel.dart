import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import 'arena_mock.dart';

/// Raised sheet at the bottom of the Arena ("Crowd filter · C — histogram")
/// that wraps the bottom nav: a crowd-split label with the battle count, a
/// histogram of battles by split, and a range slider picking which splits
/// to show.
class CrowdFilterPanel extends StatefulWidget {
  const CrowdFilterPanel({super.key});

  @override
  State<CrowdFilterPanel> createState() => _CrowdFilterPanelState();
}

class _CrowdFilterPanelState extends State<CrowdFilterPanel> {
  static const _buckets = ArenaMock.crowdBuckets;
  RangeValues _range = const RangeValues(ArenaMock.defaultStart, 1);

  (int, int) get _selected {
    final n = _buckets.length;
    return ((_range.start * n).round(), (_range.end * n).round() - 1);
  }

  /// Majority share at a slider position: 0 → 50, 1 → 100.
  static int _split(double v) => (50 + v * 50).round();

  String get _label {
    final lo = _split(_range.start);
    if (_range.end >= 1) return 'Crowd split $lo/${100 - lo} +';
    final hi = _split(_range.end);
    return 'Crowd split $lo/${100 - lo} – $hi/${100 - hi}';
  }

  int get _count {
    final (a, b) = _selected;
    var sum = 0.0;
    for (var i = a; i <= b; i++) {
      sum += _buckets[i];
    }
    return sum.round();
  }

  /// The panel's content. The app shell draws the sheet around it and the
  /// bottom nav under it, and folds it away off the Arena tab.
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Text(_label, style: VistaType.subhead)),
            Text(
              '$_count battles',
              style: VistaType.bodyMedium.copyWith(
                color: VistaColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: VistaSpace.lg),
        VistaHistogram(values: _buckets, selected: _selected),
        const SizedBox(height: VistaSpace.lg),
        VistaRangeSlider(
          values: _range,
          divisions: _buckets.length,
          semanticFormatter: (v) => '${_split(v)} percent majority',
          onChanged: (v) => setState(() => _range = v),
        ),
        const SizedBox(height: VistaSpace.lg),
      ],
    );
  }
}
