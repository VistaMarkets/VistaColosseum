import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../home/mock_trade_idea.dart';
import '../home/signal_replay_chart.dart';
import '../live/market_prices.dart';

/// A caller's record as the share card shows it ("36 of 62 right"). The
/// Figma card's caller has the designed record; others get a steady one
/// per handle. Simulated.
(int right, int settled) callerRecord(String handle) {
  if (handle == 'kaito.eth') return (36, 62);
  final h = handle.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0xffff);
  final right = 18 + h % 30;
  return (right, right + 12 + (h ~/ 7) % 25);
}

/// The image a shared call shows as its link preview outside the app
/// (Figma "CallShareCard", 465:530): Vista mark, side, the question, caller and
/// record with the move since the call, and the replay drawn in the app's
/// line style. 346 × 182, the 1.91:1 link-preview shape.
class ShareCallCard extends StatelessWidget {
  const ShareCallCard({super.key, required this.idea});

  final TradeIdea idea;

  static const double width = 346;
  static const double height = 182;
  static const double _chartTop = 96;

  @override
  Widget build(BuildContext context) {
    final i = idea;
    final long = i.side == TradeSide.long;
    final (right, settled) = callerRecord(i.callerHandle);
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: VistaColors.background,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // The replay, in the app's line style, along the bottom.
            Positioned(
              left: 0,
              right: 0,
              top: _chartTop,
              bottom: 0,
              child: _Chart(idea: i),
            ),
            // The Vista mark.
            const Positioned(
              left: 16,
              top: 14,
              child: VistaIcon(VistaAssets.shareLogo, size: 27.43, height: 24),
            ),
            Positioned(
              right: 16 - 8,
              top: 17,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  '${long ? 'LONG' : 'SHORT'} ${i.ticker.toUpperCase()}',
                  style: VistaType.micro.copyWith(color: i.side.color),
                ),
              ),
            ),
            Positioned(
              left: 16,
              width: 314,
              top: 48,
              height: 20,
              // One line: scales down a touch rather than cutting off.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  i.question,
                  maxLines: 1,
                  style: VistaType.subhead.copyWith(fontSize: 16),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 76,
              child: Row(
                children: [
                  const VistaIcon(VistaAssets.shareAvatar, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    i.callerHandle,
                    style: VistaType.body.copyWith(fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· $right of $settled right',
                    style: VistaType.meta.copyWith(
                      color: VistaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              top: 74,
              child: ValueListenableBuilder(
                valueListenable: MarketPrices.of(i.ticker),
                builder: (context, price, _) {
                  var pct = (price - i.callPrice) / i.callPrice * 100;
                  if (!long) pct = -pct;
                  return Text(
                    '${pct >= 0 ? '+' : '−'}${pct.abs().toStringAsFixed(2)}%',
                    style: VistaType.subhead.copyWith(
                      fontWeight: FontWeight.w700,
                      color: pct >= 0 ? VistaColors.long : VistaColors.short,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card's replay: the Home chart's painter at card size, with the
/// entry marker, the "Called …" tag above the call line, and the live dot.
class _Chart extends StatelessWidget {
  const _Chart({required this.idea});

  final TradeIdea idea;

  static const Size _canvas = Size(360, 403);

  @override
  Widget build(BuildContext context) {
    final s = idea.script;
    return LayoutBuilder(
      builder: (context, c) {
        final sx = c.maxWidth / _canvas.width;
        final sy = c.maxHeight / _canvas.height;
        final baseY = s.entryY * sy;
        final end = Offset(s.path.last.dx * sx, s.path.last.dy * sy);
        final start = Offset(s.path.first.dx * sx, baseY);
        final below = end.dy > baseY;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _Baseline(baseY),
                foregroundPainter: ReplayLinePainter(
                  points: s.path,
                  entryY: s.entryY,
                  revealX: null,
                  latticeShift: 0,
                  sx: sx,
                  sy: sy,
                  screenLattice: true,
                ),
              ),
            ),
            Positioned(
              left: start.dx - 1,
              top: start.dy - 5,
              child: const VistaIcon(VistaAssets.markerEntry, size: 10),
            ),
            // Above the call line: its left end is where the chart is empty.
            Positioned(
              left: 12,
              top: math.max(0, baseY - 7 - 17),
              child: VistaTag(label: s.callTag, dense: true),
            ),
            Positioned(
              left: end.dx - 9,
              top: end.dy - 7,
              child: _LiveDot(
                color: below ? VistaColors.short : VistaColors.long,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The dashed call line (#858585, 2 on 3 off).
class _Baseline extends CustomPainter {
  const _Baseline(this.y);

  final double y;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = VistaColors.textMuted;
    for (var x = 0.0; x < size.width; x += 5) {
      canvas.drawRect(Rect.fromLTWH(x, y - 0.5, 2, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_Baseline old) => old.y != y;
}

/// The live dot with its halo, as on the Home chart.
class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 14,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    ),
  );
}
