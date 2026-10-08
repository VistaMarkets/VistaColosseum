part of 'order_ticket.dart';

/// Opens the first-time order ticket a feed card's Long / Short opens
/// (Figma "sheet · first-time ticket", 472:1359): the card's side, Market or
/// Limit, three leverage choices plus custom, an amount in dollars, and
/// take profit / stop loss on one track anchored at entry. [onDetails] is the
/// card's own Details. Simulated: a market order just confirms; a limit
/// order goes to Portfolio › Open orders. Nothing is sent.
Future<void> showFeedOrderTicket(
  BuildContext context, {
  required String symbol,
  required TradeSide side,
  VoidCallback? onDetails,
}) {
  return showVistaSheet<void>(
    context,
    builder: (_) =>
        FeedOrderTicket(symbol: symbol, side: side, onDetails: onDetails),
  );
}

class FeedOrderTicket extends StatefulWidget {
  const FeedOrderTicket({
    super.key,
    required this.symbol,
    required this.side,
    this.onDetails,
  });

  final String symbol;
  final TradeSide side;
  final VoidCallback? onDetails;

  /// Leverage offered as buttons; anything else is "custom".
  static const presets = [2, 5, 10];

  /// The amount slider's stops, as shares of what's available: dragging or
  /// tapping snaps to the nearest one. Typing sets any amount.
  static const amountStops = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0];

  @override
  State<FeedOrderTicket> createState() => _FeedOrderTicketState();
}

class _FeedOrderTicketState extends State<FeedOrderTicket> {
  late final _market = _Market.of(widget.symbol);
  bool _limit = false;
  int _leverage = 2;
  // Opens on the first stop, 20% of what's available.
  double _margin = OrderTicket.available * 0.2;
  // Opens with take profit / stop loss on, as the design shows.
  bool _exits = true;
  double _slPct = 2.1;
  double _tpPct = 7.0;

  late final _amount = TextEditingController(text: _fmtUsd(_margin));
  late final _price = TextEditingController(
    text: groupDigits(_live, _priceDecimals),
  );

  bool get _long => widget.side == TradeSide.long;
  double get _live => MarketPrices.now(widget.symbol);
  int get _priceDecimals => MarketPrices.decimalsFor(_live);

  double get _entry {
    if (!_limit) return _live;
    return double.tryParse(_price.text.replaceAll(',', '')) ?? 0;
  }

  double get _notional => _margin * _leverage;

  /// Liquidation as a share of entry: the margin, less a half-percent
  /// maintenance buffer.
  double get _liqPct => (1 / _leverage - 0.005) * 100;

  /// The stop stays short of liquidation and inside the track.
  double get _slMax => math.min(_TpSlTrack.maxStop, _liqPct - 0.1);

  static String _fmtUsd(double v) =>
      groupDigits(v, v == v.roundToDouble() ? 0 : 2);

  String _signedUsd(double v) =>
      '${v < 0 ? '−' : '+'}\$${groupDigits(v.abs(), 2)}';

  String get _units {
    final u = _entry <= 0 ? 0.0 : _notional / _entry;
    final d = _entry >= 1000
        ? 4
        : _entry >= 10
        ? 2
        : 1;
    return '${groupDigits(u, d)} ${_market.unit}';
  }

  String? get _problem {
    if (_margin <= 0) return 'Enter an amount';
    if (_margin > OrderTicket.available) return 'Not enough balance';
    if (_limit && _entry <= 0) return 'Enter a limit price';
    return null;
  }

  void _setMargin(double m, {bool fromField = false}) {
    setState(() {
      _fault = null;
      _margin = math.max(0, m);
      if (!fromField) _amount.text = _fmtUsd(_margin);
    });
  }

  void _setLeverage(int l) => setState(() {
    _leverage = l;
    _slPct = math.min(_slPct, _slMax);
  });

  Future<void> _custom() async {
    final l = await showVistaSheet<int>(
      context,
      scrollControlled: false,
      builder: (_) => _LeverageSheet(
        initial: _leverage,
        max: _market.maxLeverage,
        liquidation: (l) =>
            _entry * (_long ? 1 - 1 / l + 0.005 : 1 + 1 / l - 0.005),
      ),
    );
    if (l != null && mounted) _setLeverage(l);
  }

  /// Bumped to shake the order button when the order can't go through.
  int _shakes = 0;

  /// The field a refused order points at ('price' or 'amount'), outlined in
  /// red until it's edited.
  String? _fault;

  /// Set once placed: the button reads "Placed ✓" before the sheet closes.
  bool _placed = false;

