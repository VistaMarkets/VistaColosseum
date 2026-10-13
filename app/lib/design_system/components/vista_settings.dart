import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_typography.dart';
import 'vista_pressable.dart';

/// Settings building blocks (Figma "Settings · 2 — open" 442:102 and
/// "Settings 3 · Notifications open in place" 442:772).

/// Full-width hairline with 7pt above and below.
class VistaSettingsDivider extends StatelessWidget {
  const VistaSettingsDivider({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 7),
    child: SizedBox(
      height: 1,
      width: double.infinity,
      child: ColoredBox(color: VistaColors.hairline),
    ),
  );
}

/// Small caps heading inside an open section, e.g. "WHO NOTIFIES YOU".
class VistaSettingsHeading extends StatelessWidget {
  const VistaSettingsHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: VistaSpace.md),
    child: Text(
      text.toUpperCase(),
      style: VistaType.labelStrong.copyWith(
        color: VistaColors.textSecondary,
        letterSpacing: 0.6,
      ),
    ),
  );
}

/// Label (13) with an optional grey subtitle (11) and a trailing control.
class VistaSettingRow extends StatelessWidget {
  const VistaSettingRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor = VistaColors.textPrimary,
    this.verticalPadding = 6,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color titleColor;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: ConstrainedBox(
        // Rows without a 44pt control still keep a 44pt tap target.
        constraints: const BoxConstraints(minHeight: VistaSize.tapTarget - 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: VistaType.bodyRegular.copyWith(color: titleColor),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: VistaType.caption),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: VistaSpace.md),
              trailing!,
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// Trailing value text on a setting row, e.g. the wallet address.
class VistaSettingValue extends StatelessWidget {
  const VistaSettingValue(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: VistaType.body.copyWith(color: color ?? VistaColors.textPrimary),
  );
}

/// The "›" chevron used on navigable rows.
class VistaSettingChevron extends StatelessWidget {
  const VistaSettingChevron({super.key, this.open = false});

  /// Points down when the section is open.
  final bool open;

  @override
  Widget build(BuildContext context) => AnimatedRotation(
    turns: open ? 0.25 : 0,
    duration: const Duration(milliseconds: 200),
    child: Text(
      '›',
      style: VistaType.subheadMuted.copyWith(
        fontSize: 18,
        color: VistaColors.textSecondary,
      ),
    ),
  );
}

/// A section header that opens its rows in place below it.
class VistaExpandingSection extends StatelessWidget {
  const VistaExpandingSection({
    super.key,
    required this.title,
    required this.open,
    required this.onToggle,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool open;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          child: VistaSettingRow(
            title: title,
            subtitle: subtitle,
            verticalPadding: 13,
            trailing: VistaSettingChevron(open: open),
            onTap: onToggle,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: open
              ? Padding(
                  padding: const EdgeInsets.only(bottom: VistaSpace.md),
                  child: child,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// On/off switch: a 26×15 track in a 44pt target (Figma "SettingSwitch").
class VistaSwitch extends StatelessWidget {
  const VistaSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;

  static const _duration = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      toggled: value,
      button: true,
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.95,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: SizedBox.square(
          dimension: VistaSize.tapTarget,
          child: Center(
            child: AnimatedContainer(
              duration: _duration,
              width: 26,
              height: 15,
              decoration: BoxDecoration(
                color: value ? VistaColors.long : VistaColors.surfaceRaised,
                borderRadius: BorderRadius.circular(7.5),
              ),
              child: AnimatedAlign(
                duration: _duration,
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: VistaColors.textPrimary,
                    shape: BoxShape.circle,
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

/// Two or three short options in a pill, for settings with a fixed choice
/// (candles / line, left / right). Styled like the Figma "Edit" pill: the
/// chosen option sits on the raised grey.
class VistaSegmentedToggle extends StatelessWidget {
  const VistaSegmentedToggle({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    // A 30pt pill, but each option's tap target is the full 44pt height.
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Center(
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                color: VistaColors.surface,
                borderRadius: BorderRadius.circular(VistaRadius.pill),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (var i = 0; i < labels.length; i++) _option(i)],
          ),
        ),
      ],
    );
  }

  Widget _option(int i) {
    final selected = i == selectedIndex;
    return Semantics(
      button: true,
      selected: selected,
      child: VistaPressable(
        scale: 0.95,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(i);
        },
        child: SizedBox(
          height: VistaSize.tapTarget,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 26,
              constraints: const BoxConstraints(minWidth: 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? VistaColors.surfaceRaised : null,
                borderRadius: BorderRadius.circular(VistaRadius.pill),
              ),
              child: Text(
                labels[i],
                style: VistaType.bodyMedium.copyWith(
                  color: selected
                      ? VistaColors.textPrimary
                      : VistaColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
