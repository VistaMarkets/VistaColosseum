/// One person in a follow list. Demo data only.
class FollowPerson {
  const FollowPerson({
    required this.handle,
    required this.stats,
    required this.following,
    this.market,
    this.followsYou = false,
    this.private = false,
  });

  final String handle;
  final String stats;

  /// Their market cap, shown after the stats when they have a market.
  final String? market;
  final bool followsYou;
  final bool private;

  /// Whether the viewer follows them (initial state of the Follow button).
  final bool following;
}

/// Mock content from Figma 308:102 (Followers) and 308:244 (Following).
abstract final class FollowMock {
  static const owner = 'maya.eth';

  /// Shared with the Portfolio chips so the counts agree across screens.
  static const followerCount = '1,204';
  static const followingCount = '128';

  static const followers = [
    FollowPerson(
      handle: 'lunaq',
      stats: '118 calls   1 open',
      market: r'Market $31.5M',
      followsYou: true,
      following: true,
    ),
    FollowPerson(
      handle: '0xreal',
      stats: '240 calls',
      market: r'Market $38.2M',
      following: false,
    ),
    FollowPerson(
      handle: 'nara',
      stats: 'Private account   31 calls',
      private: true,
      followsYou: true,
      following: false,
    ),
    FollowPerson(
      handle: 'kilo.sol',
      stats: '54 calls   1 open',
      market: r'Market $17.2M',
      following: true,
    ),
    FollowPerson(
      handle: 'deltaone',
      stats: '402 calls   2 open',
      market: r'Market $26.1M',
      following: false,
    ),
    FollowPerson(
      handle: 'kestrel',
      stats: '87 calls',
      market: r'Market $19.8M',
      following: false,
    ),
    FollowPerson(handle: 'mirin', stats: '92 calls   2 open', following: true),
    FollowPerson(
      handle: 'kaito.eth',
      stats: '184 calls   1 open',
      following: false,
    ),
    FollowPerson(handle: 'sam.sol', stats: 'No calls yet', following: false),
  ];

  static const following = [
    FollowPerson(
      handle: 'kaito.eth',
      stats: '184 calls   1 open',
      following: false,
    ),
    FollowPerson(handle: 'mirin', stats: '92 calls   2 open', following: true),
    FollowPerson(
      handle: 'deltaone',
      stats: '402 calls   2 open',
      market: r'Market $26.1M',
      following: false,
    ),
    FollowPerson(
      handle: 'lunaq',
      stats: '118 calls   1 open',
      market: r'Market $31.5M',
      followsYou: true,
      following: true,
    ),
    FollowPerson(
      handle: 'nara',
      stats: 'Private account   31 calls',
      private: true,
      followsYou: true,
      following: false,
    ),
    FollowPerson(
      handle: '0xreal',
      stats: '240 calls',
      market: r'Market $38.2M',
      following: false,
    ),
    FollowPerson(handle: 'vega', stats: '12 calls', following: false),
    FollowPerson(
      handle: 'kilo.sol',
      stats: '54 calls   1 open',
      market: r'Market $17.2M',
      following: true,
    ),
    FollowPerson(
      handle: 'orbit.eth',
      stats: '7 calls   1 open',
      following: false,
    ),
  ];
}
