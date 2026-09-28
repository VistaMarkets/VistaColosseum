import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../design_system/design_system.dart';
import 'live_fills_stream.dart';
import '../live/live_feed.dart';
import 'mock_trade_idea.dart';
import 'replay_timeline.dart';
import 'signal_replay_chart.dart';

/// Full-height feed card: caller header, replay chart with social rail, and
/// the Details / side action buttons. Fills whatever height it is given.
///
/// While the chart replays, the header's price and "% since call" move with
/// the chart's tip, then land on the live values.
class TradeIdeaCard extends StatefulWidget {
  const TradeIdeaCard({
    super.key,
    required this.idea,
    this.active = true,
    this.onDetails,
    this.onTrade,
    this.onCaller,
  });

  final TradeIdea idea;

  /// Whether this card is the one settled on screen; drives the chart replay.
  final bool active;
  final VoidCallback? onDetails;
  final VoidCallback? onTrade;

  /// Opens the caller's profile (the "kaito.eth ›" row).
  final VoidCallback? onCaller;

  @override
  State<TradeIdeaCard> createState() => _TradeIdeaCardState();
}

class _TradeIdeaCardState extends State<TradeIdeaCard> {
  final _frame = ValueNotifier(const ReplayFrame());

  TradeIdea get idea => widget.idea;

