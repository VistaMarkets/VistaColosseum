import '../../design_system/design_system.dart';

/// A battle: a question with a Bull caller against a Bear caller.
class Battle {
  const Battle({
    required this.ticker,
    required this.price,
    required this.change,
    required this.timeLeft,
    required this.question,
    required this.bull,
    required this.bear,
    required this.moreOpinions,
  });

  final String ticker;
  final String price;
  final String change;
  final String timeLeft;
  final String question;
  final VistaBattleSide bull;
  final VistaBattleSide bear;
  final String moreOpinions;
}

/// Mock content from Figma 33:2 ("Arena — screen"). Simulated.
abstract final class ArenaMock {
  static const sorts = ['Volume', 'Change', 'Funding'];

  static const _btc = Battle(
    ticker: 'BTC',
    price: r'$67,412',
    change: '+ 1.2%',
    timeLeft: '4h 12m left',
    question: r"Reclaims $72,000 before Friday's expiry",
    bull: VistaBattleSide(
      caller: 'maya.eth',
      accuracy: '82% accuracy',
      price: r'$0.2610',
      change: '+0.7%',
      thesis:
          'Breaks on ETF flows — spot bid has absorbed every wick since '
          'Tuesday.',
      result: '+4.2%',
      crowd: 'and 14',
    ),
    bear: VistaBattleSide(
      caller: '0xreal',
      accuracy: '68% accuracy',
      price: r'$0.2610',
      change: '-0.7%',
      thesis:
          "Supply wall at 71.8k. Funding is paying longs to hold a level "
          "they can't take.",
      result: '−1.8%',
      crowd: 'and 6',
    ),
    moreOpinions: '+21 more opinions',
  );

  /// Figma shows the same battle twice; the feed repeats it until more
  /// battles are designed.
  static const battles = [_btc, _btc];

  /// Figma's selection: from the 70/30 bucket to the end.
  static const defaultStart = 0.4;
}
