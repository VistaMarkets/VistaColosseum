import 'package:flutter/material.dart';

import '../../charting/time_marks.dart';
import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../live/live_feed.dart';
import '../live/market_prices.dart';
import '../profile/profile_mock.dart';
import 'market_mock.dart';
import '../../app_shell.dart';

/// "26 Sep · 11:45".
String _when(DateTime t) =>
    '${timeLabel(t, const Duration(days: 1))} · '
    '${timeLabel(t, const Duration(hours: 1))}';

/// A titled screen whose list keeps clear of the simulation strip.
Widget _page(
  BuildContext context, {
  required String title,
  required List<Widget> children,
  Widget? footer,
}) {
  return Scaffold(
    body: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VistaTitleBar(
            title: title,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.md,
                VistaSpace.gutter,
                footer == null
                    ? MediaQuery.paddingOf(context).bottom + VistaSpace.gutter
                    : VistaSpace.gutter,
              ),
              children: children,
            ),
          ),
          ?footer,
        ],
      ),
    ),
  );
}

/// The fee ledger of the user's market (VC-MKT-004): every credit, naming
/// its market and event, and their sum as the footer. Illustrative: the
/// 40% creator share is a demo assumption.
class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const LedgerScreen());

  /// Works [e] back from the fee traders paid: fee × 40% = the credit.
  /// The fee is the credit ÷ 40% in int cents, rounded half up; the result
  /// shown is the listed credit itself, never recomputed from the fee.
  static String example(FeeEntry e) {
    const pct = YourMarketMock.creatorSharePct;
    final fee = (e.amountCents * 100 + pct ~/ 2) ~/ pct;
    return 'Example: ${e.eventTitle} on ${e.marketId}: traders paid '
        '${formatCents(fee)} in fees. $pct% of ${formatCents(fee)} = '
        '${formatCents(e.amountCents)}, its credit below.';
  }

  @override
  Widget build(BuildContext context) {
    final muted = VistaType.caption.copyWith(color: VistaColors.textMuted);
    return ListenableBuilder(
      listenable: Listenable.merge([Scenario.feeEntries, Scenario.marketId]),
      builder: (context, _) {
        final entries = Scenario.marketFees;
        final copies = Scenario.copyFees;
        return _page(
          context,
          title: 'Fee ledger',
          children: [
            Text(
              'Illustrative demo ledger · ${YourMarketMock.shareLabel}',
              style: VistaType.bodyMedium,
            ),
            if (entries.isNotEmpty) ...[
              const SizedBox(height: VistaSpace.sm),
              Text(example(entries.first), style: muted),
            ],
            const SizedBox(height: VistaSpace.md),
            if (entries.isEmpty && copies.isEmpty)
              VistaEmptyState(
                message: 'No fee credits yet',
                actionLabel: 'Explore markets',
                onAction: () => AppShell.showExplore(context),
              ),
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: VistaSpace.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.eventTitle, style: VistaType.bodyStrong),
                          Text('${e.marketId} · ${_when(e.at)}', style: muted),
                        ],
                      ),
                    ),
                    const SizedBox(width: VistaSpace.md),
                    Text(
                      formatCents(e.amountCents),
                      style: VistaType.bodyStrong,
                    ),
                  ],
                ),
              ),
            // Flat fees copiers paid to copy the creator's calls.
            if (copies.isNotEmpty) ...[
              const SizedBox(height: VistaSpace.xl),
              const VistaSectionHead(title: 'COPY FEES'),
              for (final e in copies)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: VistaSpace.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.eventTitle} · @${e.counterparty} · '
                              '${e.asset}',
                              style: VistaType.bodyStrong,
                            ),
                            Text(_when(e.at), style: muted),
                          ],
                        ),
                      ),
                      const SizedBox(width: VistaSpace.md),
                      Text(
                        formatCents(e.amountCents),
                        style: VistaType.bodyStrong,
                      ),
                    ],
                  ),
                ),
            ],
          ],
          // The sum of exactly the entries listed above, kept clear of the
          // simulation strip.
          footer: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: VistaColors.hairline)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.xl,
                VistaSpace.gutter,
                MediaQuery.paddingOf(context).bottom + VistaSpace.xxl,
              ),
              child: Row(
                children: [
                  Expanded(child: Text('Total', style: VistaType.bodyStrong)),
                  Text(
                    formatCents(
                      Scenario.marketFeesCents +
                          copies.fold(0, (sum, e) => sum + e.amountCents),
                    ),
                    style: VistaType.bodyStrong,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One call in a record list; tapping it opens its receipt.
class CallRecordItem extends StatelessWidget {
  const CallRecordItem({super.key, required this.receipt});

  final CallReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            Navigator.of(context).push(CallReceiptScreen.route(receipt)),
        child: VistaTimelineEntry(
          railAsset: receipt.rail,
          time: receipt.entryAt ?? unavailable,
          title: receipt.rule ?? unavailable,
          status: receipt.status,
          statusColor: receipt.color,
          detail: receipt.detail,
        ),
      ),
    );
  }
}

