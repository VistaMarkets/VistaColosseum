import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/design_system.dart';

import '../account/account_state.dart';
import '../account/account_top_bar.dart';
import '../make_market/make_market_flow.dart';
import '../market/your_market_screen.dart';
import '../people/follow_list_screen.dart';
import '../people/follow_mock.dart';
import 'open_order_card.dart';
import 'orders_state.dart';
import 'portfolio_mock.dart';
import 'portfolio_pager.dart';
import 'position_sheet.dart';

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

  /// Cancel removes a resting order (simulated, with Undo).
  void _cancelOrder(OpenOrder order) {
    final index = OrdersState.remove(order);
    if (index < 0) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${order.symbol} limit order cancelled (simulated)'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => OrdersState.insert(index, order),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AccountState.hasMarket,
        AccountState.ticker,
      ]),
      builder: (context, _) =>
          _page(AccountState.hasMarket.value, AccountState.ticker.value),
    );
  }

  Widget _page(bool hasMarket, String ticker) {
    const gutter = EdgeInsets.symmetric(horizontal: VistaSpace.gutter);
    const gap = SizedBox(height: VistaSpace.sm);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(top: 9, bottom: VistaSpace.gutter),
        children: [
          Padding(padding: gutter, child: _profile()),
          gap,
          PortfolioPager(hasMarket: hasMarket, ticker: ticker),
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
          Padding(
            padding: gutter,
            child: hasMarket ? _fees() : _makeMarketButton(),
          ),
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
            child: _list == 0 ? _positions() : _openOrders(),
          ),
        ],
      ),
    );
  }

  Widget _profile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AccountTopBar(onNotBuilt: widget.onNotBuilt, showSettings: true),
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

  /// Shown in place of the fees row until the user lists a market (Figma
  /// 175:218).
  Widget _makeMarketButton() {
    return Semantics(
      button: true,
      label: 'Make a market',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(MakeMarketFlow.route()),
        child: SizedBox(
          height: VistaSize.tapTarget,
          child: Center(
            child: Container(
              height: 37,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: VistaColors.surface,
                borderRadius: BorderRadius.circular(VistaRadius.pill),
                border: Border.all(color: VistaColors.accent, width: 0.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: SvgPicture.asset(
                      VistaAssets.makeMarketButtonDots,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Make a market',
                        style: VistaType.headline.copyWith(
                          color: VistaColors.accent,
                        ),
                      ),
                      const SizedBox(width: VistaSpace.md),
                      Text(
                        '↗',
                        style: VistaType.headline.copyWith(
                          color: VistaColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
            onPressed: () => showPositionSheet(context, p),
          ),
        ],
      ],
    );
  }

  // Open orders has no Figma design; cards follow the backend's order model.
  Widget _openOrders() {
    return ValueListenableBuilder(
      valueListenable: OrdersState.open,
      builder: (context, orders, _) => _orderList(orders),
    );
  }

  Widget _orderList(List<OpenOrder> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: VistaSpace.xs, top: 6),
          child: Text(
            'Open orders · ${orders.length}',
            style: VistaType.body.copyWith(color: VistaColors.textMuted),
          ),
        ),
        if (orders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No open orders', style: VistaType.bodyRegular),
            ),
          ),
        for (final o in orders)
          Padding(
            key: ValueKey(o.id),
            padding: const EdgeInsets.only(top: VistaSpace.sm),
            child: OpenOrderCard(order: o, onCancel: () => _cancelOrder(o)),
          ),
      ],
    );
  }
}
