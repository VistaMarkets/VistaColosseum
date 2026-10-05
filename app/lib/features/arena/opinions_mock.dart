import 'package:flutter/painting.dart';

import '../../design_system/design_system.dart';

enum OpinionSide { bull, bear }

/// One caller's case in a battle.
class Opinion {
  const Opinion({
    required this.initials,
    required this.handle,
    required this.subtitle,
    required this.side,
    required this.label,
    required this.thesis,
    required this.stats,
    this.hitRate,
  });

  final String initials;
  final String handle;

  /// Role line; the opinions screen appends the caller's accuracy, derived
  /// from their record at render time.
  final String subtitle;
  final OpinionSide side;

  /// Side label as designed ("BULL", "BEAR", "EAGLE", "WOLF").
  final String label;
  final String thesis;
  final List<VistaSideStat> stats;
  final String? hitRate;

  Color get color =>
      side == OpinionSide.bull ? VistaColors.long : VistaColors.short;
}

/// Mock content from Figma 48:430 ("13 · Clash detail — scrolled"): the
/// BTC battle's seeded opinions. Simulated.
abstract final class OpinionsMock {
  static const filters = ['All', 'Bull thesis', 'Bear thesis'];

  static const opinions = [
    Opinion(
      initials: 'RF',
      handle: '@renatafx',
      subtitle: 'sniper of charts',
      side: OpinionSide.bull,
      label: 'BULL',
      thesis:
          'The weekly open held on the retest and spot volume came with it. '
          'Every reclaim of this level with volume this year has run at least '
          "another 2%, and Friday's expiry gives it something to run into.",
      stats: [
        VistaSideStat(r'$70,900', 'Entry'),
        VistaSideStat('+4.2%', 'Live', color: VistaColors.long),
      ],
    ),
    Opinion(
      initials: 'VK',
      handle: '@voskov',
      subtitle: 'Sniper · 2 streak · Alpha 2.1',
      side: OpinionSide.bear,
      label: 'BEAR',
      thesis:
          'Funding flipped positive the moment we crossed 71k and the spot bid '
          'above it is thin enough to see through. This is leverage chasing, '
          'not demand, and leverage-led moves unwind into an expiry.',
      stats: [
        VistaSideStat(r'$71,600', 'Entry'),
        VistaSideStat('-1.8%', 'Live', color: VistaColors.short),
      ],
    ),
    Opinion(
      initials: 'ETH',
      handle: '@etherealtalker',
      subtitle: 'Contractor · 3 streak · Beta 3.0',
      side: OpinionSide.bear,
      label: 'EAGLE',
      thesis:
          'Market sentiment shifted positively as we reclaimed the 3k level, '
          'but caution remains as selling pressure could come in at '
          'resistance. Institutional interest is rising steadily.',
      stats: [
        VistaSideStat(r'$3,050', 'Entry'),
        VistaSideStat('High', 'Conviction'),
        VistaSideStat('+0.5%', 'Live', color: VistaColors.short),
      ],
    ),
    Opinion(
      initials: 'BTC',
      handle: '@bitcoinninja',
      subtitle: 'Trader · 1 streak · Gamma 1.2',
      side: OpinionSide.bear,
      label: 'WOLF',
      thesis:
          'The bullish trend is showing resilience as we hover around 60k, '
          'but profit-taking is a possibility. Watch for any signs of '
          'breakdown that might indicate a correction.',
      stats: [
        VistaSideStat(r'$59,800', 'Entry'),
        VistaSideStat('High', 'Conviction'),
        VistaSideStat('-0.2%', 'Live', color: VistaColors.short),
      ],
    ),
  ];
}
