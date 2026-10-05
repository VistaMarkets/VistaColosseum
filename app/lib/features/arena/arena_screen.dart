import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../settings/settings_state.dart';
import '../trade/order_ticket.dart';
import '../profile/profile_screen.dart';
import 'arena_mock.dart';
import 'opinions_screen.dart';

/// Arena tab (Figma 33:2): battles between a Bull and a Bear caller. The
/// crowd-split filter lives in [CrowdFilterPanel], which the app shell draws
/// around the bottom nav on this tab; both read [Scenario.arena].
class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key, this.onNotBuilt});

  /// Called with a feature name when a control leads somewhere not built yet.
  final ValueChanged<String>? onNotBuilt;

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  late final _ask = TextEditingController(text: Scenario.arena.value.query);
  final _list = ScrollController();
  var _shown = ArenaMock.visible(Scenario.arena.value).length;

  @override
  void initState() {
    super.initState();
    Scenario.arena.addListener(_followView);
  }

  /// Reset clears the query; the field follows it. A narrower range or Ask
  /// starts the shorter list at its top: a kept offset would be clamped and
  /// open the remaining card partway down.
  void _followView() {
    final view = Scenario.arena.value;
    if (_ask.text != view.query) _ask.text = view.query;
    final shown = ArenaMock.visible(view).length;
    if (shown < _shown && _list.hasClients) _list.jumpTo(0);
    _shown = shown;
  }

  @override
  void dispose() {
    Scenario.arena.removeListener(_followView);
    _list.dispose();
    _ask.dispose();
    super.dispose();
  }

  void _notBuilt(String what) => widget.onNotBuilt?.call(what);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          VistaSearchTopBar(
            hint: 'Ask about a market',
            controller: _ask,
            onChanged: (q) => Scenario.setArena(query: q),
            onBell: () => _notBuilt('Notifications'),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                Scenario.arena,
                Scenario.receipts,
                Scenario.participation,
                Scenario.callReceipts,
                Scenario.clock,
                DisplayPrefs.longOnRight,
              ]),
              builder: (context, _) => _battles(context, Scenario.arena.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _battles(BuildContext context, ArenaView view) {
    final shown = ArenaMock.visible(view);
    return Column(
      children: [
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
                    selected: i == view.sort,
                    onPressed: () => Scenario.setArena(sort: i),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            controller: _list,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: VistaSpace.gutter),
            children: [
              if (shown.isEmpty) _empty(view),
              for (final b in shown)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: _card(context, b),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, Battle b) {
    String crowd(int seeded, TradeSide side) =>
        'and ${seeded + Scenario.joins(b.id, side)}';
    // Bull is long the battle's asset, Bear short; a fill is a paper
    // position (simulated) that joins this clash.
    void join(TradeSide side) =>
        showOrderTicket(context, symbol: b.asset, side: side, clashId: b.id);
    return VistaBattleCard(
      key: ValueKey(b.id),
      longOnRight: DisplayPrefs.longOnRight.value,
      ticker: b.asset,
      price: b.price,
      change: b.change,
      timeLeft: b.timeLeft,
      question: b.question,
      bull: b.bull.withLines(
        crowd: crowd(b.bullCount, TradeSide.long),
        accuracy: accuracyLine(b.bull.caller),
      ),
      bear: b.bear.withLines(
        crowd: crowd(b.bearCount, TradeSide.short),
        accuracy: accuracyLine(b.bear.caller),
      ),
      moreOpinions: b.moreOpinions,
      joined: Scenario.participation.value[b.id],
      onBull: () => join(TradeSide.long),
      onBear: () => join(TradeSide.short),
      onOpinions: () => Navigator.of(context).push(OpinionsScreen.route(b)),
      onCaller: (handle) =>
          Navigator.of(context).push(ProfileScreen.route(handle)),
    );
  }

  /// No battle matches: Ask names the assets there are and offers to
  /// clear itself; an empty crowd range offers the full range back.
  Widget _empty(ArenaView view) {
    if (ArenaMock.asked(view.query).isEmpty) {
      return VistaEmptyState(
        message: 'No battles on “${view.query.trim()}”',
        detail: ArenaMock.askHint,
        actionLabel: 'Clear search',
        onAction: () => Scenario.setArena(query: ''),
      );
    }
    return VistaEmptyState(
      message: 'No battles in this crowd split',
      actionLabel: 'Show all',
      onAction: () => Scenario.setArena(from: 0, to: ArenaMock.bucketCount),
    );
  }
}
