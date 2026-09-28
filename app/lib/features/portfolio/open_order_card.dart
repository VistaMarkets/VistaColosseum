import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../live/live_feed.dart';
import '../live/market_prices.dart';
import 'portfolio_mock.dart';

/// One resting limit order on the Portfolio "Open orders" tab, kept to what
/// matters for it filling: asset, side and leverage, the price it fills at
/// and how far the market is from it, then its size (and fill so far),
/// exits and flags, with a one-tap Cancel. Cancelling folds the card away before
/// [onCancel] runs. Simulated: nothing is sent.
class OpenOrderCard extends StatefulWidget {
  const OpenOrderCard({super.key, required this.order, required this.onCancel});

  final OpenOrder order;
  final VoidCallback onCancel;

  @override
  State<OpenOrderCard> createState() => _OpenOrderCardState();
}

class _OpenOrderCardState extends State<OpenOrderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

  @override
  void dispose() {
    _fold.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    if (_fold.isAnimating) return;
    await _fold.reverse();
    if (mounted) widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _fold, curve: Curves.easeInCubic);
    return SizeTransition(
      sizeFactor: curved,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: curved, child: _card()),
    );
  }

  String _usd(double v, [int? decimals]) =>
      formatUsd(v, decimals: decimals ?? widget.order.decimals);

  String _units(double v) =>
      '${v.toStringAsFixed(widget.order.quantityDecimals)} '
      '${widget.order.symbol}';

  Widget _card() {
    final o = widget.order;
    final muted = VistaType.caption.copyWith(color: VistaColors.textMuted);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        VistaSpace.lg,
        VistaSpace.sm,
        VistaSpace.xs,
        VistaSpace.md,
      ),
      decoration: BoxDecoration(
        color: VistaColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The order and where it fills, with Cancel.
          Row(
            children: [
              VistaIcon(o.coinAsset, size: 32),
              const SizedBox(width: VistaSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            o.asset,
                            style: VistaType.subhead,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: VistaSpace.sm),
                        Text(
                          o.tag,
                          style: VistaType.labelStrong.copyWith(
                            color: o.side.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Distance follows the market's one live price.
                    ValueListenableBuilder(
                      valueListenable: MarketPrices.of(o.symbol),
                      builder: (context, _, _) => Text.rich(
                        TextSpan(
                          style: muted,
                          children: [
                            const TextSpan(text: 'Fills at '),
                            TextSpan(
                              text: _usd(o.limitPrice),
                              style: VistaType.bodyStrong,
                            ),
                            TextSpan(
                              text:
                                  ' · ${(o.distance * 100).toStringAsFixed(1)}% '
                                  '${o.limitBelowMark ? 'below' : 'above'} mark',
                            ),
                          ],
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
              _CancelButton(onPressed: _cancel, asset: o.symbol),
            ],
          ),
          const SizedBox(height: VistaSpace.sm),
          // Size, fill, exits and flags.
          Padding(
            padding: const EdgeInsets.only(right: VistaSpace.md),
            child: Wrap(
              spacing: VistaSpace.sm,
              runSpacing: VistaSpace.sm,
              children: [
                VistaTag(
                  label: 'Size ${_usd(o.notional, 0)} · ${_units(o.quantity)}',
                  dense: true,
                ),
                if (o.partlyFilled)
                  VistaTag(
                    label:
                        '${o.filled.toStringAsFixed(o.quantityDecimals)} / '
                        '${_units(o.quantity)} filled',
                    dense: true,
                  ),
                if (o.takeProfit != null)
                  VistaTag(
                    label: 'TP ${_usd(o.takeProfit!)}',
                    textColor: VistaColors.long,
                    dense: true,
                  ),
                if (o.stopLoss != null)
                  VistaTag(
                    label: 'SL ${_usd(o.stopLoss!)}',
                    textColor: VistaColors.short,
                    dense: true,
                  ),
                if (o.reduceOnly)
                  const VistaTag(label: 'Reduce only', dense: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The quick Cancel: a small pill in a 44pt target.
class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed, required this.asset});

  final VoidCallback onPressed;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cancel $asset order',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          height: VistaSize.tapTarget,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: VistaSpace.sm),
            child: Center(
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: VistaColors.short.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(VistaRadius.pill),
                ),
                child: Text(
                  'Cancel',
                  style: VistaType.bodyStrong.copyWith(
                    color: VistaColors.short,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
