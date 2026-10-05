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

/// Sample profile content from Figma 303:102 (maya.eth). Every profile in the
/// demo shows this content under its own handle. Simulated.
abstract final class ProfileMock {
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
