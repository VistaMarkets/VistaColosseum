import 'package:flutter/painting.dart';

import '../../design_system/design_system.dart';
import '../trade/trade_mock.dart';

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
    required this.call,
    this.hitRate,
  });

  final String initials;
  final String handle;
  final String subtitle;
  final OpinionSide side;

  /// Side label as designed ("BULL", "BEAR", "EAGLE", "WOLF").
  final String label;
  final String thesis;
  final List<VistaSideStat> stats;
  final String? hitRate;

  /// Their order on the battle's market, shown under the thesis like a
  /// caller's post on a trade page.
  final CallerPost call;

  Color get color =>
      side == OpinionSide.bull ? VistaColors.long : VistaColors.short;
}

/// Mock content from Figma 48:430 ("13 · Clash detail — scrolled").
/// Simulated.
abstract final class OpinionsMock {
  static const title = r'Reclaims $72,000 by Friday';
  static const asset = r'BTC $71,840';
  static const bullShare = 0.63;
  static const opinionCount = '23 opinions';
  static const filters = ['All', 'Bull thesis', 'Bear thesis'];

  static const opinions = [
    Opinion(
      initials: 'RF',
      handle: '@renatafx',
      call: CallerPost(
        handle: 'renatafx',
        age: '2h',
        side: TradeSide.long,
        leverage: 10,
        entryRatio: 0.986,
        size: 4200,
        takeProfit: 1.045,
        stopLoss: 0.985,
        message: '',
      ),
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
      call: CallerPost(
        handle: 'voskov',
        age: '3h',
        side: TradeSide.short,
        leverage: 5,
        entryRatio: 0.997,
        size: 2800,
        takeProfit: 0.96,
        stopLoss: 1.018,
        message: '',
      ),
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
      call: CallerPost(
        handle: 'etherealtalker',
        age: '5h',
        side: TradeSide.short,
        leverage: 3,
        entryRatio: 1.004,
        size: 1500,
        takeProfit: 0.97,
        stopLoss: 1.02,
        message: '',
      ),
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
      call: CallerPost(
        handle: 'bitcoinninja',
        age: '6h',
        side: TradeSide.short,
        leverage: 2,
        entryRatio: 1.002,
        size: 900,
        takeProfit: 0.975,
        stopLoss: 1.015,
        message: '',
      ),
      subtitle: 'Trader · 1 streak · Gamma 1.2',
      side: OpinionSide.bear,
      label: 'WOLF',
      hitRate: '80%',
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
