import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../profile/profile_screen.dart';
import 'arena_mock.dart';
import 'opinions_screen.dart';

/// Arena tab (Figma 33:2): battles between a Bull and a Bear caller. The
/// crowd-split filter lives in [CrowdFilterPanel], which the app shell draws
/// around the bottom nav on this tab.
class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key, this.onNotBuilt});

  /// Called with a feature name when a control leads somewhere not built yet.
  final ValueChanged<String>? onNotBuilt;

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  int _sort = 0;

  void _notBuilt(String what) => widget.onNotBuilt?.call(what);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          VistaSearchTopBar(
            hint: 'Ask about a market',
            onSubmitted: (_) => _notBuilt('Ask'),
            onBell: () => _notBuilt('Notifications'),
          ),
          // Sort chips stay put while the battles scroll.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VistaSpace.gutter,
              0,
              VistaSpace.gutter,
              VistaSpace.xs,
            ),
            child: Wrap(
              spacing: VistaSpace.md,
              children: [
                for (var i = 0; i < ArenaMock.sorts.length; i++)
                  VistaFilterChip(
                    label: ArenaMock.sorts[i],
                    accent: true,
                    selected: i == _sort,
                    onPressed: () => setState(() => _sort = i),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: VistaSpace.gutter),
              children: [
                for (final b in ArenaMock.battles)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: VistaBattleCard(
                      ticker: b.ticker,
                      price: b.price,
                      change: b.change,
                      timeLeft: b.timeLeft,
                      question: b.question,
                      bull: b.bull,
                      bear: b.bear,
                      moreOpinions: b.moreOpinions,
                      // Simulated only: joining a side places nothing.
                      onBull: () => _notBuilt('Joining Bull (simulated)'),
                      onBear: () => _notBuilt('Joining Bear (simulated)'),
                      onOpinions: () =>
                          Navigator.of(context).push(OpinionsScreen.route()),
                      onCaller: (handle) =>
                          Navigator.of(context)
                              .push(ProfileScreen.route(handle)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
