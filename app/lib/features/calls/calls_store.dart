import 'package:flutter/foundation.dart';

import '../arena/arena_mock.dart';
import '../trade/trade_mock.dart';

/// Every published call, in one list for every page: Arena shows all of
/// them, and a trade page's Callers shows the backed ones on its asset. A
/// take posted from Arena lands in both. Seeded from mock data and held in
/// memory; the backend's `/v1/feed` and `/v1/assets/{id}/calls` replace it.
abstract final class CallsStore {
  static final all = ValueNotifier<List<Take>>(_seed());

  static List<Take> _seed() => _ordered(ArenaMock.takes);

  /// Adds a newly posted take.
  static void add(Take t) => all.value = _ordered([t, ...all.value]);

  static void reset() => all.value = _seed();

  /// The backed calls on [ticker], newest first, as caller posts (the
  /// take's text as the post's message).
  static List<CallerPost> callersOn(String ticker) => [
    for (final t in all.value)
      if (t.ticker == ticker && t.call != null) postOf(t),
  ];

  /// A backed take as a caller post, carrying the take's text.
  static CallerPost postOf(Take t) {
    final c = t.call!;
    return CallerPost(
      handle: c.handle,
      age: t.age,
      side: c.side,
      leverage: c.leverage,
      entryRatio: c.entryRatio,
      size: c.size,
      takeProfit: c.takeProfit,
      stopLoss: c.stopLoss,
      message: t.body,
      following: c.following,
    );
  }

  /// Backed first, then newest first within each.
  static List<Take> _ordered(List<Take> takes) {
    final list = [...takes];
    // Stable: equal keys keep their order.
    mergeSort(
      list,
      compare: (a, b) {
        if (a.backed != b.backed) return a.backed ? -1 : 1;
        return minutesAgo(a.age).compareTo(minutesAgo(b.age));
      },
    );
    return List.unmodifiable(list);
  }

  /// "now" → 0, "15m" → 15, "2h" → 120, "1d" → 1440.
  static int minutesAgo(String age) {
    if (age == 'now') return 0;
    final n = int.tryParse(age.substring(0, age.length - 1)) ?? 0;
    return switch (age[age.length - 1]) {
      'd' => n * 1440,
      'h' => n * 60,
      _ => n,
    };
  }
}
