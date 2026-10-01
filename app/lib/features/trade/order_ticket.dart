import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../charting/charting.dart';
import '../../design_system/design_system.dart';
import '../live/live_feed.dart';
import '../live/market_prices.dart';
import '../markets/markets_mock.dart';
import '../portfolio/orders_state.dart';
import '../portfolio/portfolio_mock.dart';
import 'trade_mock.dart';

part 'feed_order_ticket.dart';

/// Opens the order ticket for [symbol] (an asset ticker or a trader
/// market's handle) on [side] as a sheet sliding up over the page (Figma
/// "Order · C — pro", 218:608). Simulated: placing a limit or stop order
/// adds it to Portfolio › Open orders; a market order just confirms.
/// Nothing is sent.
Future<void> showOrderTicket(
  BuildContext context, {
  required String symbol,
  required TradeSide side,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x73000000), // Figma scrim: black at 45%
    builder: (_) => OrderTicket(symbol: symbol, side: side),
  );
}

enum OrderKind { market, limit, stop }

/// The market facts a ticket needs: its name, icon, leverage cap and what
/// its size is counted in.
class _Market {
  const _Market(this.name, this.icon, this.maxLeverage, this.unit);

  final String name;
  final String icon;
  final int maxLeverage;
  final String unit;

  static _Market of(String symbol) {
    final quote = TradeMock.quotes[symbol];
    if (quote != null) {
      final row = MarketsMock.assets.where((m) => m.id == symbol);
      return _Market(
        quote.name,
        row.isEmpty ? VistaAssets.coinPlaceholder : row.first.rowIcon,
        int.tryParse(quote.leverage.replaceAll('x', '')) ?? 10,
        symbol,
      );
    }
    // A trader market: units of the trader's market, up to 5x.
    return _Market(symbol, VistaAssets.traderAvatarRow, 5, 'units');
  }
}

/// The ticket itself (the sheet's content).
class OrderTicket extends StatefulWidget {
  const OrderTicket({super.key, required this.symbol, required this.side});

  final String symbol;
  final TradeSide side;

  /// Margin the demo account can put on a new order.
  static const double available = 1000;

  @override
  State<OrderTicket> createState() => _OrderTicketState();
}

class _OrderTicketState extends State<OrderTicket> {
  late final _market = _Market.of(widget.symbol);
  late TradeSide _side = widget.side;
  // Opens as a plain market order; limit, stop and exits are opt-in.
  OrderKind _kind = OrderKind.market;
  late int _leverage = math.min(10, _market.maxLeverage);
  bool _exits = false;
  bool _reduceOnly = false;
  bool _sizeInUsd = false;

  late final _price = TextEditingController();
  late final _size = TextEditingController();
  late final _tp = TextEditingController();
  late final _sl = TextEditingController();

  /// Order size in the market's units.
  double _units = 0;

  double get _live => MarketPrices.now(widget.symbol);

  int get _priceDecimals => _live >= 1000
      ? 1
      : _live >= 1
      ? 2
      : 4;

  int get _unitDecimals => _live >= 1000
      ? 4
      : _live >= 10
      ? 2
      : _live >= 1
      ? 1
      : 0;

  double _parse(String text) =>
      double.tryParse(text.replaceAll(',', '').replaceAll(r'$', '')) ?? 0;

  /// The price the order is sized and judged at: its limit or trigger, or
  /// the live price for a market order.
  double get _entry =>
      _kind == OrderKind.market ? _live : math.max(0, _parse(_price.text));

  double get _notional => _units * _entry;
  double get _margin => _notional / _leverage;
  double get _maxNotional => OrderTicket.available * _leverage;
  double get _fraction =>
      _maxNotional == 0 ? 0 : (_notional / _maxNotional).clamp(0, 1);

  bool get _long => _side == TradeSide.long;

  @override
  void initState() {
    super.initState();
    _setPrice(_live);
    // A quarter of what the account can take, as in the design.
    _setUnits(_maxNotional * 0.25 / _live);
    _resetExits();
  }

