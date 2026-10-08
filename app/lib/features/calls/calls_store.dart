import 'package:flutter/foundation.dart';

import '../arena/arena_mock.dart';
import '../home/mock_trade_idea.dart';
import '../portfolio/portfolio_mock.dart';
import '../trade/trade_mock.dart';

/// Every published call, in one list for every page: Arena shows all of
/// them, and a trade page's Callers shows the backed ones on its asset. A
/// take posted from Arena lands in both. Seeded from mock data and held in
/// memory; the backend's `/v1/feed` and `/v1/assets/{id}/calls` replace it.
abstract final class CallsStore {
  static final all = ValueNotifier<List<Take>>(_seed());

  static List<Take> _seed() =>
      _ordered([...ArenaMock.takes, for (final i in mockFeed) _fromIdea(i)]);

  /// A Home feed card as a call: its question is the call's text and its
  /// replay rides along for Home. Mock records for the callers.
  static Take _fromIdea(TradeIdea i) => Take(
    handle: i.callerHandle,
    side: i.side,
    accuracy: _records[i.callerHandle] ?? '60% right',
    age: i.age,
    ticker: i.ticker,
    body: i.question,
    likes: _count(i.likes),
    joined: _count(i.traders),
    idea: i,
  );

  static const _records = {
    'kaito.eth': '74% right',
    '0xreal': '68% right',
    'kilo.sol': '69% right',
    'lunaq': '58% right',
    'nara': '64% right',
    'deltaone': '72% right',
    'kestrel': '57% right',
    'maya.eth': '82% right',
    'vexa': '66% right',
    'pip.eth': '71% right',
    'orca.sol': '63% right',
  };

  /// "4.4k" → 4400, "860" → 860.
  static int _count(String s) {
    final k = s.endsWith('k');
    final n = double.tryParse(k ? s.substring(0, s.length - 1) : s) ?? 0;
    return (k ? n * 1000 : n).round();
  }

  /// A caller's record ("74% right"), from their calls; null if they have
  /// none. The backend's `TraderStats.winRatePct` replaces it.
  static String? recordOf(String handle) {
    for (final t in all.value) {
      if (t.handle == handle) return t.accuracy;
    }
    return _records[handle];
  }

  /// Puts [t] on the debate [label] (a challenge started one on it).
  static void putOnDebate(Take t, String label) => all.value = [
    for (final x in all.value)
      identical(x, t)
          ? Take(
              handle: x.handle,
              side: x.side,
              accuracy: x.accuracy,
              age: x.age,
              ticker: x.ticker,
              body: x.body,
              likes: x.likes,
              battle: label,
              call: x.call,
              joined: x.joined,
              idea: x.idea,
            )
          : x,
  ];

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

/// Every live battle, seeded from mock data; a battle started from the
/// composer joins it. In memory only.
abstract final class BattlesStore {
  static final all = ValueNotifier<List<LiveBattle>>(ArenaMock.battles);

  /// Newest first: a started battle leads the carousel.
  static void add(LiveBattle b) =>
      all.value = List.unmodifiable([b, ...all.value]);

  static void reset() => all.value = ArenaMock.battles;

  /// A call joins [b] on the long or short side: one more call, and the
  /// split moves with it. Returns the updated battle.
  static LiveBattle join(LiveBattle b, {required bool long}) {
    final n = b.takes + 1;
    final joined = LiveBattle(
      ticker: b.ticker,
      change: b.change,
      question: b.question,
      chip: b.chip,
      longShare: (b.longShare * b.takes + (long ? 1 : 0)) / n,
      minutesLeft: b.minutesLeft,
      takes: n,
    );
    all.value = List.unmodifiable([
      for (final x in all.value) identical(x, b) ? joined : x,
    ]);
    return joined;
  }
}

/// Finds a debate and its calls: live ones from [BattlesStore], settled
/// ones from the mock.
abstract final class Debates {
  static List<LiveBattle> get all => [
    ...BattlesStore.all.value,
    ...ArenaMock.settledDebates,
  ];

  /// The debate [t] is on, if it can be found.
  static LiveBattle? of(Take t) {
    if (t.battle == null) return null;
    for (final b in all) {
      if (b.has(t)) return b;
    }
    return null;
  }

  /// Every call on [b] from [calls]: one you have just posted first (as on
  /// X), then backed ones, then most liked.
  static List<Take> callsOn(LiveBattle b, List<Take> calls) {
    final list = [
      for (final t in calls)
        if (b.has(t)) t,
    ];
    bool fresh(Take t) => t.handle == PortfolioMock.handle && t.age == 'now';
    mergeSort(
      list,
      compare: (x, y) {
        if (fresh(x) != fresh(y)) return fresh(x) ? -1 : 1;
        if (x.backed != y.backed) return x.backed ? -1 : 1;
        return y.likes.compareTo(x.likes);
      },
    );
    return list;
  }
}
