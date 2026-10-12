import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../live/live_feed.dart';
import 'share_targets.dart';

/// The image a shared copy shows as its link preview: Vista mark, a COPIED
/// tag, whose call was copied, the fee and who it went to, and the copier.
/// 346 × 182, the 1.91:1 link-preview shape, like `ShareCallCard`. Every
/// copy fee credits the creator (Oct 12 ruling 1), whoever made the call.
class CopyCard extends StatelessWidget {
  const CopyCard({
    super.key,
    required this.copier,
    required this.author,
    required this.symbol,
    required this.feeCents,
  });

  final String copier;
  final String author;
  final String symbol;
  final int feeCents;

  static const double width = 346;
  static const double height = 182;

  /// The card's lines, top to bottom; the on-screen footer adds
  /// "· Simulated".
  static String headline(String author, String symbol) =>
      'Copied @$author · $symbol';
  static String feeLine(int feeCents) =>
      '${formatCents(feeCents)} copy fee → @${Persona.creator.handle}';
  static String byLine(String copier) => 'by @$copier';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: VistaColors.background,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned(
              left: 16,
              top: 14,
              child: VistaIcon(VistaAssets.shareLogo, size: 27.43, height: 24),
            ),
            Positioned(
              right: 16,
              top: 20,
              child: Text(
                'COPIED',
                style: VistaType.micro.copyWith(color: VistaColors.long),
              ),
            ),
            Positioned(
              left: 16,
              width: width - 32,
              top: 64,
              child: Text(
                headline(author, symbol),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VistaType.subhead.copyWith(fontSize: 16),
              ),
            ),
            Positioned(
              left: 16,
              width: width - 32,
              top: 92,
              child: Text(
                feeLine(feeCents),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VistaType.body.copyWith(fontSize: 12),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: Text(
                '${byLine(copier)} · Simulated',
                style: VistaType.meta.copyWith(color: VistaColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the copy card's share sheet. Simulated: Copy text puts the card's
/// lines on the clipboard; every other target confirms and sends nothing.
/// Never writes the store.
Future<void> showCopyCardSheet(
  BuildContext context, {
  required String copier,
  required String author,
  required String symbol,
  required int feeCents,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: VistaColors.scrim,
    builder: (_) => CopyCardSheet(
      copier: copier,
      author: author,
      symbol: symbol,
      feeCents: feeCents,
    ),
  );
}

class CopyCardSheet extends StatelessWidget {
  const CopyCardSheet({
    super.key,
    required this.copier,
    required this.author,
    required this.symbol,
    required this.feeCents,
  });

  final String copier;
  final String author;
  final String symbol;
  final int feeCents;

  /// What Copy text puts on the clipboard: the card's lines, no
  /// "Simulated" suffix (the user's call, spec 13 Q-1).
  String get text =>
      '${CopyCard.headline(author, symbol)} · ${CopyCard.feeLine(feeCents)} · '
      '${CopyCard.byLine(copier)}';

  void _send(BuildContext context, String where) {
    HapticFeedback.selectionClick();
    final messenger = ScaffoldMessenger.of(context);
    final copy = where == 'Copy text';
    if (copy) Clipboard.setData(ClipboardData(text: text));
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            copy ? 'Card text copied' : 'Shared to $where (simulated)',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;
    const gap = SizedBox(height: 12);
    return Container(
      decoration: const BoxDecoration(
        color: VistaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 30 + safe),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: VistaDragHandle()),
            gap,
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Share copy',
                    style: VistaType.subhead.copyWith(fontSize: 20),
                  ),
                ),
                Semantics(
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'Done',
                      style: VistaType.subhead.copyWith(
                        color: VistaColors.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            gap,
            Text(
              "WHAT THEY'LL SEE",
              style: VistaType.labelStrong.copyWith(
                color: VistaColors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
            gap,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VistaColors.background,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: CopyCard(
                    copier: copier,
                    author: author,
                    symbol: symbol,
                    feeCents: feeCents,
                  ),
                ),
              ),
            ),
            gap,
            ShareTargets(
              copyLabel: 'Copy text',
              onSend: (where) => _send(context, where),
            ),
          ],
        ),
      ),
    );
  }
}
