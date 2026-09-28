/// Timing of the home card replay, in milliseconds.
///
/// Why these numbers:
/// - Events sit 800 ms apart. Two targets 200–500 ms apart trigger the
///   attentional blink (the second is often missed), and the old 1.8 s
///   replay put them 190 ms and 300 ms apart.
/// - About a second per story beat, in line with animated-chart research
///   (Heer & Robertson, ~1 s per transition stage).
/// - Entrances run 400–650 ms, Material's "long" motion range: long enough to
///   read as an event, short enough to never feel like waiting.
/// - The tip never stops; it only eases into the breakout and settles.
abstract final class ReplayTimeline {
  /// The trace from the call to now.
  static const double trace = 3100;

  /// After the trace: the "% since call" stamp settles.
  static const double finale = 600;

  static const double total = trace + finale;

  /// Marker pop, the ring it sends out, and the label that follows it.
  static const double pop = 450;
  static const double ring = 650;
  static const double labelDelay = 80;
  static const double label = 380;

  /// When the tip reaches each event (it is on that vertex at that moment).
  static const double funding = 1150;
  static const double whale = 1950;
  static const double breakout = 2750;

  /// (time, fraction of the path) the tip passes through. The event rows
  /// put the tip exactly on vertices 20, 33 and 44 of the 48-point path.
  static const _keys = [
    (0.0, 0.0),
    (funding, 20 / 47),
    (whale, 33 / 47),
    (breakout, 44 / 47),
    (trace, 1.0),
  ];

  /// Fraction of the path the tip has covered at [ms]: a smooth curve
  /// through [_keys] that starts from rest and eases to a stop at the end.
  static double progressAt(double ms) {
    if (ms <= 0) return 0;
    if (ms >= trace) return 1;
    var k = 0;
    while (_keys[k + 1].$1 < ms) {
      k++;
    }
    final (x0, y0) = _keys[k];
    final (x1, y1) = _keys[k + 1];
    final h = x1 - x0;
    final s = (ms - x0) / h;
    // Cubic Hermite with averaged secant slopes (zero at both ends).
    final m0 = _slope(k);
    final m1 = _slope(k + 1);
    final s2 = s * s;
    final s3 = s2 * s;
    return (2 * s3 - 3 * s2 + 1) * y0 +
        (s3 - 2 * s2 + s) * h * m0 +
        (-2 * s3 + 3 * s2) * y1 +
        (s3 - s2) * h * m1;
  }

  static double _slope(int k) {
    if (k == 0 || k == _keys.length - 1) return 0;
    double secant(int a) =>
        (_keys[a + 1].$2 - _keys[a].$2) / (_keys[a + 1].$1 - _keys[a].$1);
    return (secant(k - 1) + secant(k)) / 2;
  }

  /// 0 → 1 over [length] ms, starting [start] ms into the replay.
  static double phase(double ms, double start, double length) =>
      ((ms - start) / length).clamp(0.0, 1.0);
}

/// What the card header needs from the replay on each frame.
class ReplayFrame {
  const ReplayFrame({
    this.replaying = false,
    this.priceFraction = 1,
    this.finale = 0,
  });

  /// True while the tip is tracing; the header shows replayed values.
  final bool replaying;

  /// Where the tip is between the call (0) and now (1), by price.
  final double priceFraction;

  /// 0 → 1 while the "% since call" stamp settles after the trace; 0 when
  /// no replay just finished.
  final double finale;
}
