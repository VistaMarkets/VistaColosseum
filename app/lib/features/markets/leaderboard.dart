import '../calls/calls_store.dart';
import 'markets_mock.dart';

/// The Explore Leaderboard's figures: what each chip ranks by over each
/// time window. The mock's own figures are the 7d ones (and the all-time
/// record for Most right); other windows are derived. Mock.
abstract final class Leaderboard {
  /// Time windows; 7d (index 1) is the default.
  static const windows = ['24h', '7d', '30d', 'All'];

  /// How each window reads after a figure ("+$12.4K this week").
  static const periods = ['today', 'this week', 'this month', 'all time'];

  /// A steady 0.6–1.4 per trader and window, so other windows reorder the
  /// board without random churn.
  static double _jitter(String id, int window) {
    var h = 0;
    for (final c in '$window/$id'.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    h = ((h ^ (h >> 13)) * 0x5bd1e995) & 0x7fffffff;
    h ^= h >> 15;
    return 0.6 + (h % 1000) / 1000 * 0.8;
  }

  /// What [metric] (a `MarketsMock.traderSorts` chip) is for [m] over
  /// [window]: the figure shown and ranked by. Null when unknown.
  static double? value(MarketItem m, String metric, int window) {
    final c = MarketsMock.traderCards[m.id];
    final j = _jitter(m.id, window);
    switch (metric) {
      case 'Most right':
        final pct = double.tryParse(
          (CallsStore.recordOf(m.id) ?? '').split('%').first,
        );
        if (pct == null || window == 3) return pct;
        return (pct + (j - 1) * 20).roundToDouble().clamp(35, 95);
      case 'Top P&L':
        if (c == null) return null;
        const scale = [1 / 6, 1.0, 3.5, 12.0];
        return c.weekPnl * scale[window] * (window == 1 ? 1 : j);
      case 'Up and coming':
        if (c == null) return null;
        return switch (window) {
          0 => (c.newHolders / 7 * j).roundToDouble(),
          1 => c.newHolders.toDouble(),
          // Every market here is under 30 days old.
          _ => c.holders.toDouble(),
        };
      case 'Change':
        const scale = [0.25, 1.0, 2.5, 6.0];
        return m.changePct * scale[window] * (window == 1 ? 1 : j);
      default:
        return m.sortValues[metric];
    }
  }

  /// "+$12.4K" / "−$0.9K"; whole thousands from $100K ("+$214K").
  static String money(double v) {
    final k = v.abs() / 1000;
    return '${v < 0 ? '−' : '+'}\$${k.toStringAsFixed(k >= 100 ? 0 : 1)}K';
  }
}
