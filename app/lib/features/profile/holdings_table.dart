import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../live/market_prices.dart';
import 'profile_mock.dart';

/// "Holding now" table: asset, side, entry, current and P/L per position,
/// then the cash share. Shared by the profile and the trader market panel.
class HoldingsTable extends StatelessWidget {
  const HoldingsTable({super.key, this.onRowTap});

  /// Tapping a position row: opens the receipt of the call it backs.
  final ValueChanged<Holding>? onRowTap;

  @override
  Widget build(BuildContext context) {
    final head = VistaType.labelStrong.copyWith(
      color: VistaColors.textSecondary,
    );
    const hairline = VistaHairline();
    final tap = onRowTap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HoldingRow(
          height: 14,
          asset: Text('Asset', style: head),
          side: Text('Side', style: head),
          entry: Text('Entry', style: head),
          current: Text('Current', style: head),
          pnl: Text('P/L', style: head),
        ),
        for (final h in ProfileMock.holdings) ...[
          const SizedBox(height: VistaSpace.md),
          hairline,
          const SizedBox(height: VistaSpace.md),
          _HoldingRow(
            onPressed: tap == null ? null : () => tap(h),
            asset: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _coin(h.ticker),
                const SizedBox(width: VistaSpace.md),
                Text(
                  h.ticker,
                  style: VistaType.bodyStrong.copyWith(fontSize: 14),
                ),
              ],
            ),
            side: Text(
              '${h.side.label} ${h.leverage}x',
              style: VistaType.body.copyWith(fontSize: 14, color: h.side.color),
            ),
            entry: Text(
              h.entry,
              style: VistaType.bodyMedium.copyWith(
                fontSize: 14,
                color: VistaColors.textMuted,
              ),
            ),
            // The market's one live price.
            current: ValueListenableBuilder(
              valueListenable: MarketPrices.of(h.ticker),
              builder: (context, price, _) => Text(
                MarketPrices.format(price, compact: true),
                style: VistaType.body.copyWith(fontSize: 14),
              ),
            ),
            pnl: Text(
              h.pnl,
              style: VistaType.bodyStrong.copyWith(
                fontSize: 14,
                color: h.inProfit ? VistaColors.long : VistaColors.short,
              ),
            ),
          ),
        ],
        const SizedBox(height: VistaSpace.md),
        hairline,
        const SizedBox(height: VistaSpace.md),
        SizedBox(
          height: 30,
          child: Row(
            children: [
              _coin('Cash'),
              const SizedBox(width: VistaSpace.md),
              Text(
                ProfileMock.cashShare,
                style: VistaType.body.copyWith(
                  fontSize: 14,
                  color: VistaColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VistaSpace.md),
        hairline,
        const SizedBox(height: VistaSpace.md),
        Text(
          'Tap a row for the call it backs and its chart.',
          style: VistaType.chip.copyWith(
            fontWeight: FontWeight.w500,
            color: VistaColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 20pt coin marks. SOL/ETH are exported vectors; BTC and cash are a
  /// coloured disc with a glyph, as drawn in Figma.
  Widget _coin(String ticker) {
    Widget disc(String bg, String glyph, TextStyle style, {double turn = 0}) =>
        SizedBox.square(
          dimension: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VistaIcon(bg, size: 20),
              Transform.rotate(
                angle: turn,
                child: Text(glyph, style: style),
              ),
            ],
          ),
        );
    return switch (ticker) {
      'SOL' => const VistaIcon(VistaAssets.coinSolSmall, size: 20),
      'ETH' => const VistaIcon(VistaAssets.coinEthSmall, size: 20),
      'BTC' => disc(
        VistaAssets.coinBtcBackground,
        '₿',
        VistaType.bodyStrong.copyWith(
          fontSize: 12,
          color: VistaColors.onAccent,
        ),
        turn: 0.21, // 12°
      ),
      _ => disc(
        VistaAssets.coinCashBackground,
        r'$',
        VistaType.bodyStrong.copyWith(color: VistaColors.textMuted),
      ),
    };
  }
}

/// One line of the holdings table. Column widths follow Figma's
/// 72 / 70 / flex / 72 / 76 / 60 split, scaled to the row's width.
class _HoldingRow extends StatelessWidget {
  const _HoldingRow({
    required this.asset,
    required this.side,
    required this.entry,
    required this.current,
    required this.pnl,
    this.height = 30,
    this.onPressed,
  });

  final Widget asset;
  final Widget side;
  final Widget entry;
  final Widget current;
  final Widget pnl;
  final double height;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    Widget cell(int flex, Widget child, {bool end = false}) => Expanded(
      flex: flex,
      child: Align(
        alignment: end ? Alignment.centerRight : Alignment.centerLeft,
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            cell(72, asset),
            cell(70, side),
            const Spacer(flex: 20),
            cell(72, entry, end: true),
            cell(76, current, end: true),
            cell(60, pnl, end: true),
          ],
        ),
      ),
    );
  }
}
