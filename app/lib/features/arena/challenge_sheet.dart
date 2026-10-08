import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../charting/price_scale.dart';
import '../../design_system/design_system.dart';
import '../calls/calls_store.dart';
import '../live/market_prices.dart';
import '../markets/markets_mock.dart';
import '../portfolio/portfolio_mock.dart';
import '../portfolio/positions_state.dart';
import '../trade/order_ticket.dart';
import 'arena_mock.dart';
import 'compose_take_screen.dart';
import 'take_card.dart';

/// Challenge [take]: take the other side of someone's call. With no open
/// position on that side of the market, the order ticket opens on it;
/// with one, the Challenge sheet (Figma 578:273) sets the debate, then the
/// composer makes the case. Posting starts the debate at 1 vs 1 and puts
/// their call on it. Simulated.
Future<void> startChallenge(BuildContext context, Take take) async {
  final side = take.side == TradeSide.long ? TradeSide.short : TradeSide.long;
  final mine = PositionsState.open.value
      .where((p) => p.detail.symbol == take.ticker && p.side == side)
      .firstOrNull;
  if (mine == null) {
    return showOrderTicket(context, symbol: take.ticker, side: side);
  }
  final navigator = Navigator.of(context);
  final debate = await showVistaSheet<LiveBattle>(
    context,
    color: VistaColors.background,
    builder: (_) => ChallengeSheet(take: take, position: mine),
  );
  if (debate == null) return;
  final post = await navigator.push(
    ComposeTakeScreen.route(mine, debate: debate),
  );
  if (post == null) return;
  CallsStore.add(post);
  // Posted without the debate (Remove in the composer): no debate starts.
  if (post.battle != debate.label) return;
  // Live at 1 vs 1: their call and yours.
  BattlesStore.add(
    LiveBattle(
      ticker: debate.ticker,
      change: debate.change,
      question: debate.question,
      chip: debate.chip,
      longShare: 0.5,
      minutesLeft: debate.minutesLeft,
      takes: 2,
    ),
  );
  CallsStore.putOnDebate(take, debate.label);
}

/// The Challenge sheet (Figma 578:273): who you're challenging and the side
/// you take, when it ends, the debate (its sentence, the wording on a
/// sideways strip, the price as its own field with shortcuts on another
/// strip), your position on that side, then Next. Returns the debate.
class ChallengeSheet extends StatefulWidget {
  const ChallengeSheet({super.key, required this.take, required this.position});

  final Take take;

  /// Your open position on the other side of [take]'s market.
  final PortfolioPosition position;

  /// Every challenge settles a day after it starts.
  static const minutes = 24 * 60;

  @override
  State<ChallengeSheet> createState() => _ChallengeSheetState();
}

class _ChallengeSheetState extends State<ChallengeSheet> {
  int _wording = 0;
  late final List<(String, double)> _prices = _priceOptions();
  late final _price = TextEditingController(text: _digits(_prices.first.$2));

  bool get _long => widget.position.side == TradeSide.long;
  String get _ticker => widget.take.ticker;

  /// The long side argues up, the short side down.
  List<String> get _wordings => _long
      ? const ['Closes above', 'Touches', 'Stays above', 'Ends higher']
      : const ['Closes below', 'Touches', 'Stays below', 'Ends lower'];

  /// Their stop first (where their call is wrong), then now, steps your
  /// way, and their target.
  List<(String, double)> _priceOptions() {
    final now = MarketPrices.of(_ticker).value;
    final c = widget.take.call;
    final entry = c == null ? null : MarketPrices.base(_ticker) * c.entryRatio;
    final dir = _long ? 1 : -1;
    String fmt(double v) => MarketPrices.format(v, compact: true);
    return [
      if (entry != null)
        ('Their stop ${fmt(entry * c!.stopLoss)}', entry * c.stopLoss),
      ('Now ${fmt(now)}', now),
      for (final pct in [2, 5])
        (
          '${dir > 0 ? '+' : '−'}$pct% ${fmt(now * (1 + dir * pct / 100))}',
          now * (1 + dir * pct / 100),
        ),
      if (entry != null)
        ('Their TP ${fmt(entry * c!.takeProfit)}', entry * c.takeProfit),
    ];
  }

  static String _digits(double v) => groupDigits(v.roundToDouble(), 0);

  double? get _level =>
      double.tryParse(_price.text.replaceAll(RegExp('[^0-9.]'), ''));

  String get _statement {
    final level = _level == null
        ? r'$…'
        : MarketPrices.format(_level!, compact: true);
    final verb = _wordings[_wording].toLowerCase();
    return switch (_wording) {
      2 => '$_ticker $verb $level for 24 hours',
      3 => '$_ticker $verb than $level in 24 hours',
      _ => '$_ticker $verb $level in 24 hours',
    };
  }

