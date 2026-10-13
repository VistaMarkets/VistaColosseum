import '../../design_system/design_system.dart';
import '../home/mock_trade_idea.dart';
import '../trade/trade_mock.dart';

/// A live battle in the carousel: a yes/no question on a market and how the
/// crowd has split on it.
class LiveBattle {
  const LiveBattle({
    required this.ticker,
    required this.change,
    required this.question,
    required this.longShare,
    required this.minutesLeft,
    required this.takes,
    this.chip,
    this.result,
  });

  final String ticker;

  /// The short form calls carry in their debate chip ("Reclaims $72,000 by
  /// Fri"); the question itself when not set.
  final String? chip;
  String get label => chip ?? question;

  /// How it ended, once settled; null while live.
  final DebateResult? result;
  bool get settled => result != null;

  /// Identifies the debate (mock: no server id yet).
  String get id => '$ticker/$label';

  /// Whether [t] is a call on this debate.
  bool has(Take t) => t.ticker == ticker && t.battle == label;

  /// The market's day change, e.g. "+1.2%".
  final String change;
  final String question;

  /// Share of takes on the long side, 0–1.
  final double longShare;

  /// Time until the battle settles, counted from when the app opened.
  final int minutesLeft;
  final int takes;

  /// Minutes still to go, as of now ([DemoClock]).
  int get remaining => minutesLeft - DemoClock.elapsedMinutes;

  /// "45m left", "4h left", "2d left"; "Settling" at zero; "Settled" once
  /// it has.
  String get timeLeft {
    if (settled) return 'Settled';
    final m = remaining;
    if (m <= 0) return 'Settling';
    return m < 60
        ? '${m}m left'
        : m < 1440
        ? '${m ~/ 60}h left'
        : '${m ~/ 1440}d left';
  }

  /// This battle, settled: [longRight] side wins at [at].
  LiveBattle settle({required bool longRight, required String at}) =>
      LiveBattle(
        ticker: ticker,
        change: change,
        question: question,
        chip: chip,
        longShare: longShare,
        minutesLeft: minutesLeft,
        takes: takes,
        result: DebateResult(longRight: longRight, settledAt: at, age: 'now'),
      );
}

/// The demo's clock: battles count down from when the app opened. Tests
/// move [start] back to make time pass.
abstract final class DemoClock {
  static DateTime start = DateTime.now();
  static DateTime Function() now = DateTime.now;
  static int get elapsedMinutes => now().difference(start).inMinutes;

  static void reset() {
    start = DateTime.now();
    now = DateTime.now;
  }
}

/// How a debate settled: which side was right and the price it settled at.
class DebateResult {
  const DebateResult({
    required this.longRight,
    required this.settledAt,
    required this.age,
  });

  final bool longRight;

  /// "$184.20".
  final String settledAt;

  /// How long ago it settled ("3h").
  final String age;
}

/// A settled call or debate as a post in the Arena feed: the receipt, and
/// for a call the caller's own market move as it settled.
class Settlement {
  const Settlement.call({
    required String this.handle,
    required this.ticker,
    required TradeSide this.side,
    required int this.leverage,
    required bool this.right,
    required String this.entry,
    required String this.close,
    required double this.pnlPct,
    required double this.marketMovePct,
    required this.age,
  }) : debate = null;

  const Settlement.debate({required LiveBattle this.debate})
    : handle = null,
      ticker = '',
      side = null,
      leverage = null,
      right = null,
      entry = null,
      close = null,
      pnlPct = null,
      marketMovePct = null,
      age = '';

  final String? handle;
  final String ticker;
  final TradeSide? side;
  final int? leverage;
  final bool? right;
  final String? entry;
  final String? close;

  /// The position's result, levered.
  final double? pnlPct;

  /// The caller's own market (e.g. MAYA) as the call settled.
  final double? marketMovePct;
  final String age;
  final LiveBattle? debate;

  String get marketTicker => debate?.ticker ?? ticker;
  String get when => debate?.result?.age ?? age;
}

/// Why a market is trending, for the Arena hub ("↑ 31 calls this hour").
class Trend {
  const Trend(this.id, this.reason, {this.note});

