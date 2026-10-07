import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../portfolio/portfolio_mock.dart';
import '../portfolio/positions_state.dart';
import 'arena_mock.dart';
import 'compose_take_screen.dart';
import '../trade/order_ticket.dart';

/// First step of a new take, opened from the Arena +: the viewer's open
/// positions. Tapping one goes on to write the take; the page pops with
/// the posted take.
///
/// From a debate's Argue long / short ([debate] and [side] set) it lists
/// only positions on that market and side, the composer opens with the
/// debate attached, and with none it offers to open one: a call always
/// stands on a position.
class PickPositionScreen extends StatelessWidget {
  const PickPositionScreen({
    super.key,
    this.onExplore,
    this.debate,
    this.side,
    this.ticker,
  });

  /// A room's "Post a call on ETH": only positions on this market, either
  /// side.
  final String? ticker;

  /// Takes the viewer to Explore to open a position (the empty state).
  final VoidCallback? onExplore;
  final LiveBattle? debate;
  final TradeSide? side;

  static Route<Take> route({
    VoidCallback? onExplore,
    LiveBattle? debate,
    TradeSide? side,
    String? ticker,
  }) => MaterialPageRoute(
    builder: (_) => PickPositionScreen(
      onExplore: onExplore,
      debate: debate,
      side: side,
      ticker: ticker,
    ),
  );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: PositionsState.open,
    builder: (context, positions, _) => _page(context, [
      for (final p in positions)
        if (debate != null
            ? p.detail.symbol == debate!.ticker && p.side == side
            : ticker == null || p.detail.symbol == ticker)
          p,
    ]),
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
                  Text(
                    debate == null
                        ? 'What are you calling?'
                        : 'Back your ${side!.label.toLowerCase()} case',
                    style: VistaType.displaySmall,
                  ),
                  const SizedBox(height: VistaSpace.sm),
                  Text(
                    debate == null
                        ? 'Your position shows on the call, live.'
                        : 'On "${debate!.question}". Your '
                              '${debate!.ticker} ${side!.label.toLowerCase()} '
                              'shows on the call, live.',
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
                  if (positions.isEmpty && debate != null)
                    _NoSidePosition(
                      ticker: debate!.ticker,
                      side: side!,
                      onOpen: () => showOrderTicket(
                        context,
                        symbol: debate!.ticker,
                        side: side!,
                      ),
                    )
                  else if (positions.isEmpty && ticker != null)
                    _NoTickerPosition(ticker: ticker!)
                  else if (positions.isEmpty)
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
                            .push(ComposeTakeScreen.route(p, debate: debate));
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

/// Arguing a side with no position on it: open one here (the order ticket,
/// simulated); it shows in the list as soon as it fills.
class _NoSidePosition extends StatelessWidget {
  const _NoSidePosition({
    required this.ticker,
    required this.side,
    required this.onOpen,
  });

  final String ticker;
  final TradeSide side;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final s = side.label.toLowerCase();
    return Container(
      padding: const EdgeInsets.all(VistaSpace.gutter + VistaSpace.xs),
      decoration: BoxDecoration(
        color: VistaColors.surface,
        borderRadius: BorderRadius.circular(VistaRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No $ticker $s open', style: VistaType.headline),
          const SizedBox(height: VistaSpace.xs),
          Text(
            'A case in a debate stands on a position. Open a $s on $ticker '
            'and it shows here to pick.',
            style: VistaType.bodyMedium.copyWith(
              color: VistaColors.textSecondary,
            ),
          ),
          const SizedBox(height: VistaSpace.gutter),
          VistaPillButton(
            label: 'Open a $s',
            variant: side == TradeSide.long
                ? VistaPillVariant.long
                : VistaPillVariant.short,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

/// A room's post with no position on its market: open one either way (the
/// order ticket, simulated); it shows in the list once it fills.
class _NoTickerPosition extends StatelessWidget {
  const _NoTickerPosition({required this.ticker});

  final String ticker;

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
          Text('No $ticker position open', style: VistaType.headline),
          const SizedBox(height: VistaSpace.xs),
          Text(
            'A call on $ticker stands on a $ticker position. Open one and '
            'it shows here to pick.',
            style: VistaType.bodyMedium.copyWith(
              color: VistaColors.textSecondary,
            ),
          ),
          const SizedBox(height: VistaSpace.gutter),
          Row(
            children: [
              Expanded(
                child: VistaPillButton(
                  label: 'Open a long',
                  variant: VistaPillVariant.long,
                  onPressed: () => showOrderTicket(
                    context,
                    symbol: ticker,
                    side: TradeSide.long,
                  ),
                ),
              ),
              const SizedBox(width: VistaSpace.md),
              Expanded(
                child: VistaPillButton(
                  label: 'Open a short',
                  variant: VistaPillVariant.short,
                  onPressed: () => showOrderTicket(
                    context,
                    symbol: ticker,
                    side: TradeSide.short,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