  void _place() {
    if (_placed) return;
    if (_problem != null) {
      HapticFeedback.heavyImpact();
      setState(() {
        _shakes++;
        _fault = _problem == 'Enter a limit price' ? 'price' : 'amount';
      });
      return;
    }
    HapticFeedback.mediumImpact();
    final side = widget.side.label.toLowerCase();
    final messenger = ScaffoldMessenger.of(context);
    PortfolioPosition? filled;
    if (!_limit) {
      // A market order fills at once: it opens a position in Portfolio.
      filled = PositionsState.fromFill(
        symbol: widget.symbol,
        name: _market.name,
        traderMarket: TradeMock.quotes[widget.symbol] == null,
        side: widget.side,
        leverage: _leverage,
        entry: _entry,
        notional: _notional,
        takeProfit: _exits ? _exitPrice(_tpPct, gain: true) : null,
        stopLoss: _exits ? _exitPrice(_slPct, gain: false) : null,
      );
      PositionsState.add(filled);
    } else {
      final units = _notional / _entry;
      OrdersState.add(
        OpenOrder(
          id: 'o-${DateTime.now().microsecondsSinceEpoch}',
          asset: _market.name,
          symbol: widget.symbol,
          coinAsset: _market.icon,
          side: widget.side,
          leverage: _leverage,
          limitPrice: _entry,
          quantity: units,
          filled: 0,
          decimals: _priceDecimals,
          quantityDecimals: _entry >= 1000 ? 4 : 2,
          takeProfit: _exits ? _exitPrice(_tpPct, gain: true) : null,
          stopLoss: _exits ? _exitPrice(_slPct, gain: false) : null,
          reduceOnly: false,
        ),
      );
    }
    // Confirm on the button itself, then close.
    setState(() => _placed = true);
    final navigator = Navigator.of(context);
    Future.delayed(VistaMotion.confirmHold, () {
      if (!mounted) return;
      final rootContext = navigator.context;
      navigator.pop();
      // A fill gets its own confirmation; a resting order a note.
      if (filled != null && rootContext.mounted) {
        showOrderFilled(
          rootContext,
          position: filled,
          paid: _margin,
          liquidation: _entry * (_long ? 1 - _liqPct / 100 : 1 + _liqPct / 100),
        );
        return;
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _limit
                  ? 'Limit $side placed   in Open orders (simulated)'
                  : 'Market $side filled   in Positions (simulated)',
            ),
          ),
        );
    });
  }

  /// The price [pct] away from entry on the winning ([gain]) or losing side.
  double _exitPrice(double pct, {required bool gain}) {
    final up = gain == _long;
    return _entry * (up ? 1 + pct / 100 : 1 - pct / 100);
  }

  @override
  void dispose() {
    _amount.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.paddingOf(context).bottom;
    const gap = SizedBox(height: 12);
    final muted12 = VistaType.chip.copyWith(
      fontWeight: FontWeight.w500,
      color: VistaColors.textMuted,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: VistaColors.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(VistaRadius.sheet),
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + safe),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: VistaDragHandle()),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _tab(
                      'Market',
                      !_limit,
                      () => setState(() => _limit = false),
                    ),
                    const SizedBox(width: 18),
                    _tab('Limit', _limit, () => setState(() => _limit = true)),
                  ],
                ),
                if (_limit) ...[
                  _field(
                    label: 'Limit price',
                    controller: _price,
                    fault: _fault == 'price',
                    onChanged: (_) => setState(() => _fault = null),
                  ),
                  gap,
                ],
                Row(
                  children: [
                    Text(
                      'Leverage',
                      style: muted12.copyWith(color: VistaColors.textSecondary),
                    ),
                    const Spacer(),
                    Text('Higher moves faster, both ways', style: muted12),
                  ],
                ),
                const SizedBox(height: 8),
                _leverageRow(),
                gap,
                _field(
                  label:
                      'Amount   you have '
                      '\$${_fmtUsd(OrderTicket.available)}',
                  controller: _amount,
                  prefix: r'$',
                  fault: _fault == 'amount',
                  onChanged: (t) => _setMargin(
                    double.tryParse(t.replaceAll(',', '')) ?? 0,
                    fromField: true,
                  ),
                ),
                gap,
                _TicketSlider(
                  fraction: (_margin / OrderTicket.available).clamp(0.0, 1.0),
                  onChanged: (f) {
                    final stop = FeedOrderTicket.amountStops.reduce(
                      (a, b) => (f - a).abs() <= (f - b).abs() ? a : b,
                    );
                    final m = OrderTicket.available * stop;
                    if (m == _margin) return;
                    HapticFeedback.selectionClick();
                    _setMargin(m);
                  },
                  stops: FeedOrderTicket.amountStops,
                  label: 'Amount',
                  value:
                      '${(_margin / OrderTicket.available * 100).round()}% '
                      'of available',
                ),
                gap,
                // What you pay versus what you control, spelled out.
                Text(
                  'You pay \$${_fmtUsd(_margin)} → '
                  '\$${_fmtUsd(_notional)} position (${_leverage}x)   '
                  '$_units',
                  style: muted12,
                ),
                gap,
                _exitsCheck(muted12),
                if (_exits) ...[
                  _TpSlTrack(
                    slPct: _slPct,
                    tpPct: _tpPct,
                    slMax: _slMax,
                    slPrice: MarketPrices.format(
                      _exitPrice(_slPct, gain: false),
                      compact: true,
                    ),
                    tpPrice: MarketPrices.format(
                      _exitPrice(_tpPct, gain: true),
                      compact: true,
                    ),
                    onStop: (v) => setState(() => _slPct = v),
                    onTarget: (v) => setState(() => _tpPct = v),
                  ),
                  gap,
                  _exitsSummary(),
                ],
                gap,
                _buttons(),
              ],
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
        child: SizedBox(
          height: 44,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: VistaType.subhead.copyWith(
                  color: on ? VistaColors.textPrimary : VistaColors.textMuted,
                ),
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
        ),
      ),
    );
  }

  /// 2x · 5x · 10x · custom (up to the market's cap); custom opens the
  /// leverage slider and stays picked for anything off the presets.
  Widget _leverageRow() {
    final presets = [
      for (final l in FeedOrderTicket.presets)
        if (l <= _market.maxLeverage) l,
    ];
    final custom = !presets.contains(_leverage);
    Widget chip(String label, bool on, VoidCallback onTap, String semantics) =>
        Expanded(
          child: Semantics(
            button: true,
            selected: on,
            label: semantics,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on
                      ? VistaColors.textPrimary
                      : VistaColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(VistaRadius.pill),
                ),
                child: Text(
                  label,
                  style: VistaType.subhead.copyWith(
                    fontWeight: FontWeight.w700,
                    color: on ? VistaColors.ink : VistaColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
    return Row(
      children: [
        for (final l in presets) ...[
          chip(
            '${l}x',
            l == _leverage,
            () => _setLeverage(l),
            '${l}x leverage',
          ),
          const SizedBox(width: 8),
        ],
        chip(
          'custom',
          custom,
          _custom,
          custom ? 'Custom leverage, ${_leverage}x' : 'Custom leverage',
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String? prefix,
    bool fault = false,
  }) {
    final value = VistaType.figures(VistaType.tab);
    return AnimatedContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      duration: VistaMotion.state,
      decoration: BoxDecoration(
        color: VistaColors.surface,
        borderRadius: BorderRadius.circular(14),
        // Red when a refused order points here; clear otherwise (same width
        // either way, so nothing shifts).
        border: Border.all(
          color: fault ? VistaColors.short : const Color(0x00000000),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: VistaType.chip.copyWith(
              fontWeight: FontWeight.w500,
              color: VistaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (prefix != null) Text(prefix, style: value),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  style: value,
                  // The decimal pad has no return key: tapping anywhere else closes it.
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  cursorColor: VistaColors.accent,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _exitsCheck(TextStyle hint) {
    return Semantics(
      checked: _exits,
      label: 'Take profit / Stop loss',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          _exits = !_exits;
          _slPct = math.min(_slPct, _slMax);
        }),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _exits ? VistaColors.accent : VistaColors.surface,
                  borderRadius: BorderRadius.circular(5),
                  border: _exits
                      ? null
                      : Border.all(
                          color: VistaColors.surfaceRaised,
                          width: 1.5,
                        ),
                ),
                child: _exits
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: VistaColors.onAccent,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text('Take profit / Stop loss', style: VistaType.row),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Close at a set gain or loss',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: hint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _exitsSummary() {
    final value = VistaType.figures(VistaType.body);
    final rr = _slPct <= 0 ? 0 : _tpPct / _slPct;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STOP LOSS',
              style: VistaType.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: VistaColors.short,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '−${_slPct.toStringAsFixed(1)}%   '
              '${_signedUsd(-_notional * _slPct / 100)}',
              style: value,
            ),
          ],
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Risk / reward   1 : ${rr.toStringAsFixed(1)}',
              style: VistaType.meta.copyWith(color: VistaColors.textMuted),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'TAKE PROFIT',
              style: VistaType.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: VistaColors.long,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '+${_tpPct.toStringAsFixed(1)}%   '
              '${_signedUsd(_notional * _tpPct / 100)}',
              style: value,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buttons() {
    final problem = _problem;
    final label = _placed
        ? 'Placed ✓'
        : problem ??
              '${widget.side.label} \$${_fmtUsd(_margin)}   ${_leverage}x';
    Widget button(String text, Color bg, Color fg, VoidCallback? onTap) =>
        Expanded(
          child: Semantics(
            button: true,
            label: text,
            excludeSemantics: true,
            child: VistaPressable(
              onTap: onTap,
              child: AnimatedContainer(
                duration: VistaMotion.state,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(VistaRadius.pill),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedSwitcher(
                    duration: VistaMotion.state,
                    child: Text(
                      text,
                      key: ValueKey(text == 'Placed ✓'),
                      style: VistaType.headline.copyWith(color: fg),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    return Row(
      children: [
        button(
          'Details',
          VistaColors.surfaceRaised,
          VistaColors.textPrimary,
          () {
            Navigator.of(context).pop();
            widget.onDetails?.call();
          },
        ),
        const SizedBox(width: 10),
        // Always tappable: an order that can't go through shakes instead.
        Expanded(
          child: VistaShake(
            count: _shakes,
            child: Row(
              children: [
                button(
                  label,
                  problem == null
                      ? widget.side.color
                      : VistaColors.surfaceRaised,
                  problem == null
                      ? VistaColors.onAccent
                      : VistaColors.textMuted,
                  _place,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Take profit and stop loss on one track (Figma 472:1411): entry fixed at
/// 38.5% of the width, red from the stop to entry, green from entry to the
/// target, each end a thumb you drag, with its price above it.
class _TpSlTrack extends StatelessWidget {
  const _TpSlTrack({
    required this.slPct,
    required this.tpPct,
    required this.slMax,
    required this.slPrice,
    required this.tpPrice,
    required this.onStop,
    required this.onTarget,
  });

  final double slPct;
  final double tpPct;
  final double slMax;
  final String slPrice;
  final String tpPrice;
  final ValueChanged<double> onStop;
  final ValueChanged<double> onTarget;

  static const double _entry = 0.385;

  /// Track width per percent from entry (25.7pt on the 370pt design).
  static const double _perPct = 25.7 / 370;
  static double get maxStop => _entry / _perPct;
  static double get maxTarget => (1 - _entry) / _perPct;

  static const double _thumb = 28;
  static const double _grab = 44;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final entry = w * _entry;
        final ppp = w * _perPct;
        final sl = entry - slPct * ppp;
        final tp = entry + tpPct * ppp;
        Widget bar(double left, double width, Color color) => Positioned(
          left: left,
          width: width,
          top: 34,
          height: 8,
          child: ColoredBox(color: color),
        );
        Widget price(double x, String text, Color color) => Positioned(
          left: (x - 30).clamp(0.0, w - 60),
          width: 60,
          top: 0,
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: VistaType.caption.copyWith(color: color),
          ),
        );
        Widget thumb(
          double x,
          Color color,
          String label,
          String value,
          ValueChanged<double> onDrag,
        ) => Positioned(
          left: x - _grab / 2,
          top: 38 - _grab / 2,
          width: _grab,
          height: _grab,
          child: Semantics(
            slider: true,
            label: label,
            value: value,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) => onDrag(d.delta.dx / ppp),
              child: Center(
                child: Container(
                  width: _thumb,
                  height: _thumb,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_Grip(), SizedBox(width: 3.6), _Grip()],
                  ),
                ),
              ),
            ),
          ),
        );
        return SizedBox(
          height: 60,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 34,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: VistaColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              bar(sl, entry - sl, VistaColors.short),
              bar(entry, tp - entry, VistaColors.long),
              Positioned(
                left: entry - 30,
                width: 60,
                top: 2,
                child: Text(
                  'ENTRY',
                  textAlign: TextAlign.center,
                  style: VistaType.micro.copyWith(
                    fontWeight: FontWeight.w700,
                    color: VistaColors.textPrimary,
                  ),
                ),
              ),
              Positioned(
                left: entry - 2,
                top: 26,
                width: 4,
                height: 24,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: VistaColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              price(sl, slPrice, VistaColors.short),
              price(tp, tpPrice, VistaColors.long),
              thumb(
                sl,
                VistaColors.short,
                'Stop loss',
                '${slPct.toStringAsFixed(1)} percent',
                (d) => onStop((slPct - d).clamp(0.1, slMax)),
              ),
              thumb(
                tp,
                VistaColors.long,
                'Take profit',
                '${tpPct.toStringAsFixed(1)} percent',
                (d) => onTarget((tpPct + d).clamp(0.1, maxTarget)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Grip extends StatelessWidget {
  const _Grip();

  @override
  Widget build(BuildContext context) => Container(
    width: 2.7,
    height: 11,
    decoration: BoxDecoration(
      color: VistaColors.ink,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