  @override
  void dispose() {
    for (final c in [_price, _size, _tp, _sl]) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(double v, int decimals) => groupDigits(v, decimals);

  void _setPrice(double price) => _price.text = _fmt(price, _priceDecimals);

  void _setUnits(double units) {
    _units = math.max(0, units);
    _size.text = _sizeInUsd
        ? _fmt(_units * _entry, 0)
        : _fmt(_units, _unitDecimals);
  }

  /// Take profit +7% and stop loss −2.1% from entry, the design's defaults
  /// (flipped for a short).
  void _resetExits() {
    final e = _entry == 0 ? _live : _entry;
    _tp.text = _fmt(
      e * (_long ? 1.07 : 0.93),
      _priceDecimals > 1 ? _priceDecimals : 0,
    );
    _sl.text = _fmt(
      e * (_long ? 0.979 : 1.021),
      _priceDecimals > 1 ? _priceDecimals : 0,
    );
  }

  void _onSize(String text) {
    final v = _parse(text);
    setState(() => _units = _sizeInUsd ? (_entry == 0 ? 0 : v / _entry) : v);
  }

  void _onSlider(double fraction) {
    if (_entry <= 0) return;
    setState(() => _setUnits(_maxNotional * fraction / _entry));
  }

  void _switchSide(TradeSide side) {
    if (side == _side) return;
    HapticFeedback.selectionClick();
    setState(() {
      _side = side;
      _resetExits();
    });
  }

  String get _problem {
    if (_units <= 0) return 'Enter a size';
    if (_kind != OrderKind.market && _entry <= 0) return 'Enter a price';
    if (_margin > OrderTicket.available + 0.005) return 'Not enough margin';
    return '';
  }

  void _place() {
    if (_problem.isNotEmpty) return;
    HapticFeedback.mediumImpact();
    final kind = _kind.name;
    final side = _side.label.toLowerCase();
    final messenger = ScaffoldMessenger.of(context);
    if (_kind != OrderKind.market) {
      OrdersState.add(
        OpenOrder(
          id: 'o-${DateTime.now().microsecondsSinceEpoch}',
          asset: _market.name,
          symbol: widget.symbol,
          coinAsset: _market.icon,
          side: _side,
          leverage: _leverage,
          limitPrice: _entry,
          quantity: _units,
          filled: 0,
          decimals: _priceDecimals > 1 ? _priceDecimals : 0,
          quantityDecimals: _unitDecimals,
          takeProfit: _exits ? _parse(_tp.text) : null,
          stopLoss: _exits ? _parse(_sl.text) : null,
          reduceOnly: _reduceOnly,
        ),
      );
    }
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _kind == OrderKind.market
                ? 'Market $side filled (simulated)'
                : '${kind[0].toUpperCase()}${kind.substring(1)} $side placed · '
                      'in Open orders (simulated)',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        decoration: const BoxDecoration(
          color: VistaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 30 + safe),
            child: ValueListenableBuilder(
              valueListenable: MarketPrices.of(widget.symbol),
              builder: (context, _, _) => _content(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    const gap = SizedBox(height: 12);
    final side = _long ? VistaColors.long : VistaColors.short;
    final entry = _entry;
    double pct(String text) =>
        entry == 0 ? 0 : (_parse(text) - entry) / entry * 100;
    final liquidation = _liquidation(entry, _leverage);
    final taker = _kind != OrderKind.limit;
    final fee = _notional * (taker ? 0.0005 : 0.0002);
    final problem = _problem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0x40FFFFFF),
              borderRadius: BorderRadius.circular(VistaRadius.pill),
            ),
          ),
        ),
        gap,
        Row(
          children: [
            Expanded(child: _sideButton(TradeSide.long)),
            const SizedBox(width: 10),
            Expanded(child: _sideButton(TradeSide.short)),
          ],
        ),
        gap,
        Row(
          children: [
            // Scales down on narrow phones rather than crowding the pill.
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    for (final k in OrderKind.values) ...[
                      _typeTab(k),
                      const SizedBox(width: 18),
                    ],
                    _moreTab(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            _leveragePill(),
          ],
        ),
        gap,
        if (_kind != OrderKind.market) ...[
          _field(
            label: _kind == OrderKind.limit ? 'Limit price' : 'Trigger price',
            controller: _price,
            onChanged: (_) => setState(() {}),
            trailing: [
              _chip('Mid', () => setState(() => _setPrice(_live))),
              const SizedBox(width: 8),
              Text('USD', style: _unitStyle),
            ],
          ),
          gap,
        ],
        _field(
          label: _kind == OrderKind.market
              ? 'Size · at ${MarketPrices.format(_live)}'
              : 'Size',
          controller: _size,
          onChanged: _onSize,
          trailing: [
            Semantics(
              button: true,
              label: 'Switch size unit',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() {
                  _sizeInUsd = !_sizeInUsd;
                  _setUnits(_units);
                }),
                child: SizedBox(
                  height: 44,
                  child: Center(
                    // The font has no ⇄; an icon stands in.
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _sizeInUsd ? 'USD' : _market.unit,
                          style: _unitStyle,
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.swap_horiz_rounded,
                          size: 16,
                          color: VistaColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        gap,
        _TicketSlider(
          fraction: _fraction,
          onChanged: _onSlider,
          label: 'Size',
          value: '${(_fraction * 100).round()}% of available',
        ),
        gap,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _check(
              'Take profit / Stop loss',
              _exits,
              () => setState(() {
                _exits = !_exits;
                if (_exits) _resetExits();
              }),
            ),
            _check(
              'Reduce only',
              _reduceOnly,
              () => setState(() => _reduceOnly = !_reduceOnly),
            ),
          ],
        ),
        if (_exits) ...[
          gap,
          Row(
            children: [
              Expanded(child: _exitField('Take profit', _tp, pct(_tp.text))),
              const SizedBox(width: 10),
              Expanded(child: _exitField('Stop loss', _sl, pct(_sl.text))),
            ],
          ),
        ],
        gap,
        _summary(
          'Margin · Liquidation',
          '${formatUsd(_margin)} · ${MarketPrices.format(math.max(0, liquidation), compact: true)}',
        ),
        gap,
        _summary(
          'Fee (${taker ? 'taker 0.05%' : 'maker 0.02%'})',
          formatUsd(fee, decimals: 2),
        ),
        gap,
        Semantics(
          button: true,
          enabled: problem.isEmpty,
          child: GestureDetector(
            onTap: _place,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: problem.isEmpty ? side : VistaColors.surfaceRaised,
                borderRadius: BorderRadius.circular(VistaRadius.pill),
              ),
              child: Text(
                problem.isEmpty
                    ? 'Place ${_kind.name} ${_side.label.toLowerCase()}'
                    : problem,
                style: VistaType.headline.copyWith(
                  color: problem.isEmpty
                      ? VistaColors.onAccent
                      : VistaColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  TextStyle get _unitStyle =>
      VistaType.row.copyWith(color: VistaColors.textMuted);

  Widget _sideButton(TradeSide s) {
    final on = s == _side;
    return Semantics(
      button: true,
      selected: on,
      label: s.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _switchSide(s),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? s.color : VistaColors.surfaceRaised,
            borderRadius: BorderRadius.circular(VistaRadius.pill),
          ),
          child: Text(
            s.label,
            style: VistaType.headline.copyWith(
              color: on ? VistaColors.onAccent : VistaColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool on, VoidCallback onTap) {
    return Semantics(
      button: true,
      selected: on,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _tabLabel(label, on),
      ),
    );
  }

  /// A tab's text over its accent underline (shown when selected). The
  /// font has no ▾, so [chevron] draws one.
  Widget _tabLabel(String label, bool on, {bool chevron = false}) {
    return SizedBox(
      height: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: VistaType.subhead.copyWith(
                  color: on ? VistaColors.textPrimary : VistaColors.textMuted,
                ),
              ),
              if (chevron)
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: VistaColors.textMuted,
                ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: on ? 1 : 0,
            child: Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                color: VistaColors.accent,
                borderRadius: BorderRadius.circular(VistaRadius.pill),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeTab(OrderKind k) {
    final label = '${k.name[0].toUpperCase()}${k.name.substring(1)}';
    return _tab(label, k == _kind, () {
      if (k == _kind) return;
      setState(() {
        _kind = k;
        if (k != OrderKind.market && _parse(_price.text) <= 0) {
          _setPrice(_live);
        }
      });
    });
  }

  /// "More ▾": order types the backend has declared but not built yet.
  Widget _moreTab() {
    return PopupMenuButton<void>(
      tooltip: 'More order types',
      color: VistaColors.surfaceRaised,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            'Scale · coming soon',
            style: VistaType.body.copyWith(color: VistaColors.textMuted),
          ),
        ),
      ],
      child: Semantics(
        button: true,
        label: 'More order types',
        excludeSemantics: true,
        child: _tabLabel('More', false, chevron: true),
      ),
    );
  }

  /// "Cross · 10x": opens the leverage slider, up to the market's cap.
  Widget _leveragePill() {
    return Semantics(
      button: true,
      label: 'Leverage, ${_leverage}x',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final l = await showModalBottomSheet<int>(
            context: context,
            backgroundColor: Colors.transparent,
            barrierColor: const Color(0x73000000),
            builder: (_) => _LeverageSheet(
              initial: _leverage,
              max: _market.maxLeverage,
              liquidation: (l) => _liquidation(_entry, l),
            ),
          );
          if (l != null && mounted) setState(() => _leverage = l);
        },
        child: SizedBox(
          height: 44,
          child: Center(
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: VistaColors.surfaceRaised,
                borderRadius: BorderRadius.circular(VistaRadius.pill),
              ),
              child: Text('Cross · ${_leverage}x', style: VistaType.row),
            ),
          ),
        ),
      ),
    );
  }

  /// Rough liquidation price at [leverage]: entry less the margin, plus a
  /// half-percent maintenance buffer (flipped for a short).
  double _liquidation(double entry, int leverage) =>
      entry * (_long ? 1 - 1 / leverage + 0.005 : 1 + 1 / leverage - 0.005);

  Widget _chip(String label, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: VistaColors.surfaceRaised,
                borderRadius: BorderRadius.circular(VistaRadius.pill),
              ),
              child: Text(label, style: VistaType.row),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    ValueChanged<String> onChanged,
    TextStyle style,
  ) {
    return TextField(
      controller: c,
      onChanged: onChanged,
      style: style,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      cursorColor: VistaColors.accent,
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    List<Widget> trailing = const [],
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: VistaColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _fieldLabel, maxLines: 1),
                const SizedBox(height: 2),
                _input(controller, onChanged, VistaType.tab),
              ],
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }

  TextStyle get _fieldLabel => VistaType.chip.copyWith(
    fontWeight: FontWeight.w500,
    color: VistaColors.textSecondary,
  );

  Widget _exitField(String label, TextEditingController c, double pct) {
    final good = label == 'Take profit';
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: VistaColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _fieldLabel, maxLines: 1),
                const SizedBox(height: 2),
                _input(c, (_) => setState(() {}), VistaType.tab),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${pct >= 0 ? '+' : '−'}${pct.abs().toStringAsFixed(1)}%',
            style: VistaType.bodyStrong.copyWith(
              color: good ? VistaColors.long : VistaColors.short,
            ),
          ),
        ],
      ),
    );
  }

  Widget _check(String label, bool on, VoidCallback onTap) {
    return Semantics(
      checked: on,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: on ? VistaColors.accent : VistaColors.background,
                  borderRadius: BorderRadius.circular(5),
                  border: on
                      ? null
                      : Border.all(color: VistaColors.textMuted, width: 1.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(label, style: VistaType.row),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: VistaType.rowMedium.copyWith(color: VistaColors.textMuted),
          ),
        ),
        Text(value, style: VistaType.row),
      ],
    );
  }
}

