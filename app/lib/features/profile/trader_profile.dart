import 'package:flutter/painting.dart';

import '../../design_system/design_system.dart';
import '../arena/arena_mock.dart';
import '../calls/calls_store.dart';
import '../live/market_prices.dart';
import '../markets/markets_mock.dart';
import '../markets/trader_standing.dart';
import '../people/follow_mock.dart';
import '../portfolio/portfolio_mock.dart';
import 'profile_mock.dart';

/// One trader's profile figures: record, followers, bio, market, what they
/// hold and their call receipts. maya.eth (you) keeps the designed profile
/// (Figma 303:102); everyone else's comes from their own calls and market.
/// Mock.
class TraderProfile {
  const TraderProfile({
    required this.handle,
    required this.recordSince,
    required this.settled,
    required this.right,
    required this.open,
    required this.followers,
    required this.bio,
    required this.holdings,
    required this.cashShare,
    required this.receipts,
  });

  final String handle;
  final String recordSince;
  final int settled;
  final int right;
  final int open;
  final String followers;
  final String bio;
  final List<Holding> holdings;
  final String cashShare;
  final List<ProfileReceipt> receipts;

  int get wrong => settled - right;

  /// Their market (symbol, cap); null without one.
  ({String symbol, String cap, double capM})? get market =>
      TraderStanding.of(handle);

  /// The market's 7d change, e.g. "+4.27%"; null without a market.
  double? get change =>
      MarketsMock.traders.where((m) => m.id == handle).firstOrNull?.changePct;

  List<(String, Color)> get summary => [
    ('$settled settled', VistaColors.textPrimary),
    ('$right right', VistaColors.long),
    ('$wrong wrong', VistaColors.short),
    ('$open open', VistaColors.textMuted),
  ];

  /// All / Calls / Debates with counts.
  List<(String, int)> get filters => [
    ('All', receipts.length),
    ('Calls', receipts.where((r) => r.kind == ReceiptKind.call).length),
    ('Debates', receipts.where((r) => r.kind == ReceiptKind.arena).length),
  ];

  static const _bios = {
    'kaito.eth':
        'ETH maxi with a stop loss. Breakouts only, no averaging down.',
    '0xreal': 'Fades crowded trades. Funding tells you who is trapped.',
    'kilo.sol':
        'SOL ecosystem and unlock calendars. Short the hype, long the dip.',
    'lunaq': 'Scalps and quick ones. Tight stops, no overnight risk.',
    'deltaone': 'Delta-neutral most days. When I lean, I lean hard.',
    'kestrel': 'Higher timeframes, fewer trades, bigger conviction.',
    'renatafx': 'Ex-FX desk. Flows first, charts second.',
    'voskov':
        'Contrarian on purpose. If everyone agrees, I check the other side.',
    'vega': 'Range trader. I sell the third tap.',
    'vexa': 'New here. Momentum on the majors, sized small.',
    'pip.eth': 'Two-week-old market, two-year-old process.',
    'orca.sol': 'SOL beta. Patient entries, quick exits.',
  };

