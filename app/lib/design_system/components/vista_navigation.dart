import 'package:flutter/widgets.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_typography.dart';
import 'vista_icon.dart';

/// Slim top bar: avatar + handle on the left, icon actions on the right.
class VistaTopBar extends StatelessWidget {
  const VistaTopBar({
    super.key,
    required this.avatarAsset,
    required this.handle,
    this.actions = const [],
  });

  final String avatarAsset;
  final String handle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: VistaSize.tapTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
        child: Row(
          children: [
            VistaIcon(avatarAsset, size: VistaSize.avatar),
            const SizedBox(width: VistaSpace.md),
            Expanded(
              child: Text(
                handle,
                style: VistaType.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// Centred text tabs with an accent underline and a hairline divider.
class VistaSegmentedTabs extends StatelessWidget {
  const VistaSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.counts,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Optional smaller figure after each label (e.g. "Followers 1,204").
  final List<String>? counts;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      if (i > 0) {
        children.add(
          Container(width: 1, height: 11, color: VistaColors.divider),
        );
      }
      children.add(_tab(i));
    }
    return SizedBox(
      height: VistaSize.tapTarget,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }

  Widget _tab(int i) {
    final selected = i == selectedIndex;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(i),
        // 14 either side of the divider, per Figma's 14px gap.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: VistaSpace.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    labels[i],
                    style: VistaType.tab.copyWith(
                      color: selected
                          ? VistaColors.textPrimary
                          : VistaColors.textInactive,
                    ),
                  ),
                  if (counts != null) ...[
                    const SizedBox(width: 5),
                    Text(
                      counts![i],
                      style: VistaType.body.copyWith(
                        color: selected
                            ? VistaColors.textMuted
                            : VistaColors.textFaint,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: VistaSpace.xs),
              Container(
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  color: selected ? VistaColors.accent : null,
                  borderRadius: BorderRadius.circular(VistaRadius.hairline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VistaNavItem {
  const VistaNavItem({required this.label, required this.asset});

  final String label;
  final String asset;
}

/// Floating capsule bottom navigation; the selected item expands to show its
/// label.
class VistaBottomNav extends StatelessWidget {
  const VistaBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<VistaNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: VistaSize.navBar,
      padding: const EdgeInsets.all(VistaSpace.md),
      decoration: BoxDecoration(
        color: VistaColors.surface,
        borderRadius: BorderRadius.circular(VistaRadius.pill),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [for (var i = 0; i < items.length; i++) _item(i)],
      ),
    );
  }

  Widget _item(int i) {
    final item = items[i];
    final selected = i == selectedIndex;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: VistaSize.navItem,
          constraints: const BoxConstraints(minWidth: 52),
          padding: selected
              ? const EdgeInsets.only(left: 16, right: 18)
              : const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? VistaColors.surfaceSelected : null,
            borderRadius: BorderRadius.circular(VistaRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              VistaIcon(
                item.asset,
                size: VistaSize.icon,
                color: selected ? VistaColors.onAccent : VistaColors.textMuted,
              ),
              if (selected) ...[
                const SizedBox(width: VistaSpace.md),
                Text(
                  item.label,
                  style: VistaType.navLabel.copyWith(
                    color: VistaColors.onAccent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
