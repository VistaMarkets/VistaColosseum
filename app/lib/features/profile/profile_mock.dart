import 'package:flutter/painting.dart';

import '../../design_system/design_system.dart';
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
    this.versus,
  });

  final ReceiptKind kind;
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
  static const recordSince = 'Record since Jun 2026 · 14 mo';
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
  static const cashShare = 'Cash · 9%';

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
      lead: '2d left',
      leadColor: VistaColors.textMuted,
      detail: 'Market said 22% · 39.6% away',
    ),
    ProfileReceipt(
      kind: ReceiptKind.arena,
      rail: VistaAssets.railArenaOpen,
      title: r'BTC stays under $72,000 to Oct 5',
      versus: VistaVersus(
        name: 'lunaq',
        avatarAsset: VistaAssets.opponentAvatarLong,
      ),
      lead: '10d left',
      leadColor: VistaColors.textMuted,
      detail: 'took the other side of lunaq · market said 71%',
    ),
    ProfileReceipt(
      kind: ReceiptKind.call,
      rail: VistaAssets.railCallOpen,
      title: r'ETH holds $3,000 to Oct 1',
      lead: '6d left',
      leadColor: VistaColors.textMuted,
      detail: 'Market said 64% · 5.7% cushion',
    ),
    ProfileReceipt(
      kind: ReceiptKind.arena,
      rail: VistaAssets.railArenaRight,
      title: r'ARB stays under $1.20 to Sep 18',
      versus: VistaVersus(
        name: '0xreal',
        avatarAsset: VistaAssets.opponentAvatarShort,
      ),
      lead: 'Right at 34%',
      leadColor: VistaColors.long,
      detail: 'beat 0xreal · settled Sep 18',
    ),
    ProfileReceipt(
      kind: ReceiptKind.call,
      rail: VistaAssets.railCallRight,
      title: r'BTC reclaims $66,000 by Tue',
      lead: 'Right at 31%',
      leadColor: VistaColors.long,
      detail: 'settled Tue 16:00',
    ),
    ProfileReceipt(
      kind: ReceiptKind.arena,
      rail: VistaAssets.railArenaWrong,
      title: r'SOL loses $190 by Sep 15',
      versus: VistaVersus(
        name: 'kilo.sol',
        avatarAsset: VistaAssets.opponentAvatarLong,
      ),
      lead: 'Wrong at 41%',
      leadColor: VistaColors.short,
      detail: 'kilo.sol was right · settled Sep 15',
    ),
  ];

  /// Filter counts as designed ("All 65 · Calls 51 · Arena 14").
  static const filters = [('All', 65), ('Calls', 51), ('Arena', 14)];
}

/// A private account with no market: stats and public calls only (Figma
/// 258:407, "Profile — nara (private account)").
class PrivateProfile {
  const PrivateProfile({
    required this.settled,
    required this.right,
    required this.followers,
    required this.openCalls,
    required this.bio,
    required this.summary,
    required this.calls,
  });

  final String settled;
  final String right;
  final String followers;
  final String openCalls;
  final String bio;
  final List<(String, Color)> summary;

  /// (rail, title, lead, lead colour, detail).
  final List<(String, String, String, Color, String)> calls;
}

/// Private accounts without a market. Opening one of these profiles shows
/// the private layout instead of the full profile.
const privateProfiles = {
  'nara': PrivateProfile(
    settled: '31',
    right: '17',
    followers: '212',
    openCalls: '2',
    bio: 'Swing trades on the majors. I post calls, not positions.',
    summary: [
      ('31 settled', VistaColors.textPrimary),
      ('17 right', VistaColors.long),
      ('14 wrong', VistaColors.short),
      ('2 open', VistaColors.textMuted),
    ],
    calls: [
      (
        VistaAssets.railRecordOpen,
        r'BTC holds $64,000 to Oct 3',
        '8d left',
        VistaColors.textMuted,
        'Market said 71% · 5.1% cushion',
      ),
      (
        VistaAssets.railRecordOpen,
        r'SOL loses $200 by Oct 10',
        '15d left',
        VistaColors.textMuted,
        'Market said 34% · 6.9% away',
      ),
      (
        VistaAssets.railRecordRight,
        r'BTC reclaims $66,000 by Tue',
        'Right at 29%',
        VistaColors.long,
        'Settled Tue 16:00',
      ),
      (
        VistaAssets.railRecordWrong,
        r'ETH reaches $3,300 by Sep 22',
        'Wrong at 38%',
        VistaColors.short,
        'Settled Sep 22',
      ),
    ],
  ),
};