  /// A steady 0–1 per handle, so made-up figures don't jump around.
  static double _seed(String handle, int salt) {
    var h = salt;
    for (final c in handle.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    h = ((h ^ (h >> 13)) * 0x5bd1e995) & 0x7fffffff;
    return (h % 1000) / 1000;
  }

  static TraderProfile of(String handle) {
    if (handle == PortfolioMock.handle) return _yours;
    final pct =
        int.tryParse((CallsStore.recordOf(handle) ?? '').split('%').first) ??
        60;
    final market = MarketsMock.traders.where((m) => m.id == handle).firstOrNull;
    final card = MarketsMock.traderCards[handle];
    // Settled calls: their market's call count, or a steady made-up one.
    final settled =
        int.tryParse(market?.subline.split(' ').first ?? '') ??
        (20 + _seed(handle, 1) * 90).round();
    final mine = [
      for (final t in CallsStore.all.value)
        if (t.handle == handle) t,
    ];
    final calls = [
      for (final t in mine)
        if (t.backed) t,
    ];
    final months = card != null
        ? (card.days / 30).ceil().clamp(1, 36)
        : (3 + _seed(handle, 2) * 20).round();
    final followers = card != null
        ? card.holders * 4 + (_seed(handle, 3) * 200).round()
        : (80 + _seed(handle, 3) * 2400).round();
    return TraderProfile(
      handle: handle,
      recordSince: card != null && card.days < 30
          ? 'Record since ${card.days}d ago'
          : 'Record since $months mo',
      settled: settled,
      right: (settled * pct / 100).round(),
      open: mine.length,
      followers: followers >= 1000
          ? '${(followers / 1000).toStringAsFixed(1)}k'
          : '$followers',
      bio: _bios[handle] ?? 'Calls with a position behind every one.',
      holdings: [for (final t in calls) _holding(t)],
      cashShare: 'Cash   ${(5 + _seed(handle, 4) * 30).round()}%',
      receipts: [for (final t in mine) _receipt(t), ..._settled(handle, pct)],
    );
  }

  static double _entry(Take t) =>
      MarketPrices.base(t.ticker) * t.call!.entryRatio;

  static Holding _holding(Take t) {
    final c = t.call!;
    final entry = _entry(t);
    final now = MarketPrices.base(t.ticker);
    final pnl = c.pnlPct(entry, now);
    return Holding(
      ticker: t.ticker,
      side: c.side,
      leverage: c.leverage,
      entry: MarketPrices.format(entry, compact: true),
      current: MarketPrices.format(now, compact: true),
      pnl: '${pnl >= 0 ? '+' : '−'}${pnl.abs().toStringAsFixed(1)}%',
    );
  }

  /// Their last few settled calls, right or wrong in line with their
  /// record. Mock.
  static List<ProfileReceipt> _settled(String handle, int pct) {
    const picks = [
      ('Sep 30', r'BTC holds $64,000 to Sep 30', 64000.0, 64820.0, true),
      ('Sep 26', r'ETH reclaims $2,900 by Sep 26', 2900.0, 2936.0, true),
      ('Sep 22', r'SOL loses $190 by Sep 22', 190.0, 196.4, false),
      ('Sep 18', r'ARB holds $1.00 to Sep 18', 1.0, 1.04, true),
    ];
    final out = <ProfileReceipt>[];
    for (var i = 0; i < 3; i++) {
      final (date, title, entry, settle, long) =
          picks[(i + (_seed(handle, 5) * 4).floor()) % picks.length];
      final right = _seed(handle, 10 + i) * 100 < pct;
      out.add(
        ProfileReceipt(
          kind: ReceiptKind.call,
          rail: right
              ? VistaAssets.railRecordRight
              : VistaAssets.railRecordWrong,
          title: title,
          side: long ? TradeSide.long : TradeSide.short,
          entry: MarketPrices.format(entry, compact: true),
          close: 'Settled ${MarketPrices.format(settle, compact: true)}',
          lead: right ? 'Right' : 'Wrong',
          leadColor: right ? VistaColors.long : VistaColors.short,
          detail: 'settled $date',
        ),
      );
    }
    return out;
  }

  /// An open call as a receipt: on a battle it's a debate, else a call.
  static ProfileReceipt _receipt(Take t) {
    final c = t.call;
    if (c == null) {
      return ProfileReceipt(
        kind: t.battle != null ? ReceiptKind.arena : ReceiptKind.call,
        rail: t.battle != null
            ? VistaAssets.railArenaOpen
            : VistaAssets.railCallOpen,
        title: t.battle ?? '${t.side.label} ${t.ticker}',
        side: t.side,
        entry: MarketPrices.format(MarketPrices.base(t.ticker), compact: true),
        close:
            'Now ${MarketPrices.format(MarketPrices.base(t.ticker), compact: true)}',
        lead: 'Open',
        leadColor: VistaColors.textMuted,
        detail: 'Called ${t.age} ago',
      );
    }
    final entry = _entry(t);
    final now = MarketPrices.base(t.ticker);
    final pnl = c.pnlPct(entry, now);
    final debate = t.battle != null;
    return ProfileReceipt(
      kind: debate ? ReceiptKind.arena : ReceiptKind.call,
      rail: debate ? VistaAssets.railArenaOpen : VistaAssets.railCallOpen,
      title: t.battle ?? '${c.side.label} ${t.ticker} ${c.leverage}x',
      side: c.side,
      entry: MarketPrices.format(entry, compact: true),
      close: 'Now ${MarketPrices.format(now, compact: true)}',
      lead: '${pnl >= 0 ? '+' : '−'}${pnl.abs().toStringAsFixed(1)}% so far',
      leadColor: pnl >= 0 ? VistaColors.long : VistaColors.short,
      detail: 'Called ${t.age} ago   still open',
    );
  }

  static final _yours = TraderProfile(
    handle: PortfolioMock.handle,
    recordSince: ProfileMock.recordSince,
    settled: int.parse(ProfileMock.settled),
    right: int.parse(ProfileMock.right),
    open: 3,
    followers: FollowMock.followerCount,
    bio: ProfileMock.bio,
    holdings: ProfileMock.holdings,
    cashShare: ProfileMock.cashShare,
    receipts: ProfileMock.receipts,
  );
}