  /// A ticker, or a trader's handle.
  final String id;
  final String reason;

  /// The second line for an asset ("Unlock tomorrow").
  final String? note;
}

/// One person's take in the feed. A take on a battle carries [battle]; a
/// plain call on a market leaves it null. A backed take carries the
/// position behind it in [call].
class Take {
  const Take({
    required this.handle,
    required this.side,
    required this.accuracy,
    required this.age,
    required this.ticker,
    required this.body,
    required this.likes,
    this.battle,
    this.call,
    this.joined,
    this.idea,
  });

  final String handle;
  final TradeSide side;

  /// Settled calls they got right, e.g. "82% right".
  final String accuracy;
  final String age;
  final String ticker;
  final String body;
  final int likes;

  /// The battle's question, short form ("Reclaims $72,000 by Fri").
  final String? battle;

  /// Their position, when the take is backed.
  final CallerPost? call;

  /// People who joined from this take.
  final int? joined;

  /// The Home card for this call, when it has its own replay (entry,
  /// market events, fills). Calls without one get a card built from their
  /// entry (`HomeFeed.ideaOf`).
  final TradeIdea? idea;

  bool get backed => call != null;

  /// Identifies the take for likes (mock: no server id yet).
  String get id => '$handle/$ticker/$age';
}

/// Mock content from Figma 505:204 ("Arena — takes feed"). Simulated.
abstract final class ArenaMock {
  /// How the Calls list is ordered (the dropdown by its heading).
  static const sorts = ['Following', 'Trending', 'New'];

  /// Callers still building a record: fewer settled calls than this and
  /// their backed calls get the new-caller boost (`HomeFeed`).
  static const newCallerUnder = 5;

  /// Settled calls per caller, for the new-caller boost. Anyone not listed
  /// has a long record. Mock.
  static const settledCalls = {'vega': 2};

  static const battles = [
    LiveBattle(
      ticker: 'BTC',
      change: '+1.2%',
      question: r"Reclaims $72,000 before Friday's expiry",
      chip: r'Reclaims $72,000 by Fri',
      longShare: 0.63,
      minutesLeft: 252,
      takes: 41,
    ),
    LiveBattle(
      ticker: 'ETH',
      change: '−0.4%',
      question: r'Flips $3,200 before the weekly close',
      chip: r'Flips $3,200 before weekly close',
      longShare: 0.41,
      minutesLeft: 1530,
      takes: 28,
    ),
    LiveBattle(
      ticker: 'SOL',
      change: '+3.8%',
      question: r'Holds $200 through the Fed minutes',
      longShare: 0.55,
      minutesLeft: 3100,
      takes: 17,
    ),
    LiveBattle(
      ticker: 'BTC',
      change: '+1.2%',
      question: 'Funding flips negative before Monday',
      longShare: 0.35,
      minutesLeft: 2280,
      takes: 22,
    ),
    LiveBattle(
      ticker: 'ARB',
      change: '+0.9%',
      question: r'Breaks $1.20 this week',
      longShare: 0.48,
      minutesLeft: 45,
      takes: 9,
    ),
    LiveBattle(
      ticker: 'AVAX',
      change: '−2.1%',
      question: r'Back above $40 by Sunday',
      longShare: 0.52,
      minutesLeft: 610,
      takes: 14,
    ),
    // Yours, and nearly done: it settles two minutes after the app opens.
    LiveBattle(
      ticker: 'ETH',
      change: '−0.4%',
      question: r'ETH holds $2,900 into the close',
      chip: r'ETH holds $2,900 into the close',
      longShare: 0.6,
      minutesLeft: 2,
      takes: 6,
    ),
  ];

  /// Debates that have settled; their threads stay open to read.
  static const settledDebates = [
    LiveBattle(
      ticker: 'SOL',
      change: '+3.8%',
      question: r'Holds $180 through CPI',
      longShare: 0.58,
      minutesLeft: 0,
      takes: 24,
      result: DebateResult(longRight: true, settledAt: r'$184.20', age: '3h'),
    ),
  ];

