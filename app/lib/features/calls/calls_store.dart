import 'package:flutter/foundation.dart';

import '../arena/arena_mock.dart';
import '../home/mock_trade_idea.dart';
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
  };

  /// "4.4k" → 4400, "860" → 860.
  static int _count(String s) {
    final k = s.endsWith('k');
    final n = double.tryParse(k ? s.substring(0, s.length - 1) : s) ?? 0;
    return (k ? n * 1000 : n).round();
  }

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
}
