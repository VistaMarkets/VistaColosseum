import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../account/account_top_bar.dart';
import '../calls/calls_store.dart';
import '../profile/profile_screen.dart';
import '../trade/caller_play_screen.dart';
import '../trade/order_ticket.dart';
import 'arena_mock.dart';
import 'live_battles_screen.dart';
import 'opinions_screen.dart';
import 'pick_position_screen.dart';
import 'take_card.dart';

/// Arena tab (Figma 505:204, "Arena — takes feed"): live battles in a
/// sideways carousel, then an X-style feed of takes. A take is either on a
/// battle (with a chip linking it) or a plain call on a market (no chip);
/// backed takes carry their position.
class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key, this.onNotBuilt});

  /// Called with a feature name when a control leads somewhere not built yet.
  final ValueChanged<String>? onNotBuilt;

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  /// Height the floating + button takes above the nav (button plus margins).
  static const double _composerSpace = 68;

  int _sort = 0;

  void _push(Route<void> route) => Navigator.of(context).push(route);

  /// The + : pick the position to back the take, write it, post it. The
  /// new take goes to the top of the feed.
  Future<void> _newTake() async {
    final take = await Navigator.of(context).push(PickPositionScreen.route());
    if (take != null) CallsStore.add(take);
  }

  @override
  Widget build(BuildContext context) {
    // The list runs to the bottom of the screen and scrolls under the
    // floating + button and nav, which sit over it with nothing behind them.
    final navSpace = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            children: [
              // The same account bar as Home and Portfolio.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VistaSpace.gutter,
                ),
                child: AccountTopBar(
                  onNotBuilt: widget.onNotBuilt,
                  showSettings: true,
                ),
              ),
              const SizedBox(height: VistaSpace.md),
              // Sort chips stay put while the feed scrolls. One row that
              // scrolls sideways when the chips outrun the screen.
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
                    for (var i = 0; i < ArenaMock.sorts.length; i++) ...[
                      if (i > 0) const SizedBox(width: VistaSpace.md),
                      VistaFilterChip(
                        label: ArenaMock.sorts[i],
                        accent: true,
                        selected: i == _sort,
                        onPressed: () => setState(() => _sort = i),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                // Every call, shared with the trade pages' Callers.
                child: ValueListenableBuilder(
                  valueListenable: CallsStore.all,
                  builder: (context, takes, _) => ListView(
                    // Room to scroll the last take clear of the + button and
                    // nav.
                    padding: EdgeInsets.only(
                      bottom: VistaSpace.gutter + _composerSpace + navSpace,
                    ),
                    children: [
                      ArenaSectionHead(
                        title: 'Live battles',
                        // "See all" sits in a 44pt tap row; the head's
                        // padding gives back the extra height.
                        top: VistaSpace.md,
                        bottom: 0,
                        trailing: Semantics(
                          button: true,
                          label: 'See all live battles',
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _push(LiveBattlesScreen.route()),
                            child: SizedBox(
                              height: VistaSize.tapTarget,
                              child: Center(
                                child: Text(
                                  'See all',
                                  style: VistaType.subhead.copyWith(
                                    color: VistaColors.accent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: VistaSpace.gutter,
                        ),
                        // Tiles share the tallest one's height.
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, b)
                                  in BattlesStore.all.value
                                      .take(3)
                                      .indexed) ...[
                                if (i > 0) const SizedBox(width: VistaSpace.lg),
                                BattleTile(
                                  battle: b,
                                  onTap: () => _push(OpinionsScreen.route()),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      ArenaSectionHead(
                        title: 'Calls',
                        trailing: Text(
                          'Backed first',
                          style: VistaType.bodyMedium.copyWith(
                            color: VistaColors.textMuted,
                          ),
                        ),
                      ),
                      for (final t in takes)
                        TakeItem(
                          take: t,
                          onCaller: () => _push(ProfileScreen.route(t.handle)),
                          onBattle: () => _push(OpinionsScreen.route()),
                          onCall: t.call == null
                              ? null
                              : () => _push(
                                  CallerPlayScreen.route(
                                    CallsStore.postOf(t),
                                    t.ticker,
                                  ),
                                ),
                          // Simulated only: joining places nothing real.
                          onJoin: () => showOrderTicket(
                            context,
                            symbol: t.ticker,
                            side: t.side,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // The + floats in the lower right, just above the nav.
          Positioned(
            right: VistaSpace.gutter,
            bottom: navSpace + VistaSpace.md,
            child: _AddTakeButton(onTap: _newTake),
          ),
        ],
      ),
    );
  }
}

/// The floating + in the lower right: starts a take by picking a position.
class _AddTakeButton extends StatelessWidget {
  const _AddTakeButton({required this.onTap});

  static const double size = 56;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Make a call',
      excludeSemantics: true,
      child: VistaPressable(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: VistaColors.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x59000000),
                offset: Offset(0, 6),
                blurRadius: 18,
              ),
            ],
          ),
          child: Text(
            '+',
            style: VistaType.displayMedium.copyWith(
              color: VistaColors.onAccent,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
