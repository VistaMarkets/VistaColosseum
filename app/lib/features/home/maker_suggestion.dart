import 'package:flutter/widgets.dart';

import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../trade/trade_mock.dart';

/// A Maker-style trade suggestion: advisory only, timed on the demo clock
/// (`Scenario.clock`) and built from the demo prices. Demo data, never an
/// order: viewing one changes nothing.
class Suggestion {
  const Suggestion({
    required this.asset,
    required this.direction,
    required this.rationale,
    required this.expiresAt,
    this.source = 'Maker · demo recommendation',
  });

  /// An asset ticker with a demo quote.
  final String asset;
  final TradeSide direction;

  /// Why, in two lines.
  final String rationale;

  /// When it stops being tradable, on the demo clock.
  final DateTime expiresAt;
  final String source;

  /// The demo quote it was built from.
  String get referencePrice => TradeMock.quotes[asset]!.price;

  bool liveAt(DateTime now) => now.isBefore(expiresAt);
}

/// The two seeded suggestions: one live, one already expired when the demo
/// clock starts (at [TradeMock.chartEnd]).
final makerSuggestions = [
  Suggestion(
    asset: 'SOL',
    direction: TradeSide.long,
    rationale:
        "SOL leads the majors in today's demo prices.\n"
        'Maker favours a long while that lead holds.',
    expiresAt: TradeMock.chartEnd.add(const Duration(hours: 4)),
  ),
  Suggestion(
    asset: 'ETH',
    direction: TradeSide.short,
    rationale:
        'ETH lagged BTC through the demo session.\n'
        'Maker favoured a short into the close.',
    expiresAt: TradeMock.chartEnd.subtract(const Duration(hours: 2)),
  ),
];

/// A suggestion as a Home feed card, set apart from the idea cards by its
/// accent outline and advisory badge. It reads the demo clock and nothing
/// else from the store; Trade this only opens the ticket.
class MakerSuggestionCard extends StatelessWidget {
  const MakerSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onTrade,
  });

  final Suggestion suggestion;

  /// Opens the order ticket; not offered once the suggestion has expired.
  final VoidCallback onTrade;

  static String _span(Duration d) =>
      d.inHours > 0 ? '${d.inHours}h' : '${d.inMinutes}m';

  @override
  Widget build(BuildContext context) {
    final s = suggestion;
    return ValueListenableBuilder<DateTime>(
      valueListenable: Scenario.clock,
      builder: (context, now, _) {
        final live = s.liveAt(now);
        final left = s.expiresAt.difference(now);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
          padding: const EdgeInsets.all(VistaSpace.gutter),
          decoration: BoxDecoration(
            color: VistaColors.surface,
            borderRadius: BorderRadius.circular(VistaRadius.card),
            border: Border.all(color: VistaColors.accent),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VistaTag(
                label: 'Maker suggestion · advisory',
                color: VistaColors.accentTint,
                textColor: VistaColors.accent,
              ),
              const SizedBox(height: VistaSpace.xl),
              Row(
                children: [
                  Text(s.asset, style: VistaType.title),
                  const SizedBox(width: VistaSpace.sm),
                  VistaSideBadge(side: s.direction),
                ],
              ),
              const SizedBox(height: VistaSpace.md),
              Text(s.rationale, style: VistaType.body),
              const SizedBox(height: VistaSpace.xl),
              Text(
                'Reference ${s.referencePrice} · '
                '${live ? 'expires in ${_span(left)}' : 'expired ${_span(-left)} ago'}',
                style: VistaType.meta,
              ),
              const SizedBox(height: VistaSpace.xs),
              Text(s.source, style: VistaType.meta),
              Text('Built from Aggro demo prices', style: VistaType.meta),
              const SizedBox(height: VistaSpace.gutter),
              // Its own node: merged with the texts above, the whole card
              // would read as one (disabled) button.
              Semantics(
                container: true,
                child: VistaPrimaryButton(
                  label: live ? 'Trade this' : 'Expired',
                  enabled: live,
                  onPressed: onTrade,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
