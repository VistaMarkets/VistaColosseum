import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import 'arena_mock.dart';

/// Raised sheet at the bottom of the Arena ("Crowd filter · C — histogram")
/// that wraps the bottom nav: a crowd-split label with the battle count, a
/// histogram of battles by split, and a range slider picking which splits
/// to show. It reads and writes [Scenario.arena], as the list does, so its
/// count is the cards shown.
class CrowdFilterPanel extends StatelessWidget {
  const CrowdFilterPanel({super.key});

  static const _n = ArenaMock.bucketCount;

  /// Majority share at a slider position: 0 → 50, 1 → 100.
  static int _split(double v) => (50 + v * 50).round();

  static String _label(RangeValues r) {
    final lo = _split(r.start);
    if (r.end >= 1) return 'Crowd split $lo/${100 - lo} +';
    final hi = _split(r.end);
    return 'Crowd split $lo/${100 - lo} – $hi/${100 - hi}';
  }

  /// The panel's content. The app shell draws the sheet around it and the
  /// bottom nav under it, and folds it away off the Arena tab.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Scenario.arena,
      builder: (context, view, _) {
        final range = RangeValues(view.from / _n, view.to / _n);
        final count = ArenaMock.visible(view).length;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text(_label(range), style: VistaType.subhead)),
                Text(
                  '$count battle${count == 1 ? '' : 's'}',
                  style: VistaType.bodyMedium.copyWith(
                    color: VistaColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: VistaSpace.lg),
            VistaHistogram(
              values: ArenaMock.buckets(view.query),
              selected: (view.from, view.to - 1),
            ),
            const SizedBox(height: VistaSpace.lg),
            VistaRangeSlider(
              values: range,
              divisions: _n,
              semanticFormatter: (v) => '${_split(v)} percent majority',
              onChanged: (v) => Scenario.setArena(
                from: (v.start * _n).round(),
                to: (v.end * _n).round(),
              ),
            ),
            const SizedBox(height: VistaSpace.lg),
          ],
        );
      },
    );
  }
}