  @override
  void dispose() {
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onTrade = widget.onTrade;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CallHeader(idea: idea, frame: _frame, onCaller: widget.onCaller),
        const SizedBox(height: VistaSpace.md),
        Expanded(
          child: _ChartWithRail(
            idea: idea,
            active: widget.active,
            frame: _frame,
          ),
        ),
        const SizedBox(height: VistaSpace.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
          child: Row(
            children: [
              Expanded(
                child: VistaPillButton(
                  label: 'Details',
                  onPressed: widget.onDetails,
                ),
              ),
              const SizedBox(width: VistaSpace.xl),
              Expanded(
                child: VistaPillButton(
                  label: idea.side.label,
                  variant: idea.side == TradeSide.long
                      ? VistaPillVariant.long
                      : VistaPillVariant.short,
                  leadingAsset: idea.side == TradeSide.long
                      ? VistaAssets.longArrow
                      : null,
                  onPressed: onTrade,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VistaSpace.xs),
      ],
    );
  }
}

class _CallHeader extends StatelessWidget {
  const _CallHeader({required this.idea, required this.frame, this.onCaller});

  final TradeIdea idea;
  final ValueNotifier<ReplayFrame> frame;
  final VoidCallback? onCaller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Caller row.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: VistaSize.tapTarget),
            child: Row(
              children: [
                VistaIcon(idea.callerAvatar, size: VistaSize.avatarSmall),
                const SizedBox(width: VistaSpace.md),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onCaller,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            idea.callerHandle,
                            style: VistaType.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: VistaSpace.xs),
                        Text(
                          '›',
                          style: VistaType.body.copyWith(
                            fontSize: 14,
                            color: VistaColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: VistaSpace.md),
                        Text('· ${idea.age}', style: VistaType.meta),
                      ],
                    ),
                  ),
                ),
                VistaSideBadge(side: idea.side),
              ],
            ),
          ),
          const SizedBox(height: VistaSpace.md),
          // Asset and price.
          Row(
            children: [
              VistaIcon(idea.coinAsset, size: VistaSize.avatar),
              const SizedBox(width: VistaSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(idea.ticker, style: VistaType.headline),
                    const SizedBox(height: 1),
                    Text(
                      idea.assetName,
                      style: VistaType.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder(
                valueListenable: frame,
                builder: (context, f, _) => _PriceBlock(idea: idea, frame: f),
              ),
            ],
          ),
          const SizedBox(height: VistaSpace.md),
          Text(
            idea.question,
            style: VistaType.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// The card's live price feed, shared by the header and the chart.
ValueListenable<double> _livePrice(TradeIdea idea) => LiveFeed.watch(
  'card:${idea.ticker}',
  parseUsd(idea.price),
  parseUsd(idea.price) * 0.0005,
);

/// Price and "% since call". During the replay both follow the chart's tip
/// from the call price, with "replaying" in place of "since call"; then the
/// live price takes over, the "% since call" stamps in, and both keep
/// following the live price.
class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.idea, required this.frame});

  final TradeIdea idea;
  final ReplayFrame frame;

  @override
  Widget build(BuildContext context) {
    final change = VistaType.bodyStrong;
    if (frame.replaying) {
      final call = parseUsd(idea.callPrice);
      final price = call + (parseUsd(idea.price) - call) * frame.priceFraction;
      var pct = (price - call) / call * 100;
      if (idea.side == TradeSide.short) pct = -pct;
      final colour = pct >= 0 ? VistaColors.long : VistaColors.short;
      const tabular = [FontFeature.tabularFigures()];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatUsd(price, decimals: 2),
            style: VistaType.displayNumber.copyWith(fontFeatures: tabular),
          ),
          const SizedBox(height: 1),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      '${pct >= 0 ? '+' : '−'}'
                      '${pct.abs().toStringAsFixed(2)}%',
                  style: change.copyWith(color: colour, fontFeatures: tabular),
                ),
                TextSpan(
                  text: ' · replaying ${idea.age}',
                  style: change.copyWith(color: VistaColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // The stamp: the final figure lands a size up with a glow, then settles.
    final f = frame.finale;
    final stamping = f > 0 && f < 1;
    final settle = Curves.easeOutBack.transform(f);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        LiveUsd(
          feedKey: 'card:${idea.ticker}',
          base: parseUsd(idea.price),
          step: parseUsd(idea.price) * 0.0005,
          decimals: 2,
          style: VistaType.displayNumber,
        ),
        const SizedBox(height: 1),
        Transform.scale(
          scale: stamping ? 1.3 - 0.3 * settle : 1,
          alignment: Alignment.centerRight,
          child: ValueListenableBuilder(
            valueListenable: _livePrice(idea),
            builder: (context, live, _) {
              final call = parseUsd(idea.callPrice);
              var pct = (live - call) / call * 100;
              if (idea.side == TradeSide.short) pct = -pct;
              final colour = pct >= 0 ? VistaColors.long : VistaColors.short;
              return Text(
                '${pct >= 0 ? '+' : '−'}'
                '${pct.abs().toStringAsFixed(2)}% since call',
                style: change.copyWith(
                  color: colour,
                  shadows: stamping
                      ? [
                          Shadow(
                            color: colour.withValues(alpha: 1 - f),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChartWithRail extends StatelessWidget {
  const _ChartWithRail({
    required this.idea,
    required this.active,
    required this.frame,
  });

  final TradeIdea idea;
  final bool active;
  final ValueNotifier<ReplayFrame> frame;

  /// In Figma the chart stops 42px short of the right edge and the 52px rail
  /// overlaps its last 14px.
  static const double _chartRightInset = 42;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          right: _chartRightInset,
          child: SignalReplayChart(
            active: active,
            frame: frame,
            // The same live price as the header, so both show one number.
            livePrice: _livePrice(idea),
            callPrice: parseUsd(idea.callPrice),
            nowPrice: parseUsd(idea.price),
          ),
        ),
        // Live fills stream; older entries fade.
        Positioned(
          left: VistaSpace.lg,
          top: VistaSpace.gutter,
          right: 120,
          child: LiveFillsStream(fills: idea.fills, active: active),
        ),
        // Social rail: bottom-aligned, scales down on short screens.
        Positioned(
          right: VistaSpace.xs,
          top: VistaSpace.md,
          bottom: VistaSpace.gutter,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                children: [
                  VistaRailButton(
                    asset: VistaAssets.like,
                    label: idea.likes,
                    semanticLabel: 'Like',
                  ),
                  const SizedBox(height: VistaSpace.lg),
                  VistaRailButton(
                    asset: VistaAssets.traders,
                    label: idea.traders,
                    semanticLabel: 'Traders',
                  ),
                  const SizedBox(height: VistaSpace.lg),
                  const VistaRailButton(
                    asset: VistaAssets.share,
                    label: 'Share',
                    semanticLabel: 'Share',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
