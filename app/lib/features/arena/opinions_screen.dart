import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_state.dart';
import '../trade/order_ticket.dart';
import 'arena_mock.dart';
import 'opinions_mock.dart';

/// Every opinion on a battle (Figma 48:430, "13 · Clash detail — scrolled"),
/// opened from a battle card's "more opinions" pill. Chips filter by side;
/// the dock shows the crowd split and the follow actions.
class OpinionsScreen extends StatefulWidget {
  const OpinionsScreen({super.key, required this.battle});

  final Battle battle;

  static Route<void> route(Battle battle) =>
      MaterialPageRoute(builder: (_) => OpinionsScreen(battle: battle));

  @override
  State<OpinionsScreen> createState() => _OpinionsScreenState();
}

class _OpinionsScreenState extends State<OpinionsScreen> {
  int _filter = 0; // 0 All, 1 Bull thesis, 2 Bear thesis

  @override
  Widget build(BuildContext context) {
    final b = widget.battle;
    final opinions = b.opinions.where(
      (o) => switch (_filter) {
        1 => o.side == OpinionSide.bull,
        2 => o.side == OpinionSide.bear,
        _ => true,
      },
    );
    final bull = b.bullPct;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Collapsed header: back, battle title, asset and consensus.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.md,
                VistaSpace.gutter,
                VistaSpace.lg,
              ),
              child: Row(
                children: [
                  VistaIconButton(
                    asset: VistaAssets.backSmall,
                    semanticLabel: 'Back',
                    iconSize: VistaSize.icon,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: VistaSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.question, style: VistaType.body),
                        const SizedBox(height: 1),
                        Wrap(
                          spacing: VistaSpace.sm,
                          children: [
                            Text(
                              '${b.asset} ${b.price}',
                              style: VistaType.caption.copyWith(
                                color: VistaColors.textMuted,
                              ),
                            ),
                            Text(
                              'Crowd split $bull% bull',
                              style: VistaType.labelStrong.copyWith(
                                color: VistaColors.long,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VistaSpace.gutter,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: VistaSpace.md,
                  children: [
                    for (var i = 0; i < OpinionsMock.filters.length; i++)
                      VistaFilterChip(
                        label: OpinionsMock.filters[i],
                        accent: true,
                        selected: i == _filter,
                        onPressed: () => setState(() => _filter = i),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  VistaSpace.gutter,
                  VistaSpace.md,
                  VistaSpace.gutter,
                  VistaSpace.gutter,
                ),
                children: [
                  for (final o in opinions)
                    VistaSideDetail(
                      initials: o.initials,
                      handle: o.handle,
                      subtitle: o.subtitle,
                      sideLabel: o.label,
                      sideColor: o.color,
                      thesis: o.thesis,
                      stats: o.stats,
                      hitRate: o.hitRate,
                      onCaller: () => Navigator.of(context).push(
                        ProfileScreen.route(o.handle.replaceFirst('@', '')),
                      ),
                    ),
                ],
              ),
            ),
            _ConsensusDock(
              bullPercent: bull,
              opinionCount: b.opinionCount,
              // Bull is long the battle's asset, Bear short; a fill joins
              // this clash.
              onBull: () => showOrderTicket(
                context,
                symbol: b.asset,
                side: TradeSide.long,
                clashId: b.id,
              ),
              onBear: () => showOrderTicket(
                context,
                symbol: b.asset,
                side: TradeSide.short,
                clashId: b.id,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Raised dock: crowd-split legend and bar over Follow Bull / Bear.
class _ConsensusDock extends StatelessWidget {
  const _ConsensusDock({
    required this.bullPercent,
    required this.opinionCount,
    required this.onBull,
    required this.onBear,
  });

  final int bullPercent;
  final int opinionCount;
  final VoidCallback onBull;
  final VoidCallback onBear;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: VistaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, -4),
            blurRadius: 2,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        VistaSpace.xl,
        VistaSpace.xl + 17,
        VistaSpace.xl,
        bottomInset > 0 ? bottomInset : VistaSpace.gutter,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$bullPercent%',
                style: VistaType.labelStrong.copyWith(color: VistaColors.long),
              ),
              Flexible(
                child: Text(
                  'Crowd split · $opinionCount opinions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: VistaType.caption.copyWith(
                    color: VistaColors.textMuted,
                  ),
                ),
              ),
              Text(
                '${100 - bullPercent}%',
                style: VistaType.labelStrong.copyWith(color: VistaColors.short),
              ),
            ],
          ),
          const SizedBox(height: VistaSpace.sm),
          VistaSplitBar(leftFraction: bullPercent / 100, height: 6),
          const SizedBox(height: VistaSpace.xl + 17 + 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ValueListenableBuilder(
              valueListenable: DisplayPrefs.longOnRight,
              builder: (context, longOnRight, _) => VistaSidePair(
                longOnRight: longOnRight,
                gap: VistaSpace.md,
                long: VistaPillButton(
                  label: 'Follow Bull',
                  variant: VistaPillVariant.long,
                  onPressed: onBull,
                ),
                short: VistaPillButton(
                  label: 'Follow Bear',
                  variant: VistaPillVariant.short,
                  onPressed: onBear,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
