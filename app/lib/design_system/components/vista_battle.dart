import 'package:flutter/widgets.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_typography.dart';
import '../vista_assets.dart';
import 'vista_buttons.dart';
import 'vista_icon.dart';
import 'vista_pressable.dart';

/// One side of a battle: its lead caller, their thesis and the side's crowd.
class VistaBattleSide {
  const VistaBattleSide({
    required this.caller,
    required this.accuracy,
    required this.price,
    required this.change,
    required this.thesis,
    required this.result,
    required this.crowd,
  });

  final String caller;
  final String accuracy;
  final String price;
  final String change;
  final String thesis;

  /// Side's return so far, e.g. "+4.2%".
  final String result;

  /// Others on this side, e.g. "and 14".
  final String crowd;
}

/// Arena battle card ("BattleCard · V2 — consensus first"): an event header,
/// Bull and Bear columns split by a hairline, a "more opinions" pill, and
/// the two join buttons.
class VistaBattleCard extends StatelessWidget {
  const VistaBattleCard({
    super.key,
    required this.ticker,
    required this.price,
    required this.change,
    required this.timeLeft,
    required this.question,
    required this.bull,
    required this.bear,
    required this.moreOpinions,
    this.onBull,
    this.onBear,
    this.onOpinions,
    this.onCaller,
    this.longOnRight = false,
  });

  final String ticker;
  final String price;
  final String change;
  final String timeLeft;
  final String question;
  final VistaBattleSide bull;
  final VistaBattleSide bear;
  final String moreOpinions;

  /// Put the bull button on the right (Settings › Display).
  final bool longOnRight;
  final VoidCallback? onBull;
  final VoidCallback? onBear;
  final VoidCallback? onOpinions;

  /// Tapping a caller (opens their profile).
  final ValueChanged<String>? onCaller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(VistaRadius.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(ticker, style: VistaType.displayNumber),
                    const SizedBox(width: VistaSpace.md),
                    Text(price, style: VistaType.tab),
                    const SizedBox(width: VistaSpace.md),
                    Expanded(
                      child: Text(
                        change,
                        style: VistaType.body.copyWith(
                          color:
                              change.startsWith('-') || change.startsWith('−')
                              ? VistaColors.short
                              : VistaColors.long,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: VistaColors.surface,
                        borderRadius: BorderRadius.circular(VistaRadius.pill),
                      ),
                      child: Text(timeLeft, style: VistaType.label),
                    ),
                  ],
                ),
                const SizedBox(height: VistaSpace.sm),
                Text(question, style: VistaType.title.copyWith(height: 1.28)),
              ],
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Side(
                    label: 'BULL',
                    color: VistaColors.long,
                    avatar: VistaAssets.battleAvatarBull,
                    side: bull,
                    alignEnd: false,
                    onCaller: onCaller,
                  ),
                ),
                Container(width: 1, color: VistaColors.hairline),
                Expanded(
                  child: _Side(
                    label: 'BEAR',
                    color: VistaColors.short,
                    avatar: VistaAssets.battleAvatarBear,
                    side: bear,
                    alignEnd: true,
                    onCaller: onCaller,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Semantics(
              button: true,
              label: moreOpinions,
              excludeSemantics: true,
              child: VistaPressable(
                scale: 0.98,
                onTap: onOpinions,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 36),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                  decoration: BoxDecoration(
                    color: VistaColors.surface,
                    borderRadius: BorderRadius.circular(42),
                  ),
                  child: Row(
                    children: [
                      const VistaIcon(
                        VistaAssets.opinionsAvatars,
                        size: 56,
                        height: 20,
                      ),
                      const SizedBox(width: VistaSpace.lg),
                      Expanded(
                        child: Text(moreOpinions, style: VistaType.body),
                      ),
                      Text(
                        '›',
                        style: VistaType.tab.copyWith(
                          color: VistaColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: VistaSidePair(
              longOnRight: longOnRight,
              long: VistaPillButton(
                label: "I'm with Bull",
                variant: VistaPillVariant.long,
                onPressed: onBull,
              ),
              short: VistaPillButton(
                label: "I'm with Bear",
                variant: VistaPillVariant.short,
                onPressed: onBear,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.label,
    required this.color,
    required this.avatar,
    required this.side,
    required this.alignEnd,
    this.onCaller,
  });

  final String label;
  final Color color;
  final String avatar;
  final VistaBattleSide side;

  /// Bear mirrors Bull: right-aligned, avatar after the name, change first.
  final bool alignEnd;
  final ValueChanged<String>? onCaller;

  @override
  Widget build(BuildContext context) {
    final cross = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final caller = Column(
      crossAxisAlignment: cross,
      children: [
        Text(side.caller, style: VistaType.subhead),
        Text(
          side.accuracy,
          style: VistaType.caption.copyWith(color: VistaColors.textSecondary),
        ),
      ],
    );
    const avatarGap = SizedBox(width: VistaSpace.md);
    final avatarIcon = VistaIcon(avatar, size: 28);
    final price = Text(side.price, style: VistaType.subhead);
    final change = Text(
      side.change,
      style: VistaType.body.copyWith(color: color),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: cross,
        children: [
          Text(label, style: VistaType.labelStrong.copyWith(color: color)),
          const SizedBox(height: VistaSpace.md),
          VistaPressable(
            scale: 0.98,
            onTap: onCaller == null ? null : () => onCaller!(side.caller),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: alignEnd
                  ? [Flexible(child: caller), avatarGap, avatarIcon]
                  : [avatarIcon, avatarGap, Flexible(child: caller)],
            ),
          ),
          const SizedBox(height: VistaSpace.md),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: alignEnd
                ? [change, const SizedBox(width: VistaSpace.xs), price]
                : [price, const SizedBox(width: VistaSpace.xs), change],
          ),
          const SizedBox(height: VistaSpace.md),
          Text(
            side.thesis,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: VistaType.bodyRegular.copyWith(height: 1.28),
          ),
          const SizedBox(height: VistaSpace.md),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                side.result,
                style: VistaType.subhead.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: VistaSpace.sm),
              Text(
                side.crowd,
                style: VistaType.body.copyWith(
                  fontWeight: FontWeight.w400,
                  color: VistaColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Trader avatar with initials and, optionally, their verified hit rate
/// riding the bottom edge. The rate is textPrimary, never green: accuracy is
/// not a direction (Figma "TraderAvatar").
class VistaTraderAvatar extends StatelessWidget {
  const VistaTraderAvatar({super.key, required this.initials, this.hitRate});

  final String initials;
  final String? hitRate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 0,
            top: 0,
            child: VistaIcon(VistaAssets.initialsAvatar, size: 36),
          ),
          Positioned(
            left: 0,
            top: 0,
            width: 36,
            height: 36,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(initials, style: VistaType.body),
              ),
            ),
          ),
          if (hitRate != null)
            Positioned(
              left: 0,
              top: 28,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: VistaColors.background,
                  borderRadius: BorderRadius.circular(VistaRadius.pill),
                  border: Border.all(color: VistaColors.hairline),
                ),
                child: Text(hitRate!, style: VistaType.labelStrong),
              ),
            ),
        ],
      ),
    );
  }
}

