import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../calls/calls_store.dart';
import 'arena_mock.dart';
import 'opinions_screen.dart';
import 'take_card.dart';

/// Every live battle, opened from "See all" on the Arena tab: the carousel's
/// tiles as flush full-width rows, sortable by takes, time left or how
/// evenly the crowd is split. A row opens the battle.
class LiveBattlesScreen extends StatefulWidget {
  const LiveBattlesScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const LiveBattlesScreen());

  @override
  State<LiveBattlesScreen> createState() => _LiveBattlesScreenState();
}

class _LiveBattlesScreenState extends State<LiveBattlesScreen> {
  int _sort = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: BattlesStore.all,
      builder: (context, all, _) =>
          _page(context, ArenaMock.sortedBattles(_sort, all)),
    );
  }

  Widget _page(BuildContext context, List<LiveBattle> battles) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.md,
                VistaSpace.gutter + VistaSpace.xs,
                VistaSpace.md,
              ),
              child: Row(
                children: [
                  VistaIconButton(
                    asset: VistaAssets.backSmall,
                    semanticLabel: 'Back',
                    iconSize: VistaSize.icon,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: VistaSpace.xs),
                  Expanded(child: Text('Live battles', style: VistaType.title)),
                  Text(
                    '${battles.length} live',
                    style: VistaType.bodyMedium.copyWith(
                      color: VistaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Sort chips stay put while the list scrolls.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                0,
                VistaSpace.gutter,
                VistaSpace.xs,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < ArenaMock.battleSorts.length; i++) ...[
                    if (i > 0) const SizedBox(width: VistaSpace.md),
                    VistaFilterChip(
                      label: ArenaMock.battleSorts[i],
                      accent: true,
                      selected: i == _sort,
                      onPressed: () => setState(() => _sort = i),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(
                  bottom:
                      VistaSpace.gutter + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  for (final b in battles)
                    BattleTile.row(
                      key: ValueKey(b.question),
                      battle: b,
                      onTap: () =>
                          Navigator.of(context).push(OpinionsScreen.route()),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
