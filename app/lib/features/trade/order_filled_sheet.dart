import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../arena/compose_take_screen.dart';
import '../calls/calls_store.dart';
import '../live/live_feed.dart';
import '../live/market_prices.dart';
import '../portfolio/portfolio_mock.dart';

/// After a market order fills: the burst (Figma 1372:9189) at the top, what
/// filled, the numbers that matter in the position sheet's rows, then Done
/// or Post a call (the position is there, so a call can stand on it).
/// Simulated; nothing is sent.
Future<void> showOrderFilled(
  BuildContext context, {
  required PortfolioPosition position,
  required double paid,
  required double liquidation,
}) {
  HapticFeedback.mediumImpact();
  return showVistaSheet<void>(
    context,
    color: VistaColors.background,
    builder: (_) => OrderFilledSheet(
      position: position,
      paid: paid,
      liquidation: liquidation,
    ),
  );
}

class OrderFilledSheet extends StatelessWidget {
  const OrderFilledSheet({
    super.key,
    required this.position,
    required this.paid,
    required this.liquidation,
  });

  final PortfolioPosition position;

  /// The margin put in.
  final double paid;
  final double liquidation;

  @override
  Widget build(BuildContext context) {
    final p = position;
    final d = p.detail;
    final long = p.side == TradeSide.long;
    String price(double v) => MarketPrices.format(v);
    final notional = paid * p.leverage;
    double pnlAt(double exit) =>
        notional * (exit - d.entry) / d.entry * (long ? 1 : -1);
    String money(double v) =>
        '${v >= 0 ? '+' : '−'}${formatUsd(v.abs(), decimals: 2)}';
    final label = VistaType.body.copyWith(color: VistaColors.textMuted);
    final value = VistaType.figures(VistaType.subheadMuted)
        .copyWith(fontWeight: FontWeight.w400, color: VistaColors.textPrimary);
    final aside = VistaType.figures(VistaType.bodyRegular)
        .copyWith(color: VistaColors.textMuted);

    Widget row(String name, String v, {Color? nameColor, String? note}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: VistaSpace.lg),
          child: Row(
            children: [
              Expanded(
                child: Text(name, style: label.copyWith(color: nameColor)),
              ),
              Text(v, style: value),
              if (note != null) ...[
                const SizedBox(width: VistaSpace.md),
                Text(note, style: aside),
              ],
            ],
          ),
        );
    const line = Divider(height: 1, thickness: 1, color: VistaColors.hairline);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final navigator = Navigator.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        VistaSpace.gutter,
        // Room above the burst so its sparkles don't crowd the sheet's edge.
        VistaSpace.section + VistaSpace.gutter,
        VistaSpace.gutter,
        bottom > 0 ? bottom : VistaSpace.gutter,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: FillBurst(width: 200)),
          const SizedBox(height: VistaSpace.md),
          Text(
            'Order filled',
            textAlign: TextAlign.center,
            style: VistaType.displaySmall,
          ),
          const SizedBox(height: VistaSpace.xs),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      '${p.side.label.toUpperCase()} ${d.symbol} '
                      '${p.leverage}x',
                  style: TextStyle(color: p.side.color),
                ),
                const TextSpan(
                  text: ' · market order',
                  style: TextStyle(color: VistaColors.textMuted),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: VistaType.subhead,
          ),
          const SizedBox(height: VistaSpace.md),
          row('Filled at', price(d.entry)),
          line,
          row(
            'You paid',
            formatUsd(paid, decimals: 2),
            note: '→ ${formatUsd(notional)} position',
          ),
          line,
          row(
            'Take profit',
            price(d.takeProfit),
            nameColor: VistaColors.long,
            note: money(pnlAt(d.takeProfit)),
          ),
          line,
          row(
            'Stop loss',
            price(d.stopLoss),
            nameColor: VistaColors.short,
            note: money(pnlAt(d.stopLoss)),
          ),
          line,
          row('Liquidation', price(liquidation)),
          const SizedBox(height: VistaSpace.lg),
          Row(
            children: [
              Expanded(
                child: VistaPillButton(
                  label: 'Done',
                  onPressed: () => navigator.pop(),
                ),
              ),
              const SizedBox(width: VistaSpace.md),
              Expanded(
                child: VistaPillButton(
                  label: 'Post a call',
                  variant: VistaPillVariant.accent,
                  foreground: VistaColors.onAccent,
                  onPressed: () async {
                    navigator.pop();
                    final take = await navigator.push(
                      ComposeTakeScreen.route(p),
                    );
                    if (take != null) CallsStore.add(take);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: VistaSpace.md),
          Text(
            'Simulated · nothing was sent',
            textAlign: TextAlign.center,
            style: VistaType.caption.copyWith(color: VistaColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// One layer of the burst: its Figma box (in the 271.73 × 207.22 frame) and
/// how it grows in.
class _Layer {
  const _Layer(this.asset, this.x, this.y, this.w, this.h, this.scale);

  final int asset;
  final double x, y, w, h;
  final double Function(double ms) scale;
}

/// The order-filled burst (Figma 1372:9189): background blobs grow in, the
/// green disc pops, the tick draws, then sparkles pop around it. Plays once
/// (1.49s) and holds; the Figma loop's fade-out is left off.
class FillBurst extends StatefulWidget {
  const FillBurst({super.key, required this.width});

  final double width;

  static const frameW = 271.7308;
  static const frameH = 207.2223;

  /// Where the Figma timeline starts fading out to loop.
  static const holdMs = 1490.0;

  @override
  State<FillBurst> createState() => _FillBurstState();
}

class _FillBurstState extends State<FillBurst>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: FillBurst.holdMs.round()),
  );

  static const _out = Cubic(0.22, 1, 0.36, 1);
  static const _pop = Cubic(0.34, 1.56, 0.64, 1);
  static const _total = 1950.0;

  /// 0 → 1 between [a] and [b] (percent of the 1.95s timeline).
  static double Function(double) _grow(double a, double b) => (ms) {
    final t = ((ms / _total * 100) - a) / (b - a);
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    return _out.transform(t);
  };

  /// 0 → [peak] → 1, as Figma's pops.
  static double Function(double) _popIn(
    double a,
    double peakAt,
    double end, {
    double peak = 1.2,
  }) => (ms) {
    final pct = ms / _total * 100;
    if (pct <= a) return 0;
    if (pct <= peakAt) return peak * _pop.transform((pct - a) / (peakAt - a));
    if (pct <= end) {
      final t = _pop.transform((pct - peakAt) / (end - peakAt));
      return peak + (1 - peak) * t;
    }
    return 1;
  };

  static double Function(double) _sparkle(double a) =>
      _popIn(a, a + 10.462, a + 15.384);

  static final _layers = [
    _Layer(0, 33.847, 0, 207.222, 207.222, _grow(0, 23.59)),
    _Layer(1, 13.124, 69.074, 138.148, 138.148, _grow(3.59, 27.179)),
    _Layer(2, 137.457, 6.908, 96.704, 96.704, _grow(6.154, 29.744)),
    _Layer(3, 233.050, 147.111, 38.681, 38.681, _grow(9.744, 33.333)),
    _Layer(
      4,
      61.472,
      31.079,
      138.156,
      138.157,
      _popIn(9.744, 23.097, 31.282, peak: 1.09),
    ),
    _Layer(6, 17.268, 24.867, 33.157, 33.156, _sparkle(31.795)),
    _Layer(7, 202.387, 2.764, 22.104, 22.104, _sparkle(33.846)),
    _Layer(8, 26.939, 158.871, 27.629, 27.629, _sparkle(35.385)),
    _Layer(9, 244.050, 61.111, 15.196, 15.196, _sparkle(36.923)),
    _Layer(10, 0, 83.580, 12.433, 12.433, _sparkle(38.462)),
    _Layer(11, 246.594, 34.537, 16.578, 16.578, _sparkle(40)),
    _Layer(12, 13.814, 62.168, 12.433, 12.433, _sparkle(41.538)),
    _Layer(13, 189.953, 169.923, 5.526, 5.526, _sparkle(43.077)),
    _Layer(14, 70.110, 6.908, 10.361, 10.361, _sparkle(44.615)),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Reduced motion: show where it ends.
      if (MediaQuery.disableAnimationsOf(context)) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.width / FillBurst.frameW;
    return Semantics(
      label: 'Order filled',
      image: true,
      child: SizedBox(
        width: widget.width,
        height: FillBurst.frameH * k,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final ms = _c.value * FillBurst.holdMs;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final l in _layers)
                  Positioned(
                    left: l.x * k,
                    top: l.y * k,
                    width: l.w * k,
                    height: l.h * k,
                    child: Transform.scale(
                      scale: l.scale(ms),
                      child: VistaIcon(
                        'assets/figma/fill_burst_${l.asset}.svg',
                        size: l.w * k,
                        height: l.h * k,
                      ),
                    ),
                  ),
                // The tick draws itself (Figma's path trim, 22%–39.5%).
                Positioned(
                  left: 86.645 * k,
                  top: 66.745 * k,
                  width: 97.1007 * k,
                  height: 69.5341 * k,
                  child: CustomPaint(
                    painter: _Tick(_grow(22.051, 39.487)(ms), k),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The tick from the Figma vector, drawn up to [progress].
class _Tick extends CustomPainter {
  const _Tick(this.progress, this.k);

  final double progress;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path = Path()
      ..moveTo(9.50065 * k, 30.4021 * k)
      ..lineTo(31.1766 * k, 60.0341 * k)
      ..lineTo(87.6007 * k, 9.50009 * k);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = VistaColors.textPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 19 * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_Tick old) => old.progress != progress || old.k != k;
}
