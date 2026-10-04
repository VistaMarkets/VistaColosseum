import 'package:flutter/material.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_typography.dart';
import '../vista_assets.dart';
import 'vista_icon.dart';
import 'vista_pressable.dart';

/// Top bar with a back chevron, an optional centred title, and optional
/// trailing actions. Without actions an empty 44pt slot keeps the title
/// centred.
class VistaTitleBar extends StatelessWidget {
  const VistaTitleBar({
    super.key,
    required this.onBack,
    this.title,
    this.actions = const [],
  });

  final VoidCallback onBack;
  final String? title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VistaSpace.xs),
      child: Row(
        children: [
          VistaIconButton(
            asset: VistaAssets.back,
            semanticLabel: 'Back',
            iconSize: VistaSize.icon,
            onPressed: onBack,
          ),
          Expanded(
            child: title == null
                ? const SizedBox.shrink()
                : Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: VistaType.tab,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          if (actions.isEmpty)
            const SizedBox.square(dimension: VistaSize.tapTarget)
          else
            ...actions,
        ],
      ),
    );
  }
}

/// Rounded search input with a leading magnifier.
class VistaSearchField extends StatelessWidget {
  const VistaSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
    this.bordered = false,
    this.onSubmitted,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  /// Called on the keyboard's search action (e.g. the Arena ask bar).
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;

  /// Top-bar variant: hairline border, 16pt icon, lighter placeholder.
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final style = VistaType.subhead.copyWith(fontWeight: FontWeight.w400);
    return Container(
      height: 38,
      padding: EdgeInsets.symmetric(
        horizontal: bordered ? VistaSpace.xl : VistaSpace.xxl,
      ),
      decoration: BoxDecoration(
        // The bottom search is outline only; the inline variant is filled.
        color: bordered ? null : VistaColors.surface,
        borderRadius: BorderRadius.circular(VistaRadius.pill),
        border: bordered ? Border.all(color: VistaColors.divider) : null,
      ),
      child: Row(
        children: [
          bordered
              ? const VistaIcon(VistaAssets.search16, size: 16)
              : const VistaIcon(VistaAssets.search, size: 14),
          const SizedBox(width: VistaSpace.md),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: style,
              cursorColor: VistaColors.accent,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: style.copyWith(
                  color: bordered
                      ? VistaColors.textMuted
                      : VistaColors.textPlaceholder,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Follow / Following toggle: accent when not following, neutral when
/// following. 30 tall inside a 44 tap target.
class VistaFollowButton extends StatelessWidget {
  const VistaFollowButton({
    super.key,
    required this.following,
    required this.onPressed,
    this.expand = false,
  });

  final bool following;
  final VoidCallback onPressed;

  /// Fill the available width (profile header) instead of hugging the label.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final label = following ? 'Following' : 'Follow';
    return Semantics(
      button: true,
      toggled: following,
      label: label,
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.96,
        onTap: onPressed,
        child: SizedBox(
          height: VistaSize.tapTarget,
          child: Center(
            widthFactor: 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 30,
              width: expand ? double.infinity : null,
              padding: const EdgeInsets.symmetric(horizontal: VistaSpace.xxl),
              decoration: BoxDecoration(
                color: following
                    ? VistaColors.surfaceRaised
                    : VistaColors.accent,
                borderRadius: BorderRadius.circular(VistaRadius.pill),
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: VistaType.body.copyWith(
                    color: following
                        ? VistaColors.textPrimary
                        : VistaColors.onAccent,
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

/// Small grey tag beside a name, e.g. "Follows you".
class VistaBadge extends StatelessWidget {
  const VistaBadge(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: VistaColors.surfaceRaised,
        borderRadius: BorderRadius.circular(VistaRadius.sm),
      ),
      child: Text(
        label,
        style: VistaType.micro.copyWith(color: VistaColors.textMuted),
      ),
    );
  }
}

/// 64pt person row: avatar, name with optional lock and badge, a stats line,
/// and a trailing widget (usually a [VistaFollowButton]).
class VistaPersonRow extends StatelessWidget {
  const VistaPersonRow({
    super.key,
    required this.name,
    required this.stats,
    this.emphasis,
    this.locked = false,
    this.badge,
    this.trailing,
    this.onPressed,
  });

  final String name;

  /// Stats line, e.g. "118 calls · 1 open".
  final String stats;

  /// Optional tail of the stats line in a quieter grey, e.g. "Market $31.5M".
  final String? emphasis;
  final bool locked;
  final String? badge;
  final Widget? trailing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final meta = VistaType.chip.copyWith(
      fontWeight: FontWeight.w500,
      color: VistaColors.textSecondary,
    );
    return VistaPressable(
      scale: 0.98,
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
          child: Row(
            children: [
              const VistaIcon(
                VistaAssets.personAvatar,
                size: VistaSize.avatarLarge,
              ),
              const SizedBox(width: VistaSpace.xl),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: VistaType.subhead,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (locked) ...[
                          const SizedBox(width: VistaSpace.sm),
                          Semantics(
                            label: 'Private account',
                            child: const VistaIcon(
                              VistaAssets.lock,
                              size: 10,
                              height: 12,
                            ),
                          ),
                        ],
                        if (badge != null) ...[
                          const SizedBox(width: VistaSpace.sm),
                          VistaBadge(badge!),
                        ],
                      ],
                    ),
                    const SizedBox(height: VistaSpace.xxs),
                    Text.rich(
                      TextSpan(
                        text: stats,
                        children: [
                          if (emphasis != null)
                            TextSpan(
                              text: ' · $emphasis',
                              style: meta.copyWith(
                                color: VistaColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                      style: meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: VistaSpace.xl),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Divider between list rows, inset to start under the text (past a 40pt
/// avatar + 12 gap + 16 gutter).
class VistaListDivider extends StatelessWidget {
  const VistaListDivider({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 68, right: VistaSpace.gutter),
    child: Container(height: 1, color: VistaColors.hairline),
  );
}

/// Slim app top bar: avatar, bordered search/ask field, notifications bell.
class VistaSearchTopBar extends StatelessWidget {
  const VistaSearchTopBar({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onBell,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onBell;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VistaSpace.gutter,
        2,
        VistaSpace.xs,
        VistaSpace.xl,
      ),
      child: Row(
        children: [
          const VistaIcon(VistaAssets.topBarAvatar, size: 32),
          const SizedBox(width: VistaSpace.xl),
          Expanded(
            child: VistaSearchField(
              bordered: true,
              controller: controller,
              hint: hint,
              onChanged: onChanged ?? (_) {},
              onSubmitted: onSubmitted,
            ),
          ),
          VistaIconButton(
            asset: VistaAssets.bell,
            semanticLabel: 'Notifications',
            iconSize: 22,
            onPressed: onBell,
          ),
        ],
      ),
    );
  }
}
