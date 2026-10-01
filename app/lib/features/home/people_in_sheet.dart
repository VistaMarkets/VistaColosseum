import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../profile/profile_screen.dart';
import 'mock_trade_idea.dart';

/// Opens "who's in" for [idea]: the rail's people-in count, opened. The
/// latest people to join the call, as the app's people rows, with sizes kept
/// private. Simulated from a steady per-call seed.
Future<void> showPeopleInSheet(BuildContext context, TradeIdea idea) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x73000000),
    builder: (_) => PeopleInSheet(idea: idea),
  );
}

class PeopleInSheet extends StatelessWidget {
  const PeopleInSheet({super.key, required this.idea});

  final TradeIdea idea;

  static const _handles = [
    'kaito.eth', '0xreal', 'kilo.sol', 'nara', 'maya.eth', //
    'lunaq', 'deltaone', 'kestrel', 'vega.eth', 'orbit',
  ];

  int get _seed => '${idea.callerHandle}/${idea.ticker}'.codeUnits.fold<int>(
    5,
    (a, c) => (a * 31 + c) & 0xffff,
  );

  /// The latest people in, newest first: mostly with the caller.
  List<(String, TradeSide, String)> get _people {
    final others = _handles.where((h) => h != idea.callerHandle).toList();
    const ages = [
      'Just now', '1m ago', '3m ago', '6m ago', '12m ago', //
      '25m ago', '41m ago', '1h ago',
    ];
    return [
      for (var n = 0; n < ages.length; n++)
        (
          others[(n + _seed) % others.length],
          (n * 7 + _seed) % 10 < 7 ? idea.side : _opposite(idea.side),
          ages[n],
        ),
    ];
  }

  static TradeSide _opposite(TradeSide s) =>
      s == TradeSide.long ? TradeSide.short : TradeSide.long;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;
    final people = _people;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: Container(
        // The page colour, as the people lists and position sheet use:
        // avatars would sink into the raised surface.
        decoration: const BoxDecoration(
          color: VistaColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(0, 10, 0, 16 + safe),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: VistaDragHandle()),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VistaSpace.gutter,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${idea.traders} in',
                            style: VistaType.subhead.copyWith(fontSize: 20),
                          ),
                        ),
                        Semantics(
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).pop(),
                            child: Text(
                              'Done',
                              style: VistaType.subhead.copyWith(
                                color: VistaColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VistaSpace.xxs),
                    Text(
                      "People in ${idea.callerHandle}'s ${idea.ticker} call",
                      style: VistaType.chip.copyWith(
                        fontWeight: FontWeight.w500,
                        color: VistaColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    VistaSectionHead(
                      title: 'LATEST IN',
                      note: 'Sizes stay private',
                    ),
                  ],
                ),
              ),
              for (final (i, (handle, side, age)) in people.indexed) ...[
                if (i > 0) const VistaListDivider(),
                VistaPersonRow(
                  name: handle,
                  stats: age,
                  onPressed: () =>
                      Navigator.of(context).push(ProfileScreen.route(handle)),
                  trailing: VistaSideBadge(side: side),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
