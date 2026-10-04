import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../portfolio/portfolio_mock.dart';

/// First step of a new take, opened from the Arena +: the viewer's open
/// positions, one of which they pick to back the take. Pops with the
/// chosen position.
class PickPositionScreen extends StatefulWidget {
  const PickPositionScreen({super.key});

  static Route<PortfolioPosition> route() =>
      MaterialPageRoute(builder: (_) => const PickPositionScreen());

  @override
  State<PickPositionScreen> createState() => _PickPositionScreenState();
}

class _PickPositionScreenState extends State<PickPositionScreen> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    const positions = PortfolioMock.positions;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.md,
                VistaSpace.gutter,
                0,
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
                  Text('New take', style: VistaType.title),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter + VistaSpace.xs,
                VistaSpace.md,
                VistaSpace.gutter + VistaSpace.xs,
                VistaSpace.gutter,
              ),
              child: Text(
                'Pick the position your take is about. It shows on your '
                'take, live, as ✓ Backed.',
                style: VistaType.subheadMuted.copyWith(
                  color: VistaColors.textMuted,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: VistaSpace.gutter,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: VistaSpace.xs,
                      bottom: VistaSpace.sm,
                    ),
                    child: Text(
                      'Your positions · ${positions.length}',
                      style: VistaType.body.copyWith(
                        color: VistaColors.textMuted,
                      ),
                    ),
                  ),
                  for (final (i, p) in positions.indexed) ...[
                    if (i > 0) const SizedBox(height: VistaSpace.sm),
                    _PickRow(
                      selected: _picked == i,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _picked = i);
                      },
                      child: VistaListRow(
                        // Picked: a tick takes the coin's place.
                        leading: _picked == i
                            ? const _Tick()
                            : p.coinAsset != null
                            ? VistaListRow.coin(p.coinAsset!)
                            : VistaListRow.initial(p.initial!),
                        title: p.title,
                        tag: p.tag,
                        tagColor: p.side.color,
                        sparkAsset: p.sparkAsset,
                        value: p.pnl,
                        change: p.pnlPercent,
                        valueColor: p.pnlColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.md,
                VistaSpace.gutter,
                bottomInset > 0 ? bottomInset : VistaSpace.gutter,
              ),
              child: VistaPillButton(
                label: 'Continue',
                variant: VistaPillVariant.accent,
                onPressed: _picked == null
                    ? null
                    : () => Navigator.of(context).pop(positions[_picked!]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A position row the whole of which picks it.
class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // The row's own tap is off; this one picks it.
        child: IgnorePointer(child: child),
      ),
    );
  }
}

/// The picked mark: an accent circle with a tick, the size of a coin.
class _Tick extends StatelessWidget {
  const _Tick();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: VistaSize.listLeading,
      height: VistaSize.listLeading,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: VistaColors.accent,
        shape: BoxShape.circle,
      ),
      child: Text(
        '✓',
        style: VistaType.bodyStrong.copyWith(
          color: VistaColors.onAccent,
          height: 1,
        ),
      ),
    );
  }
}
