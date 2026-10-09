import 'dart:math' as math;

import '../../design_system/design_system.dart';
import '../live/market_prices.dart';
import '../market/trader_market_mock.dart';
import 'opinions_mock.dart';

/// A battle (a clash): a question on one asset with a Bull caller against a
/// Bear caller. The numbers are fixture fields; the card's strings derive
/// from them.
class Battle {
  const Battle({
    required this.id,
    required this.asset,
    required this.price,
    required this.volume,
    required this.changePct,
    required this.fundingPct,
    required this.bullPct,
    required this.bullCount,
    required this.bearCount,
    required this.timeLeft,
    required this.question,
    required this.bull,
    required this.bear,
    required this.opinionCount,
    required this.opinions,
  });

  /// Stable clash id; orders placed from this battle carry it.
  final String id;

  /// The ticker the sides trade: Bull is long it, Bear short.
  final String asset;
  final String price;

  /// 24h volume in int US cents (a sort key).
  final int volume;

  /// 24h price change and funding rate, in percent (sort keys); the
  /// Markets tab's values for [asset].
  final double changePct;
  final double fundingPct;

  /// Bull's share of the crowd, 0–100. A crowd split, not odds.
  final int bullPct;

  /// Others on each side besides its lead caller, before the user joins.
  final int bullCount;
  final int bearCount;
  final String timeLeft;
  final String question;

  /// The lead callers. Their crowd line is drawn from the counts.
  final VistaBattleSide bull;
  final VistaBattleSide bear;

  /// Every opinion on the battle; [opinions] are the seeded ones.
  final int opinionCount;
  final List<Opinion> opinions;

  String get change =>
      '${changePct < 0 ? '−' : '+'} ${changePct.abs().toStringAsFixed(1)}%';

  /// The card shows the two leads; the pill counts the rest.
  String get moreOpinions => '+${opinionCount - 2} more opinions';

  /// Crowd-split bucket: 50/50 → 0 … 95/5 and over → 9, either side.
  int get bucket => math.min(
    (math.max(bullPct, 100 - bullPct) - 50) ~/ 5,
    ArenaMock.bucketCount - 1,
  );
}

/// What the Arena shows: a sort chip, a crowd-split bucket range
/// `[from, to)` and the Ask query. Held in `Scenario.arena`, so the list
/// and the crowd panel agree and Reset clears it.
typedef ArenaView = ({int sort, int from, int to, String query});

/// Mock content from Figma 33:2 ("Arena — screen"). Simulated.
abstract final class ArenaMock {
  static const sorts = ['Volume', 'Change', 'Funding'];

  /// Crowd-split buckets, 50/50 to 100/0 in 5% steps.
  static const bucketCount = 10;

  /// Every battle, sorted by volume, any split, any asset.
  static const ArenaView allBattles = (
    sort: 0,
    from: 0,
    to: bucketCount,
    query: '',
  );

  // Callers with a `MarketPrices` entry (maya.eth, 0xreal, kilo.sol, lunaq)
  // quote its opening price and their Explore change. They are fixed, while
  // other screens' prices walk every 3 s from that open. The user is
  // maya.eth, whose trader market is their listed market (ruled
  // 2026-10-09), so her price and change read `TraderMarketMock.own*`:
  // the seed's $0.4400 and +4.3% before a listing, $0.0001 and +0.0% after
  // a fresh one. mirin and renatafx have no `MarketPrices` entry and no
  // Explore row, so their price and change match nothing.
  static Battle get _btc => Battle(
    id: 'btc-72k',
    asset: 'BTC',
    price: r'$67,412',
    volume: 184000000000,
    changePct: 1.2,
    fundingPct: 0.009,
    bullPct: 63,
    bullCount: 14,
    bearCount: 6,
    timeLeft: '4h 12m left',
    question: r"Reclaims $72,000 before Friday's expiry",
    bull: VistaBattleSide(
      caller: TraderMarketMock.own,
      price: MarketPrices.format(TraderMarketMock.ownUnitPrice, compact: true),
      change: _pct(TraderMarketMock.ownDayChangePct),
      thesis:
          'Breaks on ETF flows — spot bid has absorbed every wick since '
          'Tuesday.',
      result: '+4.2%',
    ),
    bear: VistaBattleSide(
      caller: '0xreal',
      price: r'$0.3820',
      change: '+1.1%',
      thesis:
          "Supply wall at 71.8k. Funding is paying longs to hold a level "
          "they can't take.",
      result: '−1.8%',
    ),
    opinionCount: 23,
    opinions: OpinionsMock.opinions,
  );

