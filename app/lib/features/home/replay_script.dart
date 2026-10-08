import 'dart:math' as math;
import 'dart:ui';

import '../../design_system/design_system.dart';
import '../live/market_prices.dart';

/// Which of a replay's three moments an event is. Each sits on a fixed
/// vertex of the path, so every card keeps the same pacing.
enum ReplayEventKind { funding, whale, payoff }

/// One annotated moment on a replay: its label and whether it went the
/// caller's way (the payoff's tag is green if so, red if not).
class ReplayEvent {
  const ReplayEvent(this.kind, this.label, {this.favourable = true});

  final ReplayEventKind kind;
  final String label;
  final bool favourable;

  /// The path vertex the event sits on.
  int get vertex => switch (kind) {
    ReplayEventKind.funding => 20,
    ReplayEventKind.whale => 33,
    ReplayEventKind.payoff => 44,
  };
}

/// Everything a card's replay chart draws: the price path on the 360×403
/// canvas (48 points, from the call to now), the call line's height, the
/// call tag, the three events, and the prices at the call and at the end
/// of the path that set its scale.
class ReplayScript {
  const ReplayScript({
    required this.path,
    required this.entryY,
    required this.callTag,
    required this.events,
    required this.callPrice,
    required this.nowPrice,
  });

  final List<Offset> path;
  final double entryY;
  final String callTag;
  final List<ReplayEvent> events;
  final double callPrice;
  final double nowPrice;

  /// Point on the path a fraction [t] of the way along its vertices.
  Offset tipAt(double t) {
    final pos = t.clamp(0.0, 1.0) * (path.length - 1);
    final i = pos.floor();
    if (i >= path.length - 1) return path.last;
    return Offset.lerp(path[i], path[i + 1], pos - i)!;
  }

  /// The Figma card (301:102): ETH, called at $2,801.10 five hours ago.
  static const figmaEth = ReplayScript(
    path: [
      Offset(4, 232), Offset(11.4, 275.9), Offset(18.8, 295.2), //
      Offset(26.2, 310.3), Offset(33.6, 317), Offset(41, 321.4),
      Offset(48.4, 345.5), Offset(55.8, 373.5), Offset(63.2, 379),
      Offset(70.6, 355.3), Offset(78, 356.5), Offset(85.4, 342.1),
      Offset(92.9, 330.3), Offset(100.3, 333.2), Offset(107.7, 334.1),
      Offset(115.1, 318.5), Offset(122.5, 325), Offset(129.9, 331),
      Offset(137.3, 332.2), Offset(144.7, 331.5), Offset(152.1, 328.8),
      Offset(159.5, 333.4), Offset(166.9, 311.1), Offset(174.3, 287.9),
      Offset(181.7, 274.3), Offset(189.1, 259.1), Offset(196.5, 255.5),
      Offset(203.9, 225.8), Offset(211.3, 223.3), Offset(218.7, 226.2),
      Offset(226.1, 208.8), Offset(233.5, 208.2), Offset(240.9, 188.6),
      Offset(248.3, 193.6), Offset(255.7, 196.1), Offset(263.1, 168.9),
      Offset(270.6, 145.1), Offset(278, 145.2), Offset(285.4, 118.5),
      Offset(292.8, 125.3), Offset(300.2, 107.4), Offset(307.6, 81.7),
      Offset(315, 85.7), Offset(322.4, 86.2), Offset(329.8, 60.2),
      Offset(337.2, 62.3), Offset(344.6, 38.5), Offset(352, 24),
    ],
    entryY: 232.04,
    callTag: r'Called $2,801.10   5h ago',
    events: [
      ReplayEvent(ReplayEventKind.funding, 'Funding flipped +'),
      ReplayEvent(ReplayEventKind.whale, r'Whale long $4.2M'),
      ReplayEvent(ReplayEventKind.payoff, r'Broke $2,950'),
    ],
    callPrice: 2801.10,
    nowPrice: 2968.40,
  );

