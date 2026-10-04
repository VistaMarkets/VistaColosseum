import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../account/account_top_bar.dart';
import '../settings/settings_state.dart';
import '../trade/order_ticket.dart';
import '../profile/profile_screen.dart';
import 'arena_mock.dart';
import 'opinions_screen.dart';

/// Arena tab (Figma 33:2): battles between a Bull and a Bear caller.
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
          // The same account bar as Home and Portfolio.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
            child: AccountTopBar(
              onNotBuilt: widget.onNotBuilt,
              showSettings: true,
            ),
          ),
          const SizedBox(height: VistaSpace.md),
          // Sort chips stay put while the battles scroll.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VistaSpace.gutter,
              0,
              VistaSpace.gutter,
              VistaSpace.xs,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
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
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: VistaSpace.gutter),
              children: [
                for (final b in ArenaMock.battles)
                  Padding(
                    // A clear gap between battles so each reads as its own.
                    padding: const EdgeInsets.fromLTRB(
                      7,
                      0,
                      7,
                      VistaSpace.section,
                    ),
                    child: ValueListenableBuilder(
                      valueListenable: DisplayPrefs.longOnRight,
                      builder: (context, longOnRight, _) => VistaBattleCard(
                        longOnRight: longOnRight,
                        ticker: b.ticker,
                        price: b.price,
                        change: b.change,
                        timeLeft: b.timeLeft,
                        question: b.question,
                        bull: b.bull,
                        bear: b.bear,
                        moreOpinions: b.moreOpinions,
                        // Simulated only: joining a side places nothing.
                        // Bull is long the battle's market, Bear short.
                        onBull: () => showOrderTicket(
                          context,
                          symbol: b.ticker,
                          side: TradeSide.long,
                        ),
                        onBear: () => showOrderTicket(
                          context,
                          symbol: b.ticker,
                          side: TradeSide.short,
                        ),
                        onOpinions: () =>
                            Navigator.of(context).push(OpinionsScreen.route()),
                        onCaller: (handle) =>
                            Navigator.of(context)
                                .push(ProfileScreen.route(handle)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Search sits at the bottom, by the thumb and above the nav.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VistaSpace.gutter,
              VistaSpace.sm,
              VistaSpace.gutter,
              VistaSpace.sm,
            ),
            child: VistaSearchField(
              bordered: true,
              hint: 'Ask about a market',
              onChanged: (_) {},
              onSubmitted: (_) => _notBuilt('Ask'),
            ),
          ),
        ],
      ),
    );
  }
}
