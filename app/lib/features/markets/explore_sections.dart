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
                      note: m.changePct >= 0 ? 'Moving up' : 'Moving down',
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

/// A market card for Explore's sections, wider than the Favorites cards:
/// icon, ticker and leverage over the full name (or the trader's handle),
/// live price with its 24h change, the day as a line chart, why it's in
/// this row, and its figures (OI and funding; cap and holders for a
/// trader).
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

  /// A trader market: their initial, the ticker over the handle.
  final bool trader;

  static const width = 236.0;

  @override
  Widget build(BuildContext context) {
    final m = market;
    final card = MarketsMock.traderCards[m.id];
    final title = trader ? card?.symbol ?? m.name : m.name;
    final subtitle = trader ? m.name : MarketsMock.assetNames[m.id] ?? m.name;
    final muted = VistaType.meta.copyWith(color: VistaColors.textMuted);
    final strong = VistaType.figures(VistaType.meta)
        .copyWith(color: VistaColors.textPrimary, fontWeight: FontWeight.w600);
    final Widget icon = trader
        ? Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color(
                card?.avatar ?? VistaColors.surfaceRaised.toARGB32(),
              ),
              shape: BoxShape.circle,
            ),
            child: Text(m.name[0].toUpperCase(), style: VistaType.body),
          )
        : VistaIcon(m.rowIcon, size: 32);
    // Figures: OI and funding for an asset; cap and holders for a trader.
    final figures = trader
        ? <InlineSpan>[
            TextSpan(text: m.third, style: strong),
            const TextSpan(text: ' cap   '),
            TextSpan(text: '${card?.holders ?? 0}', style: strong),
            const TextSpan(text: ' holders'),
          ]
        : <InlineSpan>[
            const TextSpan(text: 'OI '),
            TextSpan(text: m.subline.replaceFirst('OI ', ''), style: strong),
            const TextSpan(text: '   Funding '),
            TextSpan(text: m.third, style: strong),
          ];
    return Semantics(
      button: true,
      label: '$title, $subtitle, $note',
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.97,
        onTap: onTap,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(VistaSpace.gutter),
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
                    const SizedBox(width: VistaSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: VistaType.subhead.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!trader && m.badge != null) ...[
                                const SizedBox(width: VistaSpace.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: VistaColors.surfaceRaised,
                                    borderRadius: BorderRadius.circular(
                                      VistaRadius.sm,
                                    ),
                                  ),
                                  child: Text(
                                    m.badge!,
                                    style: VistaType.label.copyWith(
                                      color: VistaColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            subtitle,
                            style: VistaType.chip.copyWith(
                              color: VistaColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VistaSpace.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        MarketPrices.format(price, compact: true),
                        style: VistaType.figures(VistaType.headline),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: VistaSpace.sm),
                    Text(
                      '${m.changePct >= 0 ? '▲' : '▼'}'
                      '${m.changePct.abs().toStringAsFixed(1)}%',
                      style: VistaType.figures(VistaType.label)
                          .copyWith(color: vistaChangeColor(m.changePct)),
                    ),
                    Text(
                      trader ? ' 7d' : ' 24h',
                      style: VistaType.label.copyWith(
                        color: VistaColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VistaSpace.md),
                MarketLineChart(
                  id: m.id,
                  changePct: m.changePct,
                  price: price,
                  height: 44,
                ),
                const SizedBox(height: VistaSpace.lg),
                Text(
                  note,
                  style: VistaType.meta.copyWith(
                    color: noteColor ?? VistaColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: VistaSpace.xxs),
                Text.rich(
                  TextSpan(children: figures),
                  style: muted,
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
