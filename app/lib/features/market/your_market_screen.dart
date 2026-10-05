import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../portfolio/portfolio_mock.dart';
import 'market_mock.dart';

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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  VistaSpace.gutter,
                  VistaSpace.md,
                  VistaSpace.gutter,
                  VistaSpace.gutter,
                ),
                children: [
                  _marketCap(),
                  gap,
                  const _MarketCapChart(),
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
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: VistaMetric(
                          label: 'Price',
                          value: YourMarketMock.price,
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
                    onLink: () => _notBuilt('All receipts'),
                  ),
                  Text(
                    YourMarketMock.recordSummary,
                    style: VistaType.bodyMedium,
                  ),
                  for (final e in YourMarketMock.record) ...[
                    gap,
                    VistaTimelineEntry(
                      railAsset: e.rail,
                      time: e.time,
                      title: e.title,
                      status: e.status,
                      statusColor: e.color,
                      detail: e.detail,
                    ),
                  ],
                ],
              ),
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

  Widget _marketCap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Market cap', style: VistaType.subheadMuted),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(PortfolioMock.marketCap, style: VistaType.display),
        ),
        const SizedBox(height: 3),
        Wrap(
          spacing: VistaSpace.xs,
          children: [
            Text(
              YourMarketMock.change24h,
              style: VistaType.bodyMedium.copyWith(color: VistaColors.long),
            ),
            Text('Last 24 hours', style: VistaType.bodyMedium),
          ],
        ),
        const SizedBox(height: 3),
        Text(YourMarketMock.unitLine, style: VistaType.caption),
        const SizedBox(height: 3),
        const VistaStatChip(
          value: YourMarketMock.feesThisWeek,
          label: 'earned in fees this week',
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

/// Market-cap line (static Figma vectors on a 370×150 box; x stretches).
class _MarketCapChart extends StatelessWidget {
  const _MarketCapChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: LayoutBuilder(
        builder: (context, c) {
          final sx = c.maxWidth / 370;
          Widget layer(String asset, Rect r) => Positioned(
            left: r.left * sx,
            top: r.top,
            width: r.width * sx,
            height: r.height,
            child: SvgPicture.asset(asset, fit: BoxFit.fill),
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              layer(
                VistaAssets.marketDotLattice,
                const Rect.fromLTWH(0, 0, 370, 150),
              ),
              layer(
                VistaAssets.marketBaseline,
                const Rect.fromLTWH(0, 141, 370, 1),
              ),
              layer(
                VistaAssets.marketClipAbove,
                const Rect.fromLTWH(-5, -6, 380, 148),
              ),
              layer(
                VistaAssets.marketClipBelow,
                const Rect.fromLTWH(-5, 142, 380, 14),
              ),
              // Live dot at the latest point, on the right edge.
              Positioned(
                left: c.maxWidth - 6.5,
                top: 1.5,
                child: const VistaIcon(VistaAssets.marketLiveHalo, size: 13),
              ),
              Positioned(
                left: c.maxWidth - 3.5,
                top: 4.5,
                child: const VistaIcon(VistaAssets.markerLive, size: 7),
              ),
            ],
          );
        },
      ),
    );
  }
}
