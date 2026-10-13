import 'package:flutter/material.dart' show Color;

import '../../design_system/design_system.dart';
import '../market/market_mock.dart';
import '../market/trader_market_mock.dart';
import '../people/follow_mock.dart';

/// A live position shown in "Holding now".
class Holding {
  const Holding({
    required this.ticker,
    required this.side,
    required this.leverage,
    required this.entry,
    required this.current,
    required this.pnl,
  });

  final String ticker;
  final TradeSide side;
  final int leverage;
  final String entry;
  final String current;
  final String pnl;

  bool get inProfit => !pnl.startsWith('−');
}

/// A profile's market block: its cap, unit price, 24h change and open.
typedef MarketFigures = ({
  String market,
  String price,
  String cap,
  String change,
  String openPrice,
});

enum ReceiptKind { call, arena }

/// A call or arena receipt on a profile.
class ProfileReceipt {
  const ProfileReceipt({
    required this.kind,
    required this.rail,
    required this.title,
    required this.lead,
    required this.leadColor,
    required this.detail,
    required this.side,
    required this.entry,
    required this.close,
    this.versus,
  });

  final ReceiptKind kind;

  /// The side taken, the price when it was called, and how it ended (the
  /// settle price) or where it stands now if still open.
  final TradeSide side;
  final String entry;
  final String close;

  bool get open =>
      !lead.startsWith('Right') &&
      !lead.startsWith('Wrong') &&
      !close.startsWith('Closed');
  final String rail;
  final String title;
  final String lead;
  final Color leadColor;
  final String detail;
  final VistaVersus? versus;
}

/// Sample profile content from Figma 303:102 (maya.eth). Every profile in the
/// demo shows this content under its own handle. Simulated.
abstract final class ProfileMock {
  static const recordSince = 'Record since Jun 2026   14 mo';
  static const settled = '62';
  static const right = '36';
  static const followers = FollowMock.followerCount;
  static const market = r'$44.0M';
  static const bio =
      'Macro-first. Mostly BTC and SOL, rarely leveraged past 5x. '
      'I write down why before I enter.';

  static const price = r'$0.4400';
  static const cap = r'$44.0M cap';
  static const change = '+4.27%';
  static const openPrice = r'Open $0.4220';

  /// [handle]'s market figures: the user's own market reads its cap
  /// (VC-MKT-001, `TraderMarketMock.own`); every other profile shows the
  /// fixture above.
  static MarketFigures marketOf(String handle) {
    if (handle != TraderMarketMock.own) {
      return (
        market: market,
        price: price,
        cap: cap,
        change: change,
        openPrice: openPrice,
      );
    }
    final c = TraderMarketMock.ownCapCents;
    final supply = YourMarketMock.supplyUnits;
    return (
      market: formatCap(c),
      price: formatUnitPrice(c, supply),
      cap: '${formatCap(c)} cap',
      change: TraderMarketMock.change24hOf(handle),
      openPrice:
          'Open ${formatUnitPrice(c - TraderMarketMock.ownDayMoveCents, supply)}',
    );
  }

  static const holdings = [
    Holding(
      ticker: 'SOL',
      side: TradeSide.long,
      leverage: 5,
      entry: r'$198.40',
      current: r'$214.90',
      pnl: '+41.6%',
    ),
    Holding(
      ticker: 'ETH',
      side: TradeSide.long,
      leverage: 3,
      entry: r'$2,927',
      current: r'$2,968',
      pnl: '+4.2%',
    ),
    Holding(
      ticker: 'BTC',
      side: TradeSide.short,
      leverage: 2,
      entry: r'$67,020',
      current: r'$67,412',
      pnl: '−1.2%',
    ),
  ];
  static const cashShare = 'Cash   9%';

  static const summary = [
    ('62 settled', VistaColors.textPrimary),
    ('36 right', VistaColors.long),
    ('26 wrong', VistaColors.short),
    ('3 open', VistaColors.textMuted),
  ];

  static const receipts = [
    ProfileReceipt(
      kind: ReceiptKind.call,
      rail: VistaAssets.railCallOpen,
      title: r'SOL reaches $300 by Fri',
      side: TradeSide.long,
      entry: r'$214.60',
      close: r'Now $214.90',
      lead: '2d left',
      leadColor: VistaColors.textMuted,
      detail: 'Market said 22%   39.6% away',
    ),
    ProfileReceipt(
      kind: ReceiptKind.arena,
      rail: VistaAssets.railArenaOpen,
      title: r'BTC stays under $72,000 to Oct 5',
      side: TradeSide.short,
      entry: r'$67,880',
      close: r'Now $67,412',
      versus: VistaVersus(
        name: 'lunaq',
        avatarAsset: VistaAssets.opponentAvatarLong,
      ),
      lead: '10d left',
      leadColor: VistaColors.textMuted,
      detail: 'took the other side of lunaq   market said 71%',
    ),
    ProfileReceipt(
      kind: ReceiptKind.call,
      rail: VistaAssets.railCallOpen,
      title: r'ETH holds $3,000 to Oct 1',
      side: TradeSide.long,
      entry: r'$3,052',
      close: r'Now $2,968',
      lead: '6d left',
      leadColor: VistaColors.textMuted,
      detail: 'Market said 64%   5.7% cushion',
    ),
    ProfileReceipt(
      kind: ReceiptKind.arena,
      rail: VistaAssets.railArenaRight,
      title: r'ARB stays under $1.20 to Sep 18',
      side: TradeSide.short,
      entry: r'$1.14',
      close: r'Settled $1.09',
      versus: VistaVersus(
        name: '0xreal',
        avatarAsset: VistaAssets.opponentAvatarShort,
      ),
      lead: 'Right at 34%',
      leadColor: VistaColors.long,
      detail: 'beat 0xreal   settled Sep 18',
    ),
    ProfileReceipt(
      kind: ReceiptKind.call,
      rail: VistaAssets.railCallRight,
      title: r'BTC reclaims $66,000 by Tue',
      side: TradeSide.long,
      entry: r'$64,920',
      close: r'Settled $66,340',
      lead: 'Right at 31%',
      leadColor: VistaColors.long,
      detail: 'settled Tue 16:00',
    ),
    ProfileReceipt(
      kind: ReceiptKind.arena,
      rail: VistaAssets.railArenaWrong,
      title: r'SOL loses $190 by Sep 15',
      side: TradeSide.short,
      entry: r'$201.30',
      close: r'Settled $196.80',
      versus: VistaVersus(
        name: 'kilo.sol',
        avatarAsset: VistaAssets.opponentAvatarLong,
      ),
      lead: 'Wrong at 41%',
      leadColor: VistaColors.short,
      detail: 'kilo.sol was right   settled Sep 15',
    ),
  ];

  /// Filter counts as designed ("All 65 · Calls 51 · Arena 14").
  static const filters = [('All', 65), ('Calls', 51), ('Debates', 14)];
}

/// A private account with no market: stats and public calls only (Figma
/// 258:407, "Profile — nara (private account)").
class PrivateProfile {
  const PrivateProfile({required this.followers, required this.bio});

  final String followers;
  final String bio;
}

/// Private accounts without a market. Opening one of these profiles shows
/// the private layout instead of the full profile.
const privateProfiles = {
  'nara': PrivateProfile(
    followers: '212',
    bio: 'Swing trades on the majors. I post calls, not positions.',
  ),
};
