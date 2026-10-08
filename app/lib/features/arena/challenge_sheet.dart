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

/// One ready-made challenge on the carousel: its wording, why the price
/// starts where it does, and the price (editable).
class _Option {
  _Option(this.kind, this.wording, this.note, double level)
    : price = TextEditingController(text: _digits(level));

  /// 0 closes, 1 touches, 2 stays, 3 ends (see [statement]).
  final int kind;
  final String wording;
  final String note;
  final TextEditingController price;

  double? get level =>
      double.tryParse(price.text.replaceAll(RegExp('[^0-9.]'), ''));

  String statement(String ticker) {
    final l = level;
    final at = l == null ? r'$…' : MarketPrices.format(l, compact: true);
    final verb = wording.toLowerCase();
    return switch (kind) {
      2 => '$ticker $verb $at for 24 hours',
      3 => '$ticker $verb than $at in 24 hours',
      _ => '$ticker $verb $at in 24 hours',
    };
  }
}

String _digits(double v) => groupDigits(v.roundToDouble(), 0);

/// The Challenge sheet (Figma 578:273): who you're challenging and the side
/// you take, when it ends, then ready-made challenges to swipe through
/// (each a full sentence with its own price field), your position on that
/// side, then Next. The card in view is the one posted. Returns the debate.
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
  late final List<_Option> _options = _optionsFor();
  final _pages = PageController(viewportFraction: 0.89);
  int _page = 0;

  String get _ticker => widget.take.ticker;
  _Option get _picked => _options[_page];

  /// Four challenges your way: past their stop, a stretch move, never
  /// reaching their target, and simply from here.
  List<_Option> _optionsFor() {
    final long = widget.position.side == TradeSide.long;
    final now = MarketPrices.of(_ticker).value;
    final c = widget.take.call;
    final entry = c == null ? null : MarketPrices.base(_ticker) * c.entryRatio;
    final dir = long ? 1 : -1;
    return [
      _Option(
        0,
        long ? 'Closes above' : 'Closes below',
        entry == null ? '${dir > 0 ? '+' : '−'}1%' : 'their stop',
        entry == null ? now * (1 + dir * 0.01) : entry * c!.stopLoss,
      ),
      _Option(1, 'Touches', '${dir > 0 ? '+' : '−'}5%', now * (1 + dir * 0.05)),
      _Option(
        2,
        long ? 'Stays above' : 'Stays below',
        entry == null ? '${dir > 0 ? '−' : '+'}2%' : 'their target, never hit',
        entry == null ? now * (1 - dir * 0.02) : entry * c!.takeProfit,
      ),
      _Option(3, long ? 'Ends higher' : 'Ends lower', 'from now', now),
    ];
  }

  @override
  void initState() {
    super.initState();
    for (final o in _options) {
      o.price.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    for (final o in _options) {
      o.price.dispose();
    }
    super.dispose();
  }

  void _next() {
    HapticFeedback.lightImpact();
    final m = MarketsMock.assets.where((a) => a.id == _ticker).firstOrNull;
    final change = m == null
        ? ''
        : '${m.changePct >= 0 ? '+' : '−'}${m.changePct.abs()}%';
    final statement = _picked.statement(_ticker);
    Navigator.of(context).pop(
      LiveBattle(
        ticker: _ticker,
        change: change,
        question: statement,
        chip: statement,
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
    const side = VistaSpace.gutter + VistaSpace.xs;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            0,
            VistaSpace.lg,
            0,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: side),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                  ],
                ),
              ),
              const SizedBox(height: VistaSpace.xxl),
              // Ready-made challenges, the next one peeking in.
              SizedBox(
                height: 196,
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _options.length,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _page = i);
                  },
                  // Centred, so every card lines up and its neighbours peek.
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VistaSpace.sm,
                    ),
                    child: _ChallengeCard(
                      key: ValueKey('challenge-card-$i'),
                      option: _options[i],
                      ticker: _ticker,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: VistaSpace.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _options.length; i++)
                    AnimatedContainer(
                      duration: VistaMotion.state,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? VistaColors.accent
                            : VistaColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(VistaRadius.pill),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: VistaSpace.xxl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: side),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'YOUR SIDE   ${p.side.label.toUpperCase()} $_ticker',
                      style: label,
                    ),
                    const SizedBox(height: VistaSpace.xxl),
                    // Your position on that side.
                    BackedPositionCard(
                      post: ComposeTakeScreen.backing(p),
                      ticker: _ticker,
                    ),
                    const SizedBox(height: VistaSpace.xxl),
                    VistaPillButton(
                      label: 'Next: make your case',
                      variant: VistaPillVariant.accent,
                      foreground: VistaColors.onAccent,
                      onPressed: _picked.level == null ? null : _next,
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
}

/// A ready-made challenge: the wording and where its price came from, the
/// whole sentence, and its price field.
class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({super.key, required this.option, required this.ticker});

  final _Option option;
  final String ticker;

  @override
  Widget build(BuildContext context) {
    final label = VistaType.labelStrong.copyWith(color: VistaColors.textMuted);
    return Container(
      padding: const EdgeInsets.all(VistaSpace.gutter),
      decoration: BoxDecoration(
        color: VistaColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(option.wording.toUpperCase(), style: label)),
              Text(option.note, style: label),
            ],
          ),
          const SizedBox(height: VistaSpace.lg),
          Text(
            option.statement(ticker),
            style: VistaType.title.copyWith(fontSize: 20),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          _PriceField(controller: option.price, ticker: ticker),
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
