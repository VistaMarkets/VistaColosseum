import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// The share sheets' row of targets: Messages, Telegram, X, and a copy
/// target named by [copyLabel]. Each is a Semantics button with its label;
/// [onSend] receives the label as shown. Simulated: the sheet that owns the
/// row decides what a tap does.
class ShareTargets extends StatelessWidget {
  const ShareTargets({
    super.key,
    required this.onSend,
    this.copyLabel = 'Copy link',
  });

  final void Function(String label) onSend;
  final String copyLabel;

  @override
  Widget build(BuildContext context) {
    final targets = [
      ('Messages', VistaAssets.shareMessages, 22.0),
      ('Telegram', VistaAssets.shareTelegram, 48.0),
      ('X', VistaAssets.shareX, 22.0),
      (copyLabel, VistaAssets.shareCopyLink, 22.0),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (label, asset, size) in targets)
          Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSend(label),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: VistaColors.surfaceRaised,
                      shape: BoxShape.circle,
                    ),
                    child: VistaIcon(asset, size: size),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: VistaType.meta.copyWith(
                      color: VistaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
