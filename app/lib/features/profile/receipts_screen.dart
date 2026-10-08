import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import 'profile_mock.dart';

/// A trader's full record ("All receipts"), from their profile, trader
/// market or your own market: right / wrong / open counts, filters, and
/// every receipt; a receipt opens its detail. Every profile shows the same
/// sample receipts under its own handle (mock).
class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key, required this.handle});

  final String handle;

  static Route<void> route(String handle) =>
      MaterialPageRoute(builder: (_) => ReceiptsScreen(handle: handle));

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  /// 0 All, 1 Calls, 2 Arena, 3 Open.
  int _filter = 0;

  static const _filters = ['All', 'Calls', 'Debates', 'Open'];

  @override
  Widget build(BuildContext context) {
    final receipts = [
      for (final r in ProfileMock.receipts)
        if (switch (_filter) {
          1 => r.kind == ReceiptKind.call,
          2 => r.kind == ReceiptKind.arena,
          3 => r.open,
          _ => true,
        })
          r,
    ];
    final settled = int.parse(ProfileMock.settled);
    final right = int.parse(ProfileMock.right);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.md,
                VistaSpace.gutter,
                0,
              ),
              child: Row(
                children: [
                  VistaIconButton(
                    asset: VistaAssets.backSmall,
                    semanticLabel: 'Back',
                    iconSize: VistaSize.icon,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: VistaSpace.xs),
                  Expanded(
                    child: Text(
                      "${widget.handle}'s record",
                      style: VistaType.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  VistaSpace.gutter + VistaSpace.xs,
                  VistaSpace.gutter,
                  VistaSpace.gutter + VistaSpace.xs,
                  VistaSpace.gutter + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  // The headline: how often they're right.
                  Text(
                    '${(right / settled * 100).round()}% right',
                    style: VistaType.displayMedium,
                  ),
                  const SizedBox(height: VistaSpace.xs),
                  Text(
                    '$right of $settled settled calls and debates   '
                    '${ProfileMock.recordSince}',
                    style: VistaType.bodyMedium.copyWith(
                      color: VistaColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: VistaSpace.lg),
                  Wrap(
                    spacing: VistaSpace.xl,
                    children: [
                      for (final (text, color) in ProfileMock.summary)
                        Text(
                          text,
                          style: VistaType.body.copyWith(color: color),
                        ),
                    ],
                  ),
                  const SizedBox(height: VistaSpace.gutter),
                  Wrap(
                    spacing: VistaSpace.md,
                    runSpacing: VistaSpace.md,
                    children: [
                      for (final (i, f) in _filters.indexed)
                        VistaFilterChip(
                          label: f,
                          accent: true,
                          selected: i == _filter,
                          onPressed: () => setState(() => _filter = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: VistaSpace.md),
                  if (receipts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: VistaSpace.section),
                      child: Text(
                        'Nothing here yet',
                        style: VistaType.body.copyWith(
                          color: VistaColors.textMuted,
                        ),
                      ),
                    ),
                  for (final r in receipts)
                    VistaReceipt(
                      railAsset: r.rail,
                      title: r.title,
                      versus: r.versus,
                      lead: r.lead,
                      leadColor: r.leadColor,
                      detail: r.detail,
                      onTap: () => showReceiptSheet(context, r),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The open call behind a shared holding, as a receipt.
ProfileReceipt holdingReceipt(Holding h) => ProfileReceipt(
  kind: ReceiptKind.call,
  rail: VistaAssets.railCallOpen,
  title: '${h.ticker} ${h.side.label.toLowerCase()} ${h.leverage}x',
  lead: '${h.pnl} so far',
  leadColor: h.inProfit ? VistaColors.long : VistaColors.short,
  detail: 'Shared live while the position is open.',
  side: h.side,
  entry: h.entry,
  close: 'Now ${h.current}',
);

/// Slides a receipt's detail up: what was called, the side, entry, how it
/// ended (or where it stands) and the verdict.
Future<void> showReceiptSheet(BuildContext context, ProfileReceipt r) =>
    showVistaSheet<void>(
      context,
      color: VistaColors.background,
      builder: (_) => ReceiptSheet(receipt: r),
    );

/// One receipt in full. Open calls show where they stand; settled ones
/// their verdict.
class ReceiptSheet extends StatelessWidget {
  const ReceiptSheet({super.key, required this.receipt});

  final ProfileReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final r = receipt;
    final label = VistaType.bodyMedium.copyWith(color: VistaColors.textMuted);
    Widget row(String name, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: VistaSpace.lg),
      child: Row(
        children: [
          Expanded(child: Text(name, style: label)),
          value,
        ],
      ),
    );
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        VistaSpace.gutter + VistaSpace.xs,
        VistaSpace.lg,
        VistaSpace.gutter + VistaSpace.xs,
        bottom > 0 ? bottom : VistaSpace.gutter,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            r.kind == ReceiptKind.arena
                ? 'DEBATE${r.versus == null ? '' : '   vs ${r.versus!.name}'}'
                : 'CALL',
            style: VistaType.label.copyWith(
              color: VistaColors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: VistaSpace.xs),
          Text(r.title, style: VistaType.title),
          const SizedBox(height: VistaSpace.lg),
          // The verdict, or that it's still live.
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VistaSpace.xl,
                vertical: VistaSpace.sm,
              ),
              decoration: BoxDecoration(
                color: r.leadColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(VistaRadius.pill),
              ),
              child: Text(
                r.open ? 'Open   ${r.lead}' : r.lead,
                style: VistaType.subhead.copyWith(color: r.leadColor),
              ),
            ),
          ),
          const SizedBox(height: VistaSpace.md),
          row(
            'Side',
            Text(
              r.side.label.toUpperCase(),
              style: VistaType.subhead.copyWith(color: r.side.color),
            ),
          ),
          const VistaHairline(),
          row(
            'Called at',
            Text(r.entry, style: VistaType.figures(VistaType.subhead)),
          ),
          const VistaHairline(),
          row(
            r.open ? 'Now' : 'Settled at',
            Text(
              r.close.replaceFirst(RegExp(r'^(Now|Settled) '), ''),
              style: VistaType.figures(VistaType.subhead),
            ),
          ),
          const VistaHairline(),
          const SizedBox(height: VistaSpace.lg),
          Text(
            r.detail.isEmpty
                ? ''
                : r.detail[0].toUpperCase() + r.detail.substring(1),
            style: label,
          ),
          const SizedBox(height: VistaSpace.xs),
          Text(
            'Verdicts come from the price at the deadline, and only count '
            'calls made from a position.',
            style: VistaType.caption.copyWith(color: VistaColors.textMuted),
          ),
        ],
      ),
    );
  }
}
