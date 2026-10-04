import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../settings/settings_state.dart';

/// Reset demo: the store and the simulated Settings back to the fixture,
/// then says so. Settings and the simulated note both run this.
void resetDemo(BuildContext context) {
  Scenario.reset();
  SettingsState.reset();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text('Demo reset to ${Scenario.fixtureVersion}')),
    );
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
      barrierColor: const Color(0x73000000), // Figma scrim: black at 45%
      builder: (_) => const _SimulatedNote(),
    );
    _open = false;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final label = 'Simulated · ${Scenario.fixtureVersion}';
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
        Positioned(
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
          VistaPrimaryButton(
            label: 'Reset demo',
            onPressed: () {
              resetDemo(context);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
