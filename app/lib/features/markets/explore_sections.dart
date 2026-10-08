import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../arena/arena_mock.dart';
import '../calls/calls_store.dart';
import '../live/market_prices.dart';
import 'market_chart_card.dart';
import 'markets_mock.dart';

/// The Assets tab's sideways sections, between Favorites and the full
/// list: Moving now, Most called, Most battles and Rising traders. Each is
/// a row of slim cards with a line saying why the market is there.
class ExploreSections extends StatelessWidget {
  const ExploreSections({
    super.key,
    required this.onAsset,
    required this.onTrader,
  });

  final ValueChanged<MarketItem> onAsset;
  final ValueChanged<MarketItem> onTrader;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: CallsStore.all,
      builder: (context, calls, _) => ValueListenableBuilder(
        valueListenable: BattlesStore.all,
        builder: (context, battles, _) {
          final assets = MarketsMock.assets;
          int callsOn(MarketItem m) =>
              calls.where((t) => t.ticker == m.id).length;
          final live = [
            for (final b in battles)
              if (!b.settled) b,
          ];
          List<LiveBattle> battlesOn(MarketItem m) =>
              live.where((b) => b.ticker == m.id).toList();

          final moving = [...assets]
            ..sort((a, b) => b.changePct.abs().compareTo(a.changePct.abs()));
          final called = [
            for (final m in assets)
              if (callsOn(m) > 0) m,
          ]..sort((a, b) => callsOn(b).compareTo(callsOn(a)));
          final fought = [
            for (final m in assets)
              if (battlesOn(m).isNotEmpty) m,
          ]..sort((a, b) => battlesOn(b).length.compareTo(battlesOn(a).length));
          int gained(MarketItem m) =>
              MarketsMock.traderCards[m.id]?.newHolders ?? 0;
          final rising = [...MarketsMock.traders]
            ..sort((a, b) => gained(b).compareTo(gained(a)));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Section(
                title: 'Moving now',
                cards: [
                  for (final m in moving)
                    SlimMarketCard(
                      market: m,
                      note: '24h move',
                      onTap: () => onAsset(m),
                    ),
                ],
              ),
              if (called.isNotEmpty)
                _Section(
                  title: 'Most called',
                  cards: [
                    for (final m in called)
                      SlimMarketCard(
                        market: m,
                        note: '${callsOn(m)} call${callsOn(m) == 1 ? '' : 's'}',
                        onTap: () => onAsset(m),
                      ),
                  ],
                ),
              if (fought.isNotEmpty)
                _Section(
                  title: 'Most battles',
                  cards: [
                    for (final m in fought)
                      SlimMarketCard(
                        market: m,
                        note: _battleNote(battlesOn(m)),
                        noteColor: VistaColors.short,
                        onTap: () => onAsset(m),
                      ),
                  ],
                ),
              _Section(
                title: 'Rising traders',
                cards: [
                  for (final m in rising.take(6))
                    SlimMarketCard(
                      market: m,
                      trader: true,
                      note: '+${gained(m)} holders',
                      noteColor: VistaColors.long,
                      onTap: () => onTrader(m),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// "2 live battles", or the one closing soonest: "1 battle   4h left".
  static String _battleNote(List<LiveBattle> on) {
    if (on.length > 1) return '${on.length} live battles';
    return '1 battle   ${on.first.timeLeft}';
  }
}

/// A section title and its sideways row of cards.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.cards});

  final String title;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VistaSpace.gutter,
            VistaSpace.section,
            VistaSpace.gutter,
            VistaSpace.lg,
          ),
          child: Text(title, style: VistaType.tab),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, c) in cards.indexed) ...[
                if (i > 0) const SizedBox(width: VistaSpace.lg),
                c,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A slim market card for Explore's sections: icon and ticker, live price
/// and change, a small line chart, and one line on why it's here.
class SlimMarketCard extends StatelessWidget {
  const SlimMarketCard({
    super.key,
    required this.market,
    required this.note,
    required this.onTap,
    this.noteColor,
    this.trader = false,
  });

  final MarketItem market;
  final String note;
  final Color? noteColor;
  final VoidCallback onTap;

  /// A trader market: their initial, and the ticker over the handle.
  final bool trader;

  static const width = 156.0;

  @override
  Widget build(BuildContext context) {
    final m = market;
    final card = MarketsMock.traderCards[m.id];
    final title = trader ? card?.symbol ?? m.name : m.name;
    final Widget icon = trader
        ? Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color(
                card?.avatar ?? VistaColors.surfaceRaised.toARGB32(),
              ),
              shape: BoxShape.circle,
            ),
            child: Text(m.name[0].toUpperCase(), style: VistaType.labelStrong),
          )
        : VistaIcon(m.rowIcon, size: 24);
    return Semantics(
      button: true,
      label: '$title, $note',
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.97,
        onTap: onTap,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(VistaSpace.xl),
          decoration: BoxDecoration(
            color: VistaColors.surface,
            borderRadius: BorderRadius.circular(VistaRadius.card),
          ),
          child: ValueListenableBuilder(
            valueListenable: MarketPrices.of(m.id),
            builder: (context, price, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    icon,
                    const SizedBox(width: VistaSpace.sm),
                    Expanded(
                      child: Text(
                        title,
                        style: VistaType.subhead.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VistaSpace.md),
                Text(
                  MarketPrices.format(price, compact: true),
                  style: VistaType.figures(VistaType.headline),
                  maxLines: 1,
                ),
                Text(
                  '${m.changePct >= 0 ? '▲' : '▼'}'
                  '${m.changePct.abs().toStringAsFixed(1)}%',
                  style: VistaType.figures(VistaType.label)
                      .copyWith(color: vistaChangeColor(m.changePct)),
                ),
                const SizedBox(height: VistaSpace.md),
                MarketLineChart(
                  id: m.id,
                  changePct: m.changePct,
                  price: price,
                  height: 28,
                ),
                const SizedBox(height: VistaSpace.md),
                Text(
                  note,
                  style: VistaType.meta.copyWith(
                    color: noteColor ?? VistaColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
