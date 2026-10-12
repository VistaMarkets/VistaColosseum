import 'package:flutter/material.dart';

import '../../app_shell.dart';
import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../live/live_feed.dart';
import '../live/market_prices.dart';
import '../market/receipt_screens.dart';
import '../settings/settings_state.dart';

/// Reset demo: closes every sheet and pushed route (they were built on the
/// old state), puts the store and the simulated Settings back to the
/// fixture, then says so where it can be seen. Settings and the simulated
/// note both run this.
void resetDemo(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  Navigator.of(context).popUntil((route) => route.isFirst);
  Scenario.reset();
  SettingsState.reset();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text('Demo reset to ${Scenario.fixtureVersion}')),
    );
}

/// Act as the other persona: closes every sheet and route (a ticket opened
/// as one persona must never confirm as the other), switches, and says who
/// is acting, in the Settings row's words.
void actAs(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  Navigator.of(context).popUntil((route) => route.isFirst);
  Scenario.switchPersona();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Now acting as ${Scenario.activePersona.value.handle}'),
      ),
    );
}

/// The preset copy's action id: fixed, so a second play returns the first
/// receipt and writes nothing (the store's duplicate guard).
const kPresetCopyActionId = 'preset-copy';

/// The copy story's order: kilo.sol's SOL long, sized to a 10000-cent
/// notional at the live price, so margin, fee and copy fee never drift.
OrderIntent presetCopyIntent() {
  final price = MarketPrices.now('SOL');
  return OrderIntent(
    actionId: kPresetCopyActionId,
    symbol: 'SOL',
    name: 'Solana',
    side: TradeSide.long,
    units: 100 / price,
    price: price,
    leverage: 5,
    icon: VistaAssets.coinSolRow,
    sourceCallId: 'kilo.sol/SOL',
    sourceAuthorHandle: 'kilo.sol',
  );
}

/// Play the copy story to its proof: as the copier, copy kilo.sol's SOL
/// call through the real store, then land as the creator on the Fee ledger
/// row it credited. A failed order stops here, still as the copier.
void playCopyStory(BuildContext context) {
  // Captured first: popping closes the note this was tapped from.
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  nav.popUntil((route) => route.isFirst);
  if (Scenario.activePersona.value != Persona.copier) Scenario.switchPersona();
  final before = Scenario.copyFees.length;
  final result = Scenario.placeOrder(presetCopyIntent());
  final String toast;
  if (result is OrderFailed) {
    toast = result.reason;
  } else {
    Scenario.switchPersona();
    AppShell.tab.value = AppShell.wallet;
    nav.push(LedgerScreen.route());
    final fee = formatCents(kCopyFeeCents);
    toast = Scenario.copyFees.length > before
        ? '${Persona.copier.handle} copied @kilo.sol · $fee copy fee '
              'credited to ${Persona.creator.handle} (simulated)'
        : 'Already played · the $fee copy fee is on the Fee ledger '
              '(simulated)';
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(toast)));
}

/// The "Simulated · fixture-v1" pill, shown once over the whole app (wrap
/// the navigator in `MaterialApp.builder`), so every tab, pushed route and
/// sheet shows it. It reserves a strip at the bottom by adding it to the
/// safe-area inset: whatever keeps clear of the home indicator keeps clear
/// of the pill. Tap: what is simulated, and Reset demo.
class SimulationIndicator extends StatefulWidget {
  const SimulationIndicator({
    super.key,
    required this.navigator,
    required this.child,
  });

  /// The app's navigator; the note opens on it, as the pill sits above it.
  final GlobalKey<NavigatorState> navigator;
  final Widget child;

  /// The reserved strip: fits the pill at the app's 1.3x text-scale cap.
  ///
  /// Known gap (run manager, 2026-10-05): the pill's tap target is this
  /// 30 px strip, under [VistaSize.tapTarget]. A pad above the strip would
  /// sit on footers that end flush on it (make-market footer, ChartSheet
  /// Long/Short, your-market 'Make a call'), which spec 03 forbids, and
  /// raising the slot costs every screen 14 px. Closing it is the manager's
  /// call: raise the slot, or give those footers a 14 px gap first.
  static const double slot = 30;

  @override
  State<SimulationIndicator> createState() => _SimulationIndicatorState();
}

class _SimulationIndicatorState extends State<SimulationIndicator> {
  // The pill stays tappable above the note's scrim; open the note once.
  bool _open = false;

  Future<void> _showNote() async {
    final context = widget.navigator.currentContext;
    if (_open || context == null) return;
    _open = true;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: VistaColors.scrim,
      builder: (_) => const _SimulatedNote(),
    );
    _open = false;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        MediaQuery(
          data: mq.copyWith(
            padding: mq.padding.copyWith(
              bottom: mq.padding.bottom + SimulationIndicator.slot,
            ),
            viewPadding: mq.viewPadding.copyWith(
              bottom: mq.viewPadding.bottom + SimulationIndicator.slot,
            ),
          ),
          child: widget.child,
        ),
        ValueListenableBuilder<Persona>(
          valueListenable: Scenario.activePersona,
          builder: (context, persona, _) {
            final label =
                'Simulated · ${Scenario.fixtureVersion} · ${persona.handle}';
            return Positioned(
              left: 0,
              right: 0,
              // Above the keyboard too, where screens already make room.
              bottom: mq.padding.bottom + mq.viewInsets.bottom,
              height: SimulationIndicator.slot,
              child: Center(
                child: Semantics(
                  container: true,
                  button: true,
                  label: label,
                  onTap: _showNote,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showNote,
                    child: Align(
                      widthFactor: 1,
                      child: Material(
                        color: VistaColors.surfaceRaised,
                        shape: const StadiumBorder(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VistaSpace.lg,
                            vertical: VistaSpace.xs,
                          ),
                          child: Text(
                            label,
                            style: VistaType.label.copyWith(
                              color: VistaColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// What the pill means, and the way back to the fixture.
class _SimulatedNote extends StatelessWidget {
  const _SimulatedNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: VistaColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VistaRadius.sheet),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        VistaSpace.gutter,
        VistaSpace.lg,
        VistaSpace.gutter,
        VistaSpace.gutter + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: VistaDragHandle()),
          const SizedBox(height: VistaSpace.gutter),
          Text(
            'All prices, fills, balances and results are simulated. '
            'Nothing leaves this device.',
            style: VistaType.bodyRegular,
          ),
          const SizedBox(height: VistaSpace.gutter),
          ValueListenableBuilder<Persona>(
            valueListenable: Scenario.activePersona,
            builder: (context, persona, _) {
              final other = persona == Persona.creator
                  ? Persona.copier
                  : Persona.creator;
              return VistaPrimaryButton(
                label: 'Act as @${other.handle}',
                onPressed: () => actAs(context),
              );
            },
          ),
          const SizedBox(height: VistaSpace.md),
          VistaPrimaryButton(
            label: 'Play the copy story',
            onPressed: () => playCopyStory(context),
          ),
          const SizedBox(height: VistaSpace.md),
          VistaPrimaryButton(
            label: 'Reset demo',
            onPressed: () => resetDemo(context), // closes this note too
          ),
        ],
      ),
    );
  }
}