/// A share from 0 to 1 (size of what the account can take, or leverage
/// across its range): a track with stops at quarters, filled to the thumb.
/// Drag or tap anywhere.
class _TicketSlider extends StatelessWidget {
  const _TicketSlider({
    required this.fraction,
    required this.onChanged,
    required this.label,
    required this.value,
    this.stops = const [0, 0.25, 0.5, 0.75, 1],
  });

  final double fraction;
  final ValueChanged<double> onChanged;
  final String label;
  final String value;

  /// Where the stop dots sit, as shares of the track.
  final List<double> stops;

  /// The thumb's radius; the track's ends are inset by it so the thumb,
  /// the stops and any labels under them line up.
  static const double inset = 12;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      label: label,
      value: value,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          void at(double dx) =>
              onChanged(((dx - inset) / (w - 2 * inset)).clamp(0.0, 1.0));
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => at(d.localPosition.dx),
            onHorizontalDragUpdate: (d) => at(d.localPosition.dx),
            child: SizedBox(
              height: 44,
              child: CustomPaint(painter: _SliderPainter(fraction, stops)),
            ),
          );
        },
      ),
    );
  }
}

class _SliderPainter extends CustomPainter {
  const _SliderPainter(this.fraction, this.stops);

  final double fraction;
  final List<double> stops;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final track = Paint()..color = VistaColors.surfaceRaised;
    final fill = Paint()..color = VistaColors.accent;
    const inset = _TicketSlider.inset;
    final x = inset + (size.width - 2 * inset) * fraction;
    canvas
      ..drawRRect(
        RRect.fromLTRBR(
          0,
          cy - 2,
          size.width,
          cy + 2,
          const Radius.circular(2),
        ),
        track,
      )
      ..drawRRect(
        RRect.fromLTRBR(0, cy - 2, x, cy + 2, const Radius.circular(2)),
        fill,
      );
    for (final f in stops) {
      final dx = inset + (size.width - 2 * inset) * f;
      canvas.drawCircle(Offset(dx, cy), 4, dx <= x ? fill : track);
    }
    canvas
      ..drawCircle(
        Offset(x, cy + 1),
        12,
        Paint()
          ..color = const Color(0x40000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      )
      ..drawCircle(Offset(x, cy), 12, Paint()..color = VistaColors.textPrimary);
  }

