import 'package:flutter/widgets.dart';

import '../../design_system/design_system.dart';
import 'live_fills_stream.dart';
import '../live/live_feed.dart';
import 'mock_trade_idea.dart';
import 'signal_replay_chart.dart';

/// Full-height feed card: caller header, replay chart with social rail, and
/// the Details / side action buttons. Fills whatever height it is given.
class TradeIdeaCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CallHeader(idea: idea, onCaller: onCaller),
        const SizedBox(height: VistaSpace.md),
        Expanded(
          child: _ChartWithRail(idea: idea, active: active),
        ),
        const SizedBox(height: VistaSpace.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
          child: Row(
            children: [
              Expanded(
                child: VistaPillButton(label: 'Details', onPressed: onDetails),
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
  const _CallHeader({required this.idea, this.onCaller});

  final TradeIdea idea;
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
              Column(
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
                  Text(
                    idea.changeSinceCall,
                    style: VistaType.bodyStrong.copyWith(
                      color: idea.side.color,
                    ),
                  ),
                ],
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

class _ChartWithRail extends StatelessWidget {
  const _ChartWithRail({required this.idea, required this.active});

  final TradeIdea idea;
  final bool active;

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
          child: SignalReplayChart(active: active),
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
