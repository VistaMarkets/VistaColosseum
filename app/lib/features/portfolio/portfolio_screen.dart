import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../market/your_market_screen.dart';
import '../people/follow_list_screen.dart';
import '../people/follow_mock.dart';
import 'portfolio_mock.dart';
import 'portfolio_pager.dart';

/// Wallet tab (Figma 174:110, "Portfolio — dot grid · up").
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key, this.onNotBuilt});

  /// Called with a feature name when a control leads somewhere not built yet.
  final ValueChanged<String>? onNotBuilt;

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  int _span = PortfolioMock.defaultSpan;
  int _list = 0;

  void _notBuilt(String what) => widget.onNotBuilt?.call(what);

  @override
  Widget build(BuildContext context) {
    const gutter = EdgeInsets.symmetric(horizontal: VistaSpace.gutter);
    const gap = SizedBox(height: VistaSpace.sm);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(top: 9, bottom: VistaSpace.gutter),
        children: [
          Padding(padding: gutter, child: _profile()),
          gap,
          const PortfolioPager(),
          gap,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VistaSpace.xl),
            child: VistaSpanSelector(
              labels: PortfolioMock.spans,
              selectedIndex: _span,
              onChanged: (i) => setState(() => _span = i),
            ),
          ),
          gap,
          Padding(padding: gutter, child: _fees()),
          gap,
          Padding(
            padding: gutter,
            child: VistaUnderlineTabs(
              labels: const ['Positions', 'Open orders'],
              selectedIndex: _list,
              onChanged: (i) => setState(() => _list = i),
            ),
          ),
          gap,
          Padding(
            padding: gutter,
            child: _list == 0 ? _positions() : _noOpenOrders(),
          ),
        ],
      ),
    );
  }

  Widget _profile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: VistaSize.tapTarget,
          child: Row(
            children: [
              const VistaIcon(
                VistaAssets.portfolioAvatar,
                size: VistaSize.avatarLarge,
              ),
              const SizedBox(width: VistaSpace.lg),
              Expanded(
                child: Text(
                  PortfolioMock.handle,
                  style: VistaType.subhead,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              VistaCompactButton(
                label: 'Deposit',
                leading: '+',
                // Simulated only: the demo never moves funds.
                onPressed: () => _notBuilt('Deposit (simulated)'),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: VistaSpace.sm,
          runSpacing: VistaSpace.sm,
          children: [
            VistaStatChip(
              value: FollowMock.followerCount,
              label: 'Followers',
              onPressed: () =>
                  Navigator.of(context).push(FollowListScreen.route()),
            ),
            VistaStatChip(
              value: FollowMock.followingCount,
              label: 'Following',
              onPressed: () =>
                  Navigator.of(context)
                      .push(FollowListScreen.route(initialTab: 1)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fees() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const VistaIcon(VistaAssets.feesDot, size: 6),
                const SizedBox(width: VistaSpace.sm),
                Flexible(
                  child: Text(
                    'Fees from your market',
                    style: VistaType.bodyRegular,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: VistaSpace.sm),
                Text(PortfolioMock.fees, style: VistaType.bodyStrong),
              ],
            ),
          ),
          const SizedBox(width: VistaSpace.sm),
          VistaChevronPill(
            label: 'Your market',
            onPressed: () =>
                Navigator.of(context).push(YourMarketScreen.route()),
          ),
        ],
      ),
    );
  }

  Widget _positions() {
    const positions = PortfolioMock.positions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: VistaSpace.xs, top: 6),
          child: Text(
            'Positions · ${positions.length}',
            style: VistaType.body.copyWith(color: VistaColors.textMuted),
          ),
        ),
        for (final p in positions) ...[
          const SizedBox(height: VistaSpace.sm),
          VistaListRow(
            leading: p.coinAsset != null
                ? VistaListRow.coin(p.coinAsset!)
                : VistaListRow.initial(p.initial!),
            title: p.title,
            tag: p.tag,
            tagColor: p.side.color,
            sparkAsset: p.sparkAsset,
            value: p.pnl,
            change: p.pnlPercent,
            valueColor: p.pnlColor,
            onPressed: () => _notBuilt('Position details'),
          ),
        ],
      ],
    );
  }

  // Open orders has no Figma design yet.
  Widget _noOpenOrders() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(child: Text('No open orders', style: VistaType.bodyRegular)),
  );
}