  /// Settled calls and debates for the feed, newest first. In the demo
  /// nothing settles on a clock, so these are seeded.
  static final settlements = [
    const Settlement.call(
      handle: 'maya.eth',
      ticker: 'ETH',
      side: TradeSide.long,
      leverage: 5,
      right: true,
      entry: r'$2,948',
      close: r'$3,050',
      pnlPct: 17.3,
      marketMovePct: 2.1,
      age: '1h',
    ),
    const Settlement.call(
      handle: 'kestrel',
      ticker: 'BTC',
      side: TradeSide.short,
      leverage: 3,
      right: false,
      entry: r'$66,900',
      close: r'$68,000',
      pnlPct: -4.9,
      marketMovePct: -1.4,
      age: '2h',
    ),
    Settlement.debate(debate: settledDebates.first),
  ];

  /// Most right on each asset over 30 days: who, % right on their settled
  /// calls on it, how many calls. Every asset room shows three. Mock: the
  /// backend's per-asset trader stats replace it.
  static const mostRightIn = {
    'ETH': [('maya.eth', 82, 14), ('deltaone', 72, 22), ('lunaq', 64, 9)],
    'BTC': [('renatafx', 84, 11), ('voskov', 71, 8), ('0xreal', 68, 15)],
    'SOL': [('kilo.sol', 69, 12), ('nara', 64, 7), ('kestrel', 57, 10)],
    'ARB': [('kilo.sol', 66, 6), ('orbit.eth', 61, 4), ('sam.sol', 55, 5)],
    'AVAX': [('deltaone', 70, 5), ('mirin', 63, 3), ('vega', 58, 2)],
  };

  /// Trending on the Arena hub, hottest first.
  static const trending = [
    Trend('ARB', '↑ 31 calls this hour', note: 'Unlock tomorrow'),
    Trend('deltaone', '↑ 12 new holders'),
  ];

  /// Who holds a trader's market, for the hub's people line: two names and
  /// how many in all. Mock.
  static const holders = {
    'maya.eth': (names: ['kilo.sol', 'nara'], count: 26),
    'deltaone': (names: ['maya.eth', 'vega'], count: 41),
    'lunaq': (names: ['0xreal', 'kestrel'], count: 12),
  };

  /// Who just did something in a trader market today (trending lines).
  static const boughtToday = {'deltaone': 'maya.eth'};

  /// Ways to order the Live battles page.
  static const battleSorts = ['Most calls', 'Closing soon', 'Closest split'];

  /// [from] in the order of [battleSorts] at [sort].
  static List<LiveBattle> sortedBattles(int sort, List<LiveBattle> from) {
    final list = [...from];
    switch (sort) {
      case 1:
        list.sort((a, b) => a.minutesLeft.compareTo(b.minutesLeft));
      case 2:
        double gap(LiveBattle b) => (b.longShare - 0.5).abs();
        list.sort((a, b) => gap(a).compareTo(gap(b)));
      default:
        list.sort((a, b) => b.takes.compareTo(a.takes));
    }
    return list;
  }