  static const _eth = Battle(
    id: 'eth-4k',
    asset: 'ETH',
    price: r'$2,968',
    volume: 92000000000,
    changePct: -0.4,
    fundingPct: -0.004,
    bullPct: 28,
    bullCount: 5,
    bearCount: 12,
    timeLeft: '2d 6h left',
    question: r"Tags $4,000 before the month's close",
    bull: VistaBattleSide(
      caller: 'kilo.sol',
      price: r'$0.1720',
      change: '+2.2%',
      thesis: 'Staking outflows have flipped and the ETF bid is back.',
      result: '+2.6%',
    ),
    bear: VistaBattleSide(
      caller: 'lunaq',
      price: r'$0.3145',
      change: '−2.4%',
      thesis: 'Spot is not following the perps and the ETF bid has stalled.',
      result: '+3.1%',
    ),
    opinionCount: 9,
    opinions: [
      Opinion(
        initials: 'KS',
        handle: '@kilo.sol',
        subtitle: 'Trader',
        side: OpinionSide.bull,
        label: 'BULL',
        thesis: 'Staking outflows have flipped and the ETF bid is back.',
        stats: [
          VistaSideStat(r'$2,940', 'Entry'),
          VistaSideStat('+2.6%', 'Live', color: VistaColors.long),
        ],
      ),
      Opinion(
        initials: 'LQ',
        handle: '@lunaq',
        subtitle: 'Sniper',
        side: OpinionSide.bear,
        label: 'BEAR',
        thesis: 'Spot is not following the perps and the ETF bid has stalled.',
        stats: [
          VistaSideStat(r'$3,060', 'Entry'),
          VistaSideStat('+3.1%', 'Live', color: VistaColors.long),
        ],
      ),
    ],
  );

  static const _sol = Battle(
    id: 'sol-200',
    asset: 'SOL',
    price: r'$214.90',
    volume: 41000000000,
    changePct: 3.8,
    fundingPct: 0.012,
    bullPct: 88,
    bullCount: 21,
    bearCount: 3,
    timeLeft: '1d 2h left',
    question: r"Holds $200 through Sunday's close",
    bull: VistaBattleSide(
      caller: 'mirin',
      price: r'$0.4410',
      change: '+2.3%',
      thesis: 'Every dip under 205 was bought inside the hour this week.',
      result: '+5.0%',
    ),
    bear: VistaBattleSide(
      caller: 'renatafx',
      price: r'$0.2290',
      change: '−1.2%',
      thesis: 'The unlock lands Saturday and the order book is thin.',
      result: '−2.2%',
    ),
    opinionCount: 14,
    opinions: [
      Opinion(
        initials: 'MI',
        handle: '@mirin',
        subtitle: 'Contractor',
        side: OpinionSide.bull,
        label: 'BULL',
        thesis: 'Every dip under 205 was bought inside the hour this week.',
        stats: [
          VistaSideStat(r'$204.10', 'Entry'),
          VistaSideStat('+5.0%', 'Live', color: VistaColors.long),
        ],
      ),
      Opinion(
        initials: 'RF',
        handle: '@renatafx',
        subtitle: 'sniper of charts',
        side: OpinionSide.bear,
        label: 'BEAR',
        thesis: 'The unlock lands Saturday and the order book is thin.',
        stats: [
          VistaSideStat(r'$219.80', 'Entry'),
          VistaSideStat('−2.2%', 'Live', color: VistaColors.short),
        ],
      ),
    ],
  );

  /// In no particular order: the Arena always sorts.
  static List<Battle> get battles => [_btc, _sol, _eth];

  /// "+4.3%" or "−2.4%", as Arena prints a caller's change.
  static String _pct(double p) =>
      '${p < 0 ? '−' : '+'}${p.abs().toStringAsFixed(1)}%';

  /// The assets Ask knows, for its no-match hint.
  static final askHint =
      'Try ${({for (final b in battles) b.asset}.toList()..sort()).join(', ')}';

  /// Battles in [pool] whose asset contains [query], any case.
  static List<Battle> asked(String query, [List<Battle>? pool]) {
    final q = query.trim().toUpperCase();
    return [
      for (final b in pool ?? battles)
        if (b.asset.contains(q)) b,
    ];
  }

  /// Battles per crowd-split bucket among those Ask matches.
  static List<double> buckets(String query) {
    final counts = List<double>.filled(bucketCount, 0);
    for (final b in asked(query)) {
      counts[b.bucket]++;
    }
    return counts;
  }

  /// What the list shows: Ask's matches in the range, highest first by the
  /// sort chip's field, ties by id.
  static List<Battle> visible(ArenaView v, [List<Battle>? pool]) {
    num key(Battle b) => switch (v.sort) {
      1 => b.changePct,
      2 => b.fundingPct,
      _ => b.volume,
    };
    return [
      for (final b in asked(v.query, pool))
        if (b.bucket >= v.from && b.bucket < v.to) b,
    ]..sort((a, b) {
      final c = key(b).compareTo(key(a));
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  }
}