/// One figure in a side's stats row: value over a small label.
class VistaSideStat {
  const VistaSideStat(this.value, this.label, {this.color});

  final String value;
  final String label;
  final Color? color;
}

/// A side's whole case on the clash detail page (Figma "SideDetail"): who
/// made it, the thesis at full length, and its numbers.
class VistaSideDetail extends StatelessWidget {
  const VistaSideDetail({
    super.key,
    required this.initials,
    required this.handle,
    required this.subtitle,
    required this.sideLabel,
    required this.sideColor,
    required this.thesis,
    required this.stats,
    this.hitRate,
    this.onCaller,
  });

  final String initials;
  final String handle;
  final String subtitle;
  final String sideLabel;
  final Color sideColor;
  final String thesis;
  final List<VistaSideStat> stats;
  final String? hitRate;
  final VoidCallback? onCaller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VistaSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VistaPressable(
            scale: 0.98,
            onTap: onCaller,
            child: Row(
              children: [
                VistaTraderAvatar(initials: initials, hitRate: hitRate),
                const SizedBox(width: VistaSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        handle,
                        style: VistaType.tab,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: VistaType.caption.copyWith(
                          color: VistaColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: VistaSpace.lg),
                Text(
                  sideLabel,
                  style: VistaType.labelStrong.copyWith(color: sideColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: VistaSpace.xl),
          Text(
            thesis,
            style: VistaType.subhead.copyWith(
              fontWeight: FontWeight.w400,
              color: VistaColors.textTertiary,
            ),
          ),
          const SizedBox(height: VistaSpace.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in stats)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.value,
                      style: VistaType.body.copyWith(
                        color: s.color ?? VistaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: VistaSpace.xxs),
                    Text(
                      s.label,
                      style: VistaType.caption.copyWith(
                        color: VistaColors.textMuted,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
