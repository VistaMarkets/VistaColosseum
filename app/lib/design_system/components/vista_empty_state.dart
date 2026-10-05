import 'package:flutter/widgets.dart';

import '../tokens/vista_colors.dart';
import '../tokens/vista_metrics.dart';
import '../tokens/vista_typography.dart';
import 'vista_buttons.dart';

/// What a list shows when it has nothing to show, or failed to load: one
/// short line, an optional muted hint, and one action. Put it inside the
/// list, so it scrolls and keeps clear of the bottom strip like any row.
class VistaEmptyState extends StatelessWidget {
  const VistaEmptyState({
    super.key,
    required this.message,
    this.detail,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String? detail;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VistaSpace.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center, style: VistaType.subhead),
          if (detail != null) ...[
            const SizedBox(height: VistaSpace.sm),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: VistaType.body.copyWith(color: VistaColors.textMuted),
            ),
          ],
          const SizedBox(height: VistaSpace.md),
          VistaPillButton(label: actionLabel, onPressed: onAction),
        ],
      ),
    );
  }
}