  /// A repeatable replay for a call at [callPrice] that stands at
  /// [nowPrice] today: a random walk pinned to both ends (a Brownian
  /// bridge) over a straight drift, so every card has its own shape. The
  /// same [seed] always gives the same path. Event labels come from the
  /// path's own prices.
  factory ReplayScript.generate({
    required String seed,
    required double callPrice,
    required double nowPrice,
    required TradeSide side,
    required String age,
    required String whale,
  }) {
    const n = 48;
    final rng = math.Random(
      seed.codeUnits.fold<int>(7, (h, c) => (h * 37 + c) & 0x7fffffff),
    );
    double gaussian() {
      final u = 1 - rng.nextDouble();
      return math.sqrt(-2 * math.log(u)) *
          math.cos(2 * math.pi * rng.nextDouble());
    }

    // A walk, then bridged so it starts and ends at zero.
    final walk = <double>[0];
    for (var k = 1; k < n; k++) {
      walk.add(walk.last + gaussian());
    }
    final bridge = [
      for (var k = 0; k < n; k++) walk[k] - walk.last * k / (n - 1),
    ];
    final peak = bridge.map((v) => v.abs()).reduce(math.max);
    final move = nowPrice - callPrice;
    final swing = math.max(move.abs() * 0.9, callPrice * 0.004);
    final prices = [
      for (var k = 0; k < n; k++)
        callPrice +
            move * k / (n - 1) +
            (peak == 0 ? 0 : bridge[k] / peak * swing),
    ];

    // Fit the prices into the designed frame (y 24..379) as large as it
    // goes, with two rules: the first three quarters of the path (up to
    // the whale) stay below the live-activity rows at the top left, so
    // their labels never collide; and the call line keeps room under it
    // for its tag. Only the run into the payoff can reach the top.
    const top = 24.0;
    const bottom = 379.0;
    const clearOfActivity = 150.0;
    const lowestCall = 330.0;
    const early = 37;
    double riseOf(Iterable<double> ps) =>
        math.max(0.0, ps.reduce(math.max) - callPrice);
    final above = riseOf(prices);
    final aboveEarly = riseOf(prices.take(early));
    final below = math.max(0.0, callPrice - prices.reduce(math.min));
    double limit(double room, double span) =>
        span <= 0 ? double.infinity : room / span;
    final scale = [
      limit(bottom - top, above + below),
      limit(bottom - clearOfActivity, aboveEarly + below),
      limit(lowestCall - top, above),
      limit(lowestCall - clearOfActivity, aboveEarly),
    ].reduce(math.min);
    final entryY = math.max(
      top + above * scale,
      clearOfActivity + aboveEarly * scale,
    );
    final path = [
      for (var k = 0; k < n; k++)
        Offset(4 + 7.4 * k, entryY - (prices[k] - callPrice) * scale),
    ];

    // The payoff: the level the market broke or lost by the last event,
    // green if that went the caller's way.
    final atPayoff = prices[44];
    final up = atPayoff >= callPrice;
    final level = _roundLevel(atPayoff, up: up);
    final favourable = up == (side == TradeSide.long);
    final funding = rng.nextBool() ? '+' : '−';
    final whaleSide = prices[33] >= prices[20] ? 'long' : 'short';

    return ReplayScript(
      path: path,
      entryY: entryY,
      callTag:
          'Called ${MarketPrices.format(callPrice, compact: true)}   '
          '${age == 'now' ? 'just now' : '$age ago'}',
      events: [
        ReplayEvent(ReplayEventKind.funding, 'Funding flipped $funding'),
        ReplayEvent(ReplayEventKind.whale, 'Whale $whaleSide $whale'),
        ReplayEvent(
          ReplayEventKind.payoff,
          '${up ? 'Broke' : 'Lost'} ${MarketPrices.format(level, compact: true)}',
          favourable: favourable,
        ),
      ],
      callPrice: callPrice,
      nowPrice: nowPrice,
    );
  }

  /// A round level just inside [price]: down when it broke up through it,
  /// up when it lost it on the way down.
  static double _roundLevel(double price, {required bool up}) {
    final step = price >= 10000
        ? 500.0
        : price >= 1000
        ? 50.0
        : price >= 100
        ? 5.0
        : price >= 10
        ? 0.5
        : price >= 1
        ? 0.05
        : 0.005;
    final n = price / step;
    return (up ? n.floorToDouble() : n.ceilToDouble()) * step;
  }
}