  /// Every call in the demo, in no particular order: takes on battles,
  /// plain calls, and the posts the trade pages' Callers show. `CallsStore`
  /// orders them (backed first, newest first) and serves both pages.
  static const takes = [
    Take(
      handle: 'renatafx',
      side: TradeSide.long,
      accuracy: '82% right',
      age: '2h',
      ticker: 'BTC',
      battle: r'Reclaims $72,000 by Fri',
      body:
          r'ETF bid has absorbed every wick since Tuesday. $71.8k is the last '
          'real supply — one daily close above it and shorts are trapped.',
      call: CallerPost(
        handle: 'renatafx',
        age: '2h',
        side: TradeSide.long,
        leverage: 10,
        entryRatio: 0.986,
        size: 4200,
        takeProfit: 1.083,
        stopLoss: 0.976,
        message: '',
      ),
      likes: 48,
      joined: 12,
    ),
    Take(
      handle: 'voskov',
      side: TradeSide.short,
      accuracy: '71% right',
      age: '40m',
      ticker: 'BTC',
      battle: r'Reclaims $72,000 by Fri',
      body:
          "Funding is paying longs to hold a level they can't take. I'm "
          'fading the third test of 71.8k.',
      call: CallerPost(
        handle: 'voskov',
        age: '40m',
        side: TradeSide.short,
        leverage: 5,
        entryRatio: 0.996,
        size: 2500,
        takeProfit: 0.953,
        stopLoss: 1.031,
        message: '',
      ),
      likes: 31,
      joined: 7,
    ),
    // A plain call: no battle, just the market.
    Take(
      handle: 'kilo.sol',
      side: TradeSide.short,
      accuracy: '69% right',
      age: '25m',
      ticker: 'SOL',
      body:
          'Ran 40% in two weeks straight into the unlock. Starter short '
          r'here, adding if it loses $205.',
      call: CallerPost(
        handle: 'kilo.sol',
        age: '25m',
        side: TradeSide.short,
        leverage: 3,
        entryRatio: 0.99,
        size: 1500,
        takeProfit: 0.88,
        stopLoss: 1.05,
        message: '',
      ),
      likes: 17,
      joined: 3,
    ),
    Take(
      handle: 'nara',
      side: TradeSide.long,
      accuracy: '64% right',
      age: '15m',
      ticker: 'ETH',
      battle: r'Flips $3,200 before weekly close',
      body:
          'Staking outflows just flipped positive for the first time in a '
          r'month. Not in yet — waiting for a reclaim of $3,000.',
      likes: 9,
    ),
    Take(
      handle: 'lunaq',
      side: TradeSide.long,
      accuracy: '58% right',
      age: '8m',
      ticker: 'BTC',
      body: 'Weekly open held twice. Looking for a long on the next retest.',
      likes: 4,
    ),
    // Callers on the trade pages (plain calls, all backed).
    Take(
      handle: 'vega',
      side: TradeSide.short,
      accuracy: '61% right',
      age: '15m',
      ticker: 'ETH',
      body:
          'Third tap of the same ceiling today and volume is fading each '
          'time. Short with a stop just above it.',
      call: CallerPost(
        handle: 'vega',
        age: '15m',
        side: TradeSide.short,
        leverage: 5,
        entryRatio: 1.0021,
        size: 900,
        takeProfit: 0.98,
        stopLoss: 1.01,
        message: '',
        following: false,
      ),
      likes: 6,
    ),
    Take(
      handle: 'lunaq',
      side: TradeSide.long,
      accuracy: '58% right',
      age: '40m',
      ticker: 'ETH',
      body: 'Big bids stacked just under price. Quick one with a tight stop.',
      call: CallerPost(
        handle: 'lunaq',
        age: '40m',
        side: TradeSide.long,
        leverage: 10,
        entryRatio: 0.9983,
        size: 600,
        takeProfit: 1.012,
        stopLoss: 0.994,
        message: '',
        // Took the quick one off: closed 0.11% up, +1.1% at 10x.
        exitRatio: 1.0011,
      ),
      likes: 11,
    ),
    Take(
      handle: 'maya.eth',
      side: TradeSide.long,
      accuracy: '82% right',
      age: '2h',
      ticker: 'ETH',
      body:
          'Reclaimed the range high on real volume. Longing the retest, '
          'stop under the prior low. Not chasing if it loses the level.',
      call: CallerPost(
        handle: 'maya.eth',
        age: '2h',
        side: TradeSide.long,
        leverage: 5,
        entryRatio: 0.9924,
        size: 2400,
        takeProfit: 1.03,
        stopLoss: 0.985,
        message: '',
      ),
      likes: 64,
    ),
    Take(
      handle: 'orbit.eth',
      side: TradeSide.long,
      accuracy: '66% right',
      age: '3h',
      ticker: 'ETH',
      body:
          'Bought the dip into support I have been watching all week. '
          'Adding more only if it holds on the daily close.',
      call: CallerPost(
        handle: 'orbit.eth',
        age: '3h',
        side: TradeSide.long,
        leverage: 3,
        entryRatio: 0.9871,
        size: 1800,
        takeProfit: 1.05,
        stopLoss: 0.975,
        message: '',
        following: false,
      ),
      likes: 19,
    ),
    Take(
      handle: '0xreal',
      side: TradeSide.short,
      accuracy: '68% right',
      age: '5h',
      ticker: 'BTC',
      body:
          'Funding is running hot and open interest keeps climbing into '
          'resistance. Fading it, small size, out if we close above.',
      call: CallerPost(
        handle: '0xreal',
        age: '5h',
        side: TradeSide.short,
        leverage: 3,
        entryRatio: 1.008,
        size: 1200,
        takeProfit: 0.97,
        stopLoss: 1.015,
        message: '',
      ),
      likes: 27,
    ),
    Take(
      handle: 'sam.sol',
      side: TradeSide.long,
      accuracy: '55% right',
      age: '8h',
      ticker: 'SOL',
      body: 'Scalp. Liquidity swept below the lows and snapped straight back.',
      call: CallerPost(
        handle: 'sam.sol',
        age: '8h',
        side: TradeSide.long,
        leverage: 20,
        entryRatio: 0.9960,
        size: 400,
        takeProfit: 1.01,
        stopLoss: 0.996,
        message: '',
        following: false,
      ),
      likes: 5,
    ),
    Take(
      handle: 'deltaone',
      side: TradeSide.short,
      accuracy: '72% right',
      age: '1d',
      ticker: 'BTC',
      body:
          'The weekly close looks weak to me. Holding the short until the '
          'chart proves otherwise.',
      call: CallerPost(
        handle: 'deltaone',
        age: '1d',
        side: TradeSide.short,
        leverage: 2,
        entryRatio: 0.9909,
        size: 3000,
        takeProfit: 0.95,
        stopLoss: 1.03,
        message: '',
      ),
      likes: 38,
    ),
    Take(
      handle: 'mirin',
      side: TradeSide.short,
      accuracy: '63% right',
      age: '2d',
      ticker: 'BTC',
      body:
          'Macro short, not a trade for this week. Rates and liquidity both '
          'point the same way to me.',
      call: CallerPost(
        handle: 'mirin',
        age: '2d',
        side: TradeSide.short,
        leverage: 2,
        entryRatio: 1.0150,
        size: 2500,
        takeProfit: 0.94,
        stopLoss: 1.04,
        message: '',
        following: false,
      ),
      likes: 14,
    ),
    // Arguments on debates: a side and a case, no position behind them.
    Take(
      handle: 'orbit.eth',
      side: TradeSide.short,
      accuracy: '66% right',
      age: '1h',
      ticker: 'BTC',
      battle: r'Reclaims $72,000 by Fri',
      body:
          "Every push into 71k this week came on rising funding and falling "
          "spot volume. That's not a reclaim, that's a squeeze looking for "
          'exits.',
      likes: 21,
    ),
    Take(
      handle: 'deltaone',
      side: TradeSide.long,
      accuracy: '72% right',
      age: '50m',
      ticker: 'BTC',
      battle: r'Reclaims $72,000 by Fri',
      body:
          'ETF inflows have been positive four days running. Expiry pins '
          'price near the big strikes, and 72k is the biggest one.',
      likes: 16,
    ),
    Take(
      handle: 'nara',
      side: TradeSide.long,
      accuracy: '64% right',
      age: '5h',
      ticker: 'SOL',
      battle: r'Holds $180 through CPI',
      body: 'Spot bid at 180 has absorbed every dip since Monday.',
      likes: 12,
    ),
    Take(
      handle: 'kestrel',
      side: TradeSide.short,
      accuracy: '57% right',
      age: '6h',
      ticker: 'SOL',
      battle: r'Holds $180 through CPI',
      body: 'A hot print takes out 180 in the first minute. Too much leverage.',
      likes: 7,
    ),
    // Your call on the battle that settles first.
    Take(
      handle: 'maya.eth',
      side: TradeSide.long,
      accuracy: '82% right',
      age: '3h',
      ticker: 'ETH',
      body: r'$2,900 has held every retest this week. Long into the close.',
      battle: r'ETH holds $2,900 into the close',
      call: CallerPost(
        handle: 'maya.eth',
        age: '3h',
        side: TradeSide.long,
        leverage: 3,
        entryRatio: 0.985,
        size: 800,
        takeProfit: 1.03,
        stopLoss: 0.97,
        message: '',
      ),
      likes: 9,
    ),
  ];
}
