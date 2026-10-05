import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../portfolio/portfolio_mock.dart';
import '../portfolio/positions_state.dart';
import 'arena_mock.dart';
import 'compose_take_screen.dart';

/// First step of a new take, opened from the Arena +: the viewer's open
/// positions. Tapping one goes on to write the take; the page pops with
/// the posted take.
class PickPositionScreen extends StatelessWidget {
  const PickPositionScreen({super.key, this.onExplore});

  /// Takes the viewer to Explore to open a position (the empty state).
  final VoidCallback? onExplore;

  static Route<Take> route({VoidCallback? onExplore}) => MaterialPageRoute(
    builder: (_) => PickPositionScreen(onExplore: onExplore),
  );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: PositionsState.open,
    builder: (context, positions, _) => _page(context, positions),
  );

  Widget _page(BuildContext context, List<PortfolioPosition> positions) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back on its own row; the question is the title.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.md,
                VistaSpace.gutter,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: VistaIconButton(
                  asset: VistaAssets.backSmall,
                  semanticLabel: 'Back',
                  iconSize: VistaSize.icon,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter + VistaSpace.xs,
                VistaSpace.md,
                VistaSpace.gutter + VistaSpace.xs,
                VistaSpace.section,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What are you calling?', style: VistaType.displaySmall),
                  const SizedBox(height: VistaSpace.sm),
                  Text(
                    'Your position shows on the call, live.',
                    style: VistaType.subheadMuted.copyWith(
                      color: VistaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  VistaSpace.gutter,
                  0,
                  VistaSpace.gutter,
                  VistaSpace.gutter + bottomInset,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: VistaSpace.xs,
                      bottom: VistaSpace.md,
                    ),
                    child: Text(
                      'YOUR POSITIONS · ${positions.length}',
                      style: VistaType.label.copyWith(
                        color: VistaColors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  // No positions yet: a call needs one, so point the way.
                  if (positions.isEmpty)
                    _NoPositions(
                      onExplore: onExplore == null
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              onExplore!();
                            },
                    ),
                  for (final (i, p) in positions.indexed) ...[
                    if (i > 0) const SizedBox(height: VistaSpace.sm),
                    VistaListRow(
                      leading: p.coinAsset != null
                          ? VistaListRow.coin(p.coinAsset!)
                          : VistaListRow.initial(p.initial!),
                      title: p.title,
                      tag: p.tag,
                      tagColor: p.side.color,
                      sparkAsset: p.sparkAsset,
                      value: p.pnl,
                      change: p.pnlPercent,
                      valueColor: p.pnlColor,
                      // Tapping a position goes straight on to writing the
                      // take; a posted take comes back through here.
                      onPressed: () async {
                        final take = await Navigator.of(context)
                            .push(ComposeTakeScreen.route(p));
                        if (take != null && context.mounted) {
                          Navigator.of(context).pop(take);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The picker with nothing to pick: a call is made from a position, so
/// this sends the viewer to Explore to open one.
class _NoPositions extends StatelessWidget {
  const _NoPositions({this.onExplore});

  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VistaSpace.gutter + VistaSpace.xs),
      decoration: BoxDecoration(
        color: VistaColors.surface,
        borderRadius: BorderRadius.circular(VistaRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No open positions yet', style: VistaType.headline),
          const SizedBox(height: VistaSpace.xs),
          Text(
            'A call is made from a position, so others can see it play '
            'out live. Open one on any market, then come back here.',
            style: VistaType.bodyMedium.copyWith(
              color: VistaColors.textSecondary,
            ),
          ),
          if (onExplore != null) ...[
            const SizedBox(height: VistaSpace.gutter),
            VistaPillButton(
              label: 'Find a market',
              variant: VistaPillVariant.accent,
              onPressed: onExplore,
            ),
          ],
        ],
      ),
    );
  }
}