/// [author]'s call receipts, as the store holds them, each opening its
/// receipt.
class CallRecordList extends StatelessWidget {
  const CallRecordList({super.key, required this.author});

  final String author;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Scenario.callReceipts,
      builder: (context, calls, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in calls)
            if (c.author == author) ...[
              const SizedBox(height: VistaSpace.xl),
              CallRecordItem(receipt: c),
            ],
        ],
      ),
    );
  }
}

/// A trader's record panel (VC-MKT-002, VC-FED-003): sample size, outcomes,
/// hit rate and as-of time, from [Scenario.record] at render time. With no
/// settled call there is no record: it says so instead.
class TraderRecordPanel extends StatelessWidget {
  const TraderRecordPanel({super.key, required this.handle});

  static const unavailableNote = 'No settled calls yet — record unavailable';

  final String handle;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([Scenario.callReceipts, Scenario.clock]),
      builder: (context, _) {
        final m = Scenario.record(handle);
        final pct = m.hitRatePct;
        if (pct == null) {
          return Text(
            m.unavailable == 0
                ? unavailableNote
                : '$unavailableNote · ${m.unavailable} unavailable',
            style: VistaType.bodyMedium,
          );
        }
        final n = m.settled;
        final t = m.asOf;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Illustrative index · based on $n settled '
              'call${n == 1 ? '' : 's'} · as of '
              '${timeLabel(t, const Duration(days: 1))} '
              '${timeLabel(t, const Duration(hours: 1))}',
              style: VistaType.caption.copyWith(color: VistaColors.textMuted),
            ),
            const SizedBox(height: VistaSpace.md),
            Wrap(
              spacing: VistaSpace.xl,
              children: [
                for (final (text, color) in [
                  ('$n settled', VistaColors.textPrimary),
                  ('${m.right} right', VistaColors.long),
                  ('${m.wrong} wrong', VistaColors.short),
                  ('${m.open} open', VistaColors.textMuted),
                  if (m.unavailable > 0)
                    ('${m.unavailable} unavailable', VistaColors.textMuted),
                  ('Hit rate $pct%', VistaColors.textPrimary),
                ])
                  Text(text, style: VistaType.body.copyWith(color: color)),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Every receipt for [author]: their call receipts, then, on the user's
/// own list only, the user's paper order receipts, in a separate section.
class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key, required this.author});

  static Route<void> route(String author) =>
      MaterialPageRoute(builder: (_) => ReceiptsScreen(author: author));

  final String author;

