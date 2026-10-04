import '../../design_system/design_system.dart';
import '../trade/trade_mock.dart';

/// A live battle in the carousel: a yes/no question on a market and how the
/// crowd has split on it.
class LiveBattle {
  const LiveBattle({
    required this.ticker,
    required this.change,
    required this.question,
    required this.longShare,
    required this.timeLeft,
    required this.takes,
  });

  final String ticker;

  /// The market's day change, e.g. "+1.2%".
  final String change;
  final String question;

  /// Share of takes on the long side, 0–1.
  final double longShare;
  final String timeLeft;
  final int takes;
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

  bool get backed => call != null;
}

/// Mock content from Figma 505:204 ("Arena — takes feed"). Simulated.
abstract final class ArenaMock {
  static const sorts = ['Popular', 'Recent', 'Volume', 'Change', 'Funding'];

  static const battles = [
    LiveBattle(
      ticker: 'BTC',
      change: '+1.2%',
      question: r"Reclaims $72,000 before Friday's expiry",
      longShare: 0.63,
      timeLeft: '4h left',
      takes: 41,
    ),
    LiveBattle(
      ticker: 'ETH',
      change: '−0.4%',
      question: r'Flips $3,200 before the weekly close',
      longShare: 0.41,
      timeLeft: '1d left',
      takes: 28,
    ),
    LiveBattle(
      ticker: 'SOL',
      change: '+3.8%',
      question: r'Holds $200 through the Fed minutes',
      longShare: 0.55,
      timeLeft: '2d left',
      takes: 17,
    ),
  ];

  /// Backed takes first, then the rest; each group newest first.
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
  ];
}
