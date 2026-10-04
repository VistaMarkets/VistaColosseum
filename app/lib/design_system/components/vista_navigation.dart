import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_typography.dart';
import 'vista_icon.dart';
import '../tokens/vista_motion.dart';

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
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(i);
        },
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
                  AnimatedDefaultTextStyle(
                    duration: VistaMotion.state,
                    curve: VistaMotion.enter,
                    style: VistaType.tab.copyWith(
                      color: selected
                          ? VistaColors.textPrimary
                          : VistaColors.textInactive,
                    ),
                    child: Text(labels[i]),
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
              // The underline grows in under the picked tab.
              AnimatedContainer(
                duration: VistaMotion.state,
                curve: VistaMotion.enter,
                width: selected ? 20 : 0,
                height: 2,
                decoration: BoxDecoration(
                  color: VistaColors.accent,
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
///
/// One pill slides between items and stretches to the new label; the label
/// fades and slides in as the old one folds away, and icon colours blend
/// across. A tap part-way through carries on from wherever the pill is. Taps
/// press the item in slightly and give a selection haptic.
class VistaBottomNav extends StatefulWidget {
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
  State<VistaBottomNav> createState() => _VistaBottomNavState();
}

class _VistaBottomNavState extends State<VistaBottomNav>
    with SingleTickerProviderStateMixin {
  /// Material's emphasized easing: quick to leave, long gentle settle.
  static const Curve _curve = Cubic(0.2, 0, 0, 1);

  /// Item paddings and spacing, collapsed (icon only) and expanded.
  static const double _padCollapsed = 14;
  static const double _padLeft = 16;
  static const double _padRight = 18;
  static const double _labelGap = VistaSpace.md;

  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    value: 1,
  );

  /// Each item's expansion when the current move began.
  late List<double> _from = _oneHot(widget.selectedIndex);

  int? _pressed;

  List<double> _oneHot(int index) => [
    for (var i = 0; i < widget.items.length; i++) i == index ? 1 : 0,
  ];

  /// How expanded each item is right now (they always sum to 1).
  List<double> _expansion(int target) {
    final c = _curve.transform(_move.value);
    return [
      for (var i = 0; i < _from.length; i++)
        _from[i] + ((i == target ? 1 : 0) - _from[i]) * c,
    ];
  }

  @override
  void didUpdateWidget(VistaBottomNav old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      _from = _expansion(old.selectedIndex);
      _move.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  void _tap(int i) {
    if (i != widget.selectedIndex) HapticFeedback.selectionClick();
    widget.onChanged(i);
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final labelStyle = VistaType.navLabel.copyWith(color: VistaColors.onAccent);
    final labelWidths = [
      for (final item in widget.items)
        (TextPainter(
          text: TextSpan(text: item.label, style: labelStyle),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout()).width,
    ];

    return Container(
      height: VistaSize.navBar,
      padding: const EdgeInsets.all(VistaSpace.md),
      // A floating pill holding all four tabs (the same on every tab): the
      // card colour, a hairline edge and a soft shadow lift it off whatever
      // scrolls underneath; the selected tab's pill sits inside it.
      decoration: BoxDecoration(
        color: VistaColors.surfaceOverlay,
        borderRadius: BorderRadius.circular(VistaRadius.pill),
        border: Border.all(color: VistaColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: _move,
          builder: (context, _) {
            final e = _expansion(widget.selectedIndex);
            const collapsed = _padCollapsed * 2 + VistaSize.icon;
            final widths = [
              for (var i = 0; i < e.length; i++)
                collapsed +
                    e[i] *
                        (_padLeft +
                            VistaSize.icon +
                            _labelGap +
                            labelWidths[i] +
                            _padRight -
                            collapsed),
            ];
            // Items spread across the bar with equal gaps between them.
            final used = widths.fold(0.0, (a, b) => a + b);
            final gap = e.length > 1
                ? math.max(0.0, (constraints.maxWidth - used) / (e.length - 1))
                : 0.0;
            final lefts = <double>[];
            var x = 0.0;
            for (final w in widths) {
              lefts.add(x);
              x += w + gap;
            }
            // The pill sits where the expansion is: between two items while
            // moving, stretching from one width to the other.
            var pillLeft = 0.0;
            var pillWidth = 0.0;
            for (var i = 0; i < e.length; i++) {
              pillLeft += e[i] * lefts[i];
              pillWidth += e[i] * widths[i];
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: pillLeft,
                  width: pillWidth,
                  top: 0,
                  bottom: 0,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: VistaColors.surfaceSelected,
                      borderRadius: BorderRadius.all(
                        Radius.circular(VistaRadius.pill),
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < e.length; i++)
                  Positioned(
                    left: lefts[i],
                    width: widths[i],
                    top: 0,
                    bottom: 0,
                    child: _item(i, e[i]),
                  ),
                // Labels live inside the pill: clipped to it, so a label is
                // carried in and out by the pill and never shows beside it.
                Positioned(
                  left: pillLeft,
                  width: pillWidth,
                  top: 0,
                  bottom: 0,
                  // Visual only: each item already carries its label for
                  // accessibility.
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(VistaRadius.pill),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.centerLeft,
                          children: [
                            for (var i = 0; i < e.length; i++)
                              if (e[i] > 0.01)
                                Positioned(
                                  left:
                                      lefts[i] -
                                      pillLeft +
                                      _padCollapsed +
                                      (_padLeft - _padCollapsed) * e[i] +
                                      VistaSize.icon +
                                      _labelGap -
                                      6 * (1 - e[i]),
                                  child: Opacity(
                                    opacity: Curves.easeOut.transform(e[i]),
                                    child: Text(
                                      widget.items[i].label,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: labelStyle,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _item(int i, double e) {
    final item = widget.items[i];
    final selected = i == widget.selectedIndex;
    final pad = _padCollapsed + (_padLeft - _padCollapsed) * e;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = i),
        onTapUp: (_) => setState(() => _pressed = null),
        onTapCancel: () => setState(() => _pressed = null),
        onTap: () => _tap(i),
        child: AnimatedScale(
          scale: _pressed == i ? 0.92 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left: pad,
                  child: VistaIcon(
                    item.asset,
                    size: VistaSize.icon,
                    color: Color.lerp(
                      VistaColors.textMuted,
                      VistaColors.onAccent,
                      e,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