  @override
  bool shouldRepaint(_SliderPainter old) =>
      old.fraction != fraction || old.stops != stops;
}

/// Picks leverage with a horizontal slider from 1x to the market's cap,
/// with − / + for single steps and the liquidation price it implies.
class _LeverageSheet extends StatefulWidget {
  const _LeverageSheet({
    required this.initial,
    required this.max,
    required this.liquidation,
  });

  final int initial;
  final int max;
  final double Function(int leverage) liquidation;

  @override
  State<_LeverageSheet> createState() => _LeverageSheetState();
}

class _LeverageSheetState extends State<_LeverageSheet> {
  late int _l = widget.initial;

  double get _fraction => widget.max <= 1 ? 1 : (_l - 1) / (widget.max - 1);

  void _set(int l) {
    final next = l.clamp(1, widget.max);
    if (next == _l) return;
    HapticFeedback.selectionClick();
    setState(() => _l = next);
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;
    // Round stops: 1x, then every 10x on a 50x market, 5x on 20x, ...
    final max = widget.max;
    final step = max >= 40
        ? 10
        : max >= 20
        ? 5
        : max >= 10
        ? 2
        : 1;
    final marks = [
      1,
      for (var m = step; m < max; m += step)
        if (m > 1) m,
      max,
    ];
    double at(int m) => max <= 1 ? 1 : (m - 1) / (max - 1);
    return Container(
      decoration: const BoxDecoration(
        color: VistaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 24 + safe),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: VistaDragHandle()),
          const SizedBox(height: 12),
          Text('Leverage', style: VistaType.title),
          const SizedBox(height: 16),
          Row(
            children: [
              VistaStepButton(
                glyph: '−',
                semanticLabel: 'Lower leverage',
                onPressed: () => _set(_l - 1),
              ),
              Expanded(
                child: Text(
                  '${_l}x',
                  textAlign: TextAlign.center,
                  style: VistaType.display,
                ),
              ),
              VistaStepButton(
                glyph: '+',
                semanticLabel: 'Raise leverage',
                onPressed: () => _set(_l + 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _TicketSlider(
            fraction: _fraction,
            onChanged: (f) => _set(1 + (f * (widget.max - 1)).round()),
            label: 'Leverage',
            value: '${_l}x',
            stops: [for (final m in marks) at(m)],
          ),
          // Each label centred under its stop; tapping one jumps there.
          LayoutBuilder(
            builder: (context, c) {
              const inset = _TicketSlider.inset;
              final track = c.maxWidth - 2 * inset;
              return SizedBox(
                height: 44,
                child: Stack(
                  children: [
                    for (final m in marks)
                      Positioned(
                        left: inset + track * at(m) - 22,
                        width: 44,
                        top: 0,
                        bottom: 0,
                        child: Semantics(
                          button: true,
                          label: '${m}x',
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _set(m),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                '${m}x',
                                style: VistaType.meta.copyWith(
                                  color: m == _l
                                      ? VistaColors.textPrimary
                                      : VistaColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Est. liquidation',
                  style: VistaType.body.copyWith(
                    color: VistaColors.textSecondary,
                  ),
                ),
              ),
              Text(
                MarketPrices.format(widget.liquidation(_l)),
                style: VistaType.row,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Higher leverage moves liquidation closer to entry.',
            style: VistaType.meta.copyWith(color: VistaColors.textMuted),
          ),
          const SizedBox(height: 20),
          VistaPrimaryButton(
            label: 'Set ${_l}x',
            onPressed: () => Navigator.of(context).pop(_l),
          ),
        ],
      ),
    );
  }
}
