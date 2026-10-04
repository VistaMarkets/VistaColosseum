import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../home/mock_trade_idea.dart';
import '../live/market_prices.dart';
import 'share_call_card.dart';

/// Opens the share sheet for [idea] (Figma "sheet · share call", 462:474):
/// a preview of exactly what the recipient will see (an optional note over
/// the call's link preview), share targets, and two options. Simulated: the
/// demo copies the link or confirms; nothing is sent.
Future<void> showShareCallSheet(BuildContext context, TradeIdea idea) {
  return showVistaSheet<void>(
    context,
    builder: (_) => ShareCallSheet(idea: idea),
  );
}

class ShareCallSheet extends StatefulWidget {
  const ShareCallSheet({super.key, required this.idea});

  final TradeIdea idea;

  @override
  State<ShareCallSheet> createState() => _ShareCallSheetState();
}

class _ShareCallSheetState extends State<ShareCallSheet> {
  /// The link bubble, a step above the preview (Figma color/surfaceRaised,
  /// #262626).
  static const _bubble = VistaColors.surface;

  /// A short, stable code for the call's link.
  String get _code {
    final h = '${widget.idea.callerHandle}/${widget.idea.ticker}'.codeUnits
        .fold<int>(11, (a, c) => (a * 33 + c) & 0x3fffffff);
    return h.toRadixString(36).padLeft(6, '0').substring(0, 6);
  }

  String get _url => 'vistamarkets.xyz/c/$_code';

  String _title(double price) {
    final i = widget.idea;
    var pct = (price - i.callPrice) / i.callPrice * 100;
    if (i.side == TradeSide.short) pct = -pct;
    final move = pct >= 0
        ? 'is up ${pct.toStringAsFixed(2)}%'
        : 'is down ${pct.abs().toStringAsFixed(2)}%';
    return "${i.callerHandle}'s ${i.ticker} ${i.side.label.toLowerCase()} "
        '$move since the call';
  }

  void _send(String where) {
    HapticFeedback.selectionClick();
    final messenger = ScaffoldMessenger.of(context);
    if (where == 'Copy link') {
      Clipboard.setData(ClipboardData(text: 'https://$_url'));
    }
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            where == 'Copy link'
                ? 'Link copied'
                : 'Shared to $where (simulated)',
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VistaRadius.sheet),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 30 + safe),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: VistaDragHandle()),
            gap,
            Row(
              children: [
                Expanded(child: Text('Share call', style: VistaType.title)),
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
            _preview(),
            gap,
            _targets(),
            gap,
            Semantics(
              button: true,
              label: 'Share call',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => _send('your apps'),
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: VistaColors.accent,
                    borderRadius: BorderRadius.circular(VistaRadius.pill),
                  ),
                  child: Text(
                    'Share call',
                    style: VistaType.headline.copyWith(
                      color: VistaColors.onAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// What the recipient gets: the call's link preview.
  Widget _preview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VistaColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: _bubble,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FittedBox(
                fit: BoxFit.fitWidth,
                child: ShareCallCard(idea: widget.idea),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: MarketPrices.of(widget.idea.ticker),
                      builder: (context, price, _) =>
                          Text(_title(price), style: VistaType.body),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _url,
                      style: VistaType.meta.copyWith(
                        color: VistaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _targets() {
    const targets = [
      ('Messages', VistaAssets.shareMessages, 22.0),
      ('Telegram', VistaAssets.shareTelegram, 48.0),
      ('X', VistaAssets.shareX, 22.0),
      ('Copy link', VistaAssets.shareCopyLink, 22.0),
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
              onTap: () => _send(label),
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
