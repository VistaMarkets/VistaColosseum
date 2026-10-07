import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/design_system.dart';
import '../markets/market_chart_card.dart';

import '../account/account_state.dart';
import '../account/account_top_bar.dart';
import '../make_market/make_market_flow.dart';
import '../market/your_market_screen.dart';
import '../people/follow_list_screen.dart';
import '../people/follow_mock.dart';
import 'open_order_card.dart';
import 'orders_state.dart';
import 'positions_state.dart';
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
      // Scrolls under the floating nav; the end clears it.
      child: ListView(
        // The account bar sits where it does on Home, Explore and Arena.
        padding: EdgeInsets.only(
          bottom: VistaSpace.gutter + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Padding(padding: gutter, child: _profile()),
          gap,
          PortfolioPager(hasMarket: hasMarket, ticker: ticker, span: _span),
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
  /// 175:218): the page's one call to action, so it stands out as a tinted
  /// card (like "Make it a battle"), with the brand's dot pattern behind it.
  Widget _makeMarketButton() {
    return Semantics(
      button: true,
      label: 'Make a market',
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.98,
        onTap: () => Navigator.of(context).push(MakeMarketFlow.route()),
        child: Container(
          clipBehavior: Clip.antiAlias,
          // The blue is strongest behind the title and fades to the right.
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VistaColors.long.withValues(alpha: 0.30),
                VistaColors.long.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(VistaRadius.card),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.6,
                  child: SvgPicture.asset(
                    VistaAssets.makeMarketButtonDots,
                    fit: BoxFit.cover,
                    // The dots are drawn blue; tint them to the card's green.
                    colorFilter: const ColorFilter.mode(
                      VistaColors.long,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              // A rising line on the right, faded so the blue washes over
              // it: decoration for "your market", not data.
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: 220,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Color(0x00FFFFFF), Color(0x8CFFFFFF)],
                    stops: [0, 0.75],
                  ).createShader(r),
                  child: const CustomPaint(painter: _RisingLine()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VistaSpace.gutter,
                  vertical: VistaSpace.xxl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      // The text stays left of the line's brighter end.
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Make a market', style: VistaType.headline),
                              const SizedBox(height: VistaSpace.xxs),
                              Text(
                                'Let people trade your track record. You earn '
                                'the fees.',
                                style: VistaType.bodyMedium.copyWith(
                                  color: VistaColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: VistaSpace.md),
                    Text(
                      '›',
                      style: VistaType.displaySmall.copyWith(
                        color: VistaColors.long,
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

  Widget _positions() => ValueListenableBuilder(
    valueListenable: PositionsState.open,
    builder: (context, positions, _) => _positionList(positions),
  );

  Widget _positionList(List<PortfolioPosition> positions) {
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
            chart: PositionLineChart(position: p),
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

/// The faded line behind "Make a market": a market that climbs with a
/// couple of dips, in the up-green, with a soft fill under it.
class _RisingLine extends CustomPainter {
  const _RisingLine();

  static const _points = [
    (0.0, 0.78),
    (0.12, 0.70),
    (0.22, 0.74),
    (0.34, 0.58),
    (0.44, 0.62),
    (0.56, 0.44),
    (0.66, 0.50),
    (0.78, 0.32),
    (0.88, 0.26),
    (1.0, 0.14),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final line = Path();
    for (final (i, (x, y)) in _points.indexed) {
      final o = Offset(x * size.width, y * size.height);
      i == 0 ? line.moveTo(o.dx, o.dy) : line.lineTo(o.dx, o.dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            VistaColors.long.withValues(alpha: 0.35),
            VistaColors.long.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = VistaColors.long
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RisingLine old) => false;
}