  @override
  Widget build(BuildContext context) {
    final muted = VistaType.caption.copyWith(color: VistaColors.textMuted);
    return ListenableBuilder(
      listenable: Listenable.merge([
        Scenario.callReceipts,
        Scenario.receipts,
        Scenario.activePersona,
      ]),
      builder: (context, _) {
        // Paper receipts are the active persona's own.
        final own = author == Scenario.activePersona.value.handle;
        final calls = [
          for (final c in Scenario.callReceipts.value)
            if (c.author == author) c,
        ];
        return _page(
          context,
          title: 'All receipts',
          children: [
            Text(author, style: muted),
            const SizedBox(height: VistaSpace.xl),
            const VistaSectionHead(title: 'CALL RECEIPTS'),
            const SizedBox(height: VistaSpace.md),
            if (calls.isEmpty)
              VistaEmptyState(
                message:
                    'No call receipts for $author in ${Scenario.fixtureVersion}',
                actionLabel: 'Explore markets',
                onAction: () => AppShell.showExplore(context),
              ),
            for (final c in calls) CallRecordItem(receipt: c),
            if (own) ...[
              const SizedBox(height: VistaSpace.xl),
              const VistaSectionHead(title: 'PAPER ORDER RECEIPTS'),
              if (Scenario.receipts.value.isEmpty)
                VistaEmptyState(
                  message: 'No paper orders yet',
                  actionLabel: 'Explore markets',
                  onAction: () => AppShell.showExplore(context),
                ),
              for (final r in Scenario.receipts.value)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: VistaSpace.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${r.side.label} ${r.symbol} ${r.leverage}x',
                              style: VistaType.bodyStrong,
                            ),
                            Text(
                              'Paper fill at ${MarketPrices.format(r.price)} · '
                              '${formatCents(r.notionalCents)} notional · '
                              'fee ${formatCents(r.feeCents)} · ${_when(r.at)}',
                              style: muted,
                            ),
                            if (r.copyFeeCents > 0)
                              Text(
                                copyLine(r.sourceAuthorHandle!, r.copyFeeCents),
                                style: muted,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: VistaSpace.md),
                      Text(
                        formatCents(r.totalCents),
                        style: VistaType.bodyStrong,
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

/// One call's receipt: every field, each missing one shown as unavailable.
class CallReceiptScreen extends StatelessWidget {
  const CallReceiptScreen({super.key, required this.receipt});

  static Route<void> route(CallReceipt receipt) =>
      MaterialPageRoute(builder: (_) => CallReceiptScreen(receipt: receipt));

  /// Call details for [author]'s [holding]: the receipt of the author's
  /// open call on the same asset and side, or an unavailable receipt
  /// when the fixture names none (VC-FED-003).
  static Route<void> forHolding(String author, Holding holding) {
    for (final c in Scenario.callReceipts.value) {
      if (c.author == author &&
          c.asset == holding.ticker &&
          c.side == holding.side &&
          c.result == CallOutcome.open) {
        return route(c);
      }
    }
    return route(
      CallReceipt(id: 'none', author: author, asset: holding.ticker),
    );
  }

  final CallReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final r = receipt;
    final fields = [
      ('Author', r.author),
      ('Asset', r.asset),
      ('Direction', r.side?.label),
      ('Entry price', r.entryPrice),
      ('Paper size', r.sizeCents == null ? null : formatCents(r.sizeCents!)),
      ('Entered', r.entryAt),
      ('Rule', r.rule),
      ('Result', r.result == null ? null : r.status),
      (
        'Settled',
        r.result == CallOutcome.open ? 'Not settled yet' : r.settledAt,
      ),
      ('Market said', r.odds),
      ('Provenance', r.provenance),
    ];
    return _page(
      context,
      title: 'Call receipt',
      children: [
        Text(
          r.rule == null
              ? 'No open call in ${Scenario.fixtureVersion} backs this holding'
              : 'A published call, not an order fill',
          style: VistaType.bodyMedium,
        ),
        const SizedBox(height: VistaSpace.md),
        for (final (label, value) in fields)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: VistaSpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: VistaType.bodyMedium.copyWith(
                      color: VistaColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: VistaSpace.md),
                Expanded(
                  flex: 2,
                  child: Text(
                    value ?? unavailable,
                    textAlign: TextAlign.end,
                    style: value == null
                        ? VistaType.body.copyWith(color: VistaColors.textMuted)
                        : VistaType.bodyStrong,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
