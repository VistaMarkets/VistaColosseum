import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../account/account_top_bar.dart';
import '../profile/profile_screen.dart';
import '../trade/caller_play_screen.dart';
import '../trade/order_ticket.dart';
import 'arena_mock.dart';
import 'live_battles_screen.dart';
import 'opinions_screen.dart';
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
  /// Height the floating composer takes above the nav (pill plus margins).
  static const double _composerSpace = 60;

  int _sort = 0;

  void _notBuilt(String what) => widget.onNotBuilt?.call(what);

  void _push(Route<void> route) => Navigator.of(context).push(route);

  @override
  Widget build(BuildContext context) {
    // The list runs to the bottom of the screen and scrolls under the
    // floating composer and nav, which sit over it with nothing behind them.
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
                child: ListView(
                  // Room to scroll the last take clear of the composer and
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
                                in ArenaMock.battles.take(3).indexed) ...[
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
                      title: 'Takes',
                      trailing: Text(
                        'Backed first',
                        style: VistaType.bodyMedium.copyWith(
                          color: VistaColors.textMuted,
                        ),
                      ),
                    ),
                    for (final t in ArenaMock.takes)
                      TakeItem(
                        take: t,
                        onCaller: () => _push(ProfileScreen.route(t.handle)),
                        onBattle: () => _push(OpinionsScreen.route()),
                        onCall: t.call == null
                            ? null
                            : () => _push(
                                CallerPlayScreen.route(t.call!, t.ticker),
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
            ],
          ),
          // The composer floats just above the nav.
          Positioned(
            left: VistaSpace.gutter,
            right: VistaSpace.gutter,
            bottom: navSpace + VistaSpace.sm,
            child: _Composer(onTap: () => _notBuilt('Add your take')),
          ),
        ],
      ),
    );
  }
}

/// The floating "+ Add your take…" pill: where a take or a call starts.
class _Composer extends StatelessWidget {
  const _Composer({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add your take',
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.98,
        onTap: onTap,
        child: VistaGlass(
          height: 48,
          padding: const EdgeInsets.only(
            left: VistaSpace.md,
            right: VistaSpace.gutter,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: VistaColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '+',
                  style: VistaType.title.copyWith(
                    color: VistaColors.onAccent,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: VistaSpace.lg),
              Expanded(
                child: Text(
                  'Add your take…',
                  style: VistaType.subheadMuted.copyWith(
                    color: VistaColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
