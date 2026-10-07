import 'package:flutter/painting.dart';

import '../../design_system/design_system.dart';

/// A rank tier, from the season's settled calls.
enum Tier {
  diamond('Diamond', Color(0xFF8AD8FF)),
  gold('Gold', Color(0xFFF2B35A)),
  silver('Silver', Color(0xFFC9CED6)),
  bronze('Bronze', Color(0xFFC98A5A));

  const Tier(this.label, this.color);

  final String label;
  final Color color;
}

/// A trader's standing this season: tier and division ("Gold II"), right
/// calls in a row, the week's P/L and season points.
class Standing {
  const Standing(
    this.handle,
    this.tier,
    this.division, {
    required this.streak,
    required this.weekPct,
    required this.points,
  });

  final String handle;
  final Tier tier;

  /// I, II or III; empty for Diamond.
  final String division;
  final int streak;

  /// Return on settled calls this week.
  final double weekPct;

  /// Season points (XP) — what the season leaderboard orders by.
  final int points;

  String get rank => division.isEmpty ? tier.label : '${tier.label} $division';
}

/// A daily quest on the season strip.
class Quest {
  const Quest(this.label, this.xp, {this.done = false});

  final String label;
  final int xp;
  final bool done;
}

/// The Arena's game layer: tiers, streaks, seasons, quests. Mock: the
/// backend's season service replaces it.
abstract final class GameMock {
  static const season = 'Season 3';
  static const seasonEndsIn = '5d';

  /// The viewer's XP toward the next division.
  static const xp = 340;
  static const xpToNext = 500;
  static const nextRank = 'Gold I';

  static const quests = [
    Quest('Make a call', 20, done: true),
    Quest('Win a battle', 50),
    Quest('Get 5 joins', 30),
  ];

  static const standings = [
    Standing(
      'renatafx',
      Tier.diamond,
      '',
      streak: 6,
      weekPct: 41.2,
      points: 9840,
    ),
    Standing(
      'deltaone',
      Tier.diamond,
      '',
      streak: 3,
      weekPct: 28.7,
      points: 9310,
    ),
    Standing(
      'kaito.eth',
      Tier.gold,
      'I',
      streak: 2,
      weekPct: 22.4,
      points: 7120,
    ),
    Standing('voskov', Tier.gold, 'I', streak: 2, weekPct: 19.9, points: 6980),
    Standing('0xreal', Tier.gold, 'II', streak: 1, weekPct: 15.3, points: 6410),
    Standing(
      'maya.eth',
      Tier.gold,
      'II',
      streak: 4,
      weekPct: 17.3,
      points: 5340,
    ),
    Standing(
      'orbit.eth',
      Tier.gold,
      'III',
      streak: 0,
      weekPct: 9.8,
      points: 4980,
    ),
    Standing(
      'kilo.sol',
      Tier.silver,
      'I',
      streak: 1,
      weekPct: 8.1,
      points: 3920,
    ),
    Standing('mirin', Tier.silver, 'I', streak: 0, weekPct: 4.4, points: 3710),
    Standing(
      'lunaq',
      Tier.silver,
      'II',
      streak: 0,
      weekPct: -2.6,
      points: 3220,
    ),
    Standing('nara', Tier.silver, 'III', streak: 2, weekPct: 6.2, points: 2890),
    Standing(
      'kestrel',
      Tier.bronze,
      'I',
      streak: 0,
      weekPct: -7.9,
      points: 1650,
    ),
    Standing('vega', Tier.bronze, 'I', streak: 1, weekPct: 3.1, points: 420),
  ];

  static Standing? of(String handle) {
    for (final s in standings) {
      if (s.handle == handle) return s;
    }
    return null;
  }

  /// By the week's return, or by season points.
  static List<Standing> ranked({required bool season}) {
    final list = [...standings];
    list.sort(
      (a, b) => season
          ? b.points.compareTo(a.points)
          : b.weekPct.compareTo(a.weekPct),
    );
    return list;
  }

  /// [handle]'s place on the leaderboard, from 1.
  static int placeOf(String handle, {required bool season}) =>
      ranked(season: season).indexWhere((s) => s.handle == handle) + 1;

  static Color tierColor(String handle) =>
      of(handle)?.tier.color ?? VistaColors.surfaceRaised;
}
