import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../portfolio/series_chart.dart';
import '../live/live_feed.dart';
import '../portfolio/portfolio_mock.dart';
import 'market_mock.dart';
import 'receipt_screens.dart';

/// The user's own market, opened from Portfolio's "Your market" button
/// (Figma 168:110, "Your market — as built").
class YourMarketScreen extends StatefulWidget {
  const YourMarketScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const YourMarketScreen());

  @override
  State<YourMarketScreen> createState() => _YourMarketScreenState();
}

class _YourMarketScreenState extends State<YourMarketScreen> {
  int _span = PortfolioMock.defaultSpan;

  void _notBuilt(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what — not in the demo yet')));
  }

  @override
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const gap = SizedBox(height: VistaSpace.xl);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: Scenario.ticker,
              builder: (context, ticker, _) => VistaDetailHeader(
                avatarAsset: VistaAssets.portfolioAvatar,
                title: ticker,
                subtitle: '${PortfolioMock.handle} · your market',
                onBack: () => Navigator.of(context).maybePop(),
                actionGlyph: '↗',
                actionLabel: 'Share',
                onAction: () => _notBuilt('Share'),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: Scenario.ownCap,
                builder: (context, _) {
                  final cap = Scenario.ownCapCents;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                    VistaSpace.gutter,
                    VistaSpace.md,
                    VistaSpace.gutter,
                    VistaSpace.gutter,
                  ),
                  children: [
                    _marketCap(cap),
                    gap,
                    if (ownCapSeries(_span) case final s?) SizedBox(height: 150, child: SeriesChart(focus: s)) else const SizedBox(height: 150),
                    gap,
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VistaSpace.xl,
                      ),
                      child: VistaSpanSelector(
                        labels: PortfolioMock.spans,
                        selectedIndex: _span,
                        onChanged: (i) => setState(() => _span = i),
                      ),
                    ),
                    gap,
                    const VistaHairline(),
                    gap,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: VistaMetric(
                            label: 'Price',
                            value: cap == null ? unavailable : formatUnitPrice(cap, YourMarketMock.supplyUnits),
                            valueColor: cap == null ? VistaColors.textMuted : VistaColors.textPrimary,
                          ),
                        ),
                        SizedBox(width: VistaSpace.md),
                        Expanded(
                          child: VistaMetric(
                            label: 'Skew',
                            value: YourMarketMock.skew,
                          ),
                        ),
                        SizedBox(width: VistaSpace.md),
                        Expanded(
                          child: VistaMetric(
                            label: 'Open interest',
                            value: YourMarketMock.openInterest,
                          ),
                        ),
                      ],
                    ),
                    gap,
                    Text(YourMarketMock.funding, style: VistaType.bodyMedium),
                    gap,
                    _holders(),
                    gap,
                    const VistaHairline(),
                    // The head's 44pt link target stands in for the gaps.
                    VistaSectionHead(
                      title: 'RECORD',
                      linkLabel: 'All receipts',
                      onLink: () =>
                          Navigator.of(context)
                              .push(ReceiptsScreen.route(PortfolioMock.handle)),
                    ),
                    const TraderRecordPanel(handle: PortfolioMock.handle),
                    // The user's call receipts; each opens its receipt.
                    const CallRecordList(author: PortfolioMock.handle),
                  ],
                );
              }),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.lg,
                VistaSpace.gutter,
                bottomInset > 0 ? bottomInset : VistaSpace.gutter,
              ),
              child: VistaPillButton(
                label: 'Make a call',
                variant: VistaPillVariant.accent,
                onPressed: () => _notBuilt('Make a call'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _marketCap(int? cap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Market cap', style: VistaType.subheadMuted),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(cap == null ? unavailable : formatCap(cap), style: VistaType.display),
        ),
        const SizedBox(height: 3),
        Wrap(
          spacing: VistaSpace.xs,
          children: [
            Text(
              cap == null ? unavailable : formatCapChange(cap - Scenario.ownCapMoveCents(_span), cap),
              style: VistaType.bodyMedium.copyWith(color: cap == null ? VistaColors.textMuted : (Scenario.ownCapMoveCents(_span) >= 0 ? VistaColors.long : VistaColors.short)),
            ),
            Text(spanWindows[_span], style: VistaType.bodyMedium),
          ],
        ),
        const SizedBox(height: 3),
        Text(cap == null ? unavailable : '${formatUnitPrice(cap, YourMarketMock.supplyUnits)} / unit · ${YourMarketMock.supplyUnits ~/ 1000000}M supply', style: VistaType.caption),
        const SizedBox(height: 3),
        // Market credits only (spec 06): the ledger Total adds copy fees.
        // Never a stored figure; opens the ledger.
        ListenableBuilder(
          listenable: Listenable.merge([
            Scenario.feeEntries,
            Scenario.marketId,
          ]),
          builder: (context, _) => VistaStatChip(
            value: formatCents(Scenario.marketFeesCents),
            label: 'earned in fees this week',
            onPressed: () => Navigator.of(context).push(LedgerScreen.route()),
          ),
        ),
      ],
    );
  }

  Widget _holders() {
    return Row(
      children: [
        const VistaIcon(VistaAssets.holdersAvatars, size: 64, height: 22),
        const SizedBox(width: VistaSpace.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(YourMarketMock.holders, style: VistaType.bodyStrong),
              Text(
                YourMarketMock.holderSplit,
                style: VistaType.caption.copyWith(color: VistaColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: VistaSpace.lg),
        Text(
          YourMarketMock.holdersChange,
          style: VistaType.label.copyWith(color: VistaColors.textMuted),
        ),
      ],
    );
  }
}