  @override
  void initState() {
    super.initState();
    _price.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.lightImpact();
    final m = MarketsMock.assets.where((a) => a.id == _ticker).firstOrNull;
    final change = m == null
        ? ''
        : '${m.changePct >= 0 ? '+' : '−'}${m.changePct.abs()}%';
    Navigator.of(context).pop(
      LiveBattle(
        ticker: _ticker,
        change: change,
        question: _statement,
        chip: _statement,
        // Only their call so far; yours joins when you post.
        longShare: widget.take.side == TradeSide.long ? 1 : 0,
        minutesLeft: ChallengeSheet.minutes,
        takes: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.take;
    final p = widget.position;
    final muted = VistaType.subheadMuted.copyWith(
      fontWeight: FontWeight.w500,
      color: VistaColors.textMuted,
    );
    final label = VistaType.labelStrong.copyWith(color: VistaColors.textMuted);
    final selectedPrice = _prices.indexWhere(
      (o) => _level != null && _digits(o.$2) == _digits(_level!),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VistaSpace.gutter + VistaSpace.xs,
            VistaSpace.lg,
            VistaSpace.gutter + VistaSpace.xs,
            VistaSpace.gutter,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VistaColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(VistaRadius.hairline),
                  ),
                ),
              ),
              const SizedBox(height: VistaSpace.xxl),
              Text('Challenge ${t.handle}', style: VistaType.title),
              const SizedBox(height: VistaSpace.xs),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: "They're "),
                    TextSpan(
                      text: '${t.side.label.toLowerCase()} $_ticker',
                      style: TextStyle(color: t.side.color),
                    ),
                    const TextSpan(text: '. You take the '),
                    TextSpan(
                      text: p.side.label.toLowerCase(),
                      style: TextStyle(color: p.side.color),
                    ),
                    const TextSpan(text: ' side.'),
                  ],
                ),
                style: muted,
              ),
              const SizedBox(height: VistaSpace.xxl),
              Row(
                children: [
                  Expanded(child: Text('ENDS', style: label)),
                  Text('24 hours', style: label),
                ],
              ),
              const SizedBox(height: VistaSpace.xxl),
              // The debate: sentence, wording, price, price shortcuts.
              Container(
                padding: const EdgeInsets.only(
                  left: VistaSpace.gutter,
                  top: VistaSpace.xxl,
                  bottom: VistaSpace.xxl,
                ),
                decoration: BoxDecoration(
                  color: VistaColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: VistaSpace.gutter),
                      child: Text(
                        _statement,
                        style: VistaType.title.copyWith(fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: VistaSpace.xl),
                    _Strip(
                      labels: _wordings,
                      selected: _wording,
                      onPick: (i) => setState(() => _wording = i),
                    ),
                    const SizedBox(height: VistaSpace.xl),
                    Padding(
                      padding: const EdgeInsets.only(right: VistaSpace.gutter),
                      child: _PriceField(controller: _price, ticker: _ticker),
                    ),
                    const SizedBox(height: VistaSpace.xl),
                    _Strip(
                      labels: [for (final o in _prices) o.$1],
                      selected: selectedPrice,
                      onPick: (i) {
                        _price.text = _digits(_prices[i].$2);
                        _price.selection = TextSelection.collapsed(
                          offset: _price.text.length,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VistaSpace.xxl),
              Text(
                'YOUR SIDE · ${p.side.label.toUpperCase()} $_ticker',
                style: label,
              ),
              const SizedBox(height: VistaSpace.xxl),
              // Your position on that side, picked.
              Container(
                padding: const EdgeInsets.only(right: VistaSpace.xxl),
                decoration: BoxDecoration(
                  color: VistaColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: VistaColors.accent, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    Expanded(
                      child: BackedPositionCard(
                        post: ComposeTakeScreen.backing(p),
                        ticker: _ticker,
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: VistaColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VistaSpace.xxl),
              VistaPillButton(
                label: 'Next: make your case',
                variant: VistaPillVariant.accent,
                foreground: VistaColors.onAccent,
                onPressed: _level == null ? null : _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of choice pills that scrolls sideways, running to the card's
/// edge; the picked one is filled.
class _Strip extends StatelessWidget {
  const _Strip({
    required this.labels,
    required this.selected,
    required this.onPick,
  });

  final List<String> labels;

  /// -1 when none matches.
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: VistaSpace.gutter),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: VistaSpace.md),
            VistaFilterChip(
              label: labels[i],
              accent: true,
              selected: i == selected,
              onPressed: () => onPick(i),
            ),
          ],
        ],
      ),
    );
  }
}

/// The price as its own field: "$", the number, and the live price.
class _PriceField extends StatelessWidget {
  const _PriceField({required this.controller, required this.ticker});

  final TextEditingController controller;
  final String ticker;

  @override
  Widget build(BuildContext context) {
    final big = VistaType.title.copyWith(fontSize: 22);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
      decoration: BoxDecoration(
        color: VistaColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VistaColors.accent, width: 1.5),
      ),
      child: Row(
        children: [
          Text(r'$', style: big.copyWith(color: VistaColors.textMuted)),
          const SizedBox(width: VistaSpace.sm),
          Expanded(
            child: Semantics(
              label: 'Price',
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
                ],
                style: VistaType.figures(big),
                cursorColor: VistaColors.accent,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: VistaSpace.xxl,
                  ),
                ),
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: MarketPrices.of(ticker),
            builder: (context, now, _) => Text(
              '$ticker ${MarketPrices.format(now, compact: true)} now',
              style: VistaType.meta.copyWith(color: VistaColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
