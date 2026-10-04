import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../live/market_prices.dart';
import 'arena_mock.dart';

/// The statements a battle can make. Only the ones whose sides map to a
/// single long or short on the market, so every call on them can be backed
/// (Figma BATTLE-FLOW-TYPES).
enum BattleKind {
  closesAbove('Closes above'),
  closesBelow('Closes below'),
  touches('Touches'),
  endsHigher('Ends higher');

  const BattleKind(this.label);
  final String label;

  bool get needsLevel => this != BattleKind.endsHigher;
}

/// When a battle settles: the chip's label, how the question says it, and
/// the time left (mock).
typedef BattleDeadline = ({String chip, String phrase, int minutes});

const battleDeadlines = <BattleDeadline>[
  (chip: 'Today', phrase: 'today', minutes: 480),
  (chip: 'Fri', phrase: 'Friday', minutes: 2880),
  (chip: 'End of month', phrase: 'month end', minutes: 20160),
];

/// A battle being written in the composer: its statement, a typed level and
/// a deadline, for one market.
class BattleDraft extends ChangeNotifier {
  BattleDraft(this.ticker);

  final String ticker;
  final level = TextEditingController();

  BattleKind _kind = BattleKind.closesAbove;
  int _deadline = 1;

  BattleKind get kind => _kind;
  set kind(BattleKind k) {
    _kind = k;
    notifyListeners();
  }

  int get deadline => _deadline;
  set deadline(int i) {
    _deadline = i;
    notifyListeners();
  }

  /// The typed level, or null when there isn't a usable one.
  double? get levelValue {
    final v = double.tryParse(level.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    return v == null || v <= 0 ? null : v;
  }

  bool get valid => !_kind.needsLevel || levelValue != null;

  String get _levelText => levelValue == null
      ? r'$…'
      : MarketPrices.format(levelValue!, compact: true);

  /// The question, as the battle will read: "ETH closes above $3,200 by
  /// Friday".
  String get question {
    final by = battleDeadlines[_deadline].phrase;
    return switch (_kind) {
      BattleKind.closesAbove => '$ticker closes above $_levelText by $by',
      BattleKind.closesBelow => '$ticker closes below $_levelText by $by',
      BattleKind.touches => '$ticker touches $_levelText before $by',
      BattleKind.endsHigher => '$ticker ends higher than now by $by',
    };
  }

  /// What makes it right, in plain words.
  String get settles {
    final by = battleDeadlines[_deadline].phrase;
    return switch (_kind) {
      BattleKind.closesAbove || BattleKind.closesBelow =>
        "Settles on $ticker's mark price at the deadline ($by).",
      BattleKind.touches =>
        'Right the moment $ticker trades at $_levelText, any time before '
            '$by.',
      BattleKind.endsHigher =>
        "Right if $ticker's price at the deadline beats its price now.",
    };
  }

  /// The battle this draft starts, with the poster's call as its first.
  LiveBattle start({required String change, required bool long}) => LiveBattle(
    ticker: ticker,
    change: change,
    question: question,
    longShare: long ? 1 : 0,
    minutesLeft: battleDeadlines[_deadline].minutes,
    takes: 1,
  );

  @override
  void dispose() {
    level.dispose();
    super.dispose();
  }
}

/// The battle half of the composer: statement chips, the question as it
/// will read, a typed level, deadline chips and how it settles.
class BattleBuilder extends StatelessWidget {
  const BattleBuilder({super.key, required this.draft, required this.onRemove});

  final BattleDraft draft;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([draft, draft.level]),
      builder: (context, _) {
        final d = draft;
        final label = VistaType.label.copyWith(
          color: VistaColors.textMuted,
          letterSpacing: 0.6,
        );
        return Container(
          padding: const EdgeInsets.all(VistaSpace.xxl),
          decoration: BoxDecoration(
            color: VistaColors.surface,
            borderRadius: BorderRadius.circular(VistaRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('BATTLE', style: label)),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onRemove,
                    child: Padding(
                      padding: const EdgeInsets.all(VistaSpace.xs),
                      child: Text(
                        'Remove',
                        style: VistaType.body.copyWith(
                          color: VistaColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VistaSpace.md),
              Wrap(
                spacing: VistaSpace.md,
                runSpacing: VistaSpace.md,
                children: [
                  for (final k in BattleKind.values)
                    VistaFilterChip(
                      label: k.label,
                      accent: true,
                      selected: d.kind == k,
                      onPressed: () => d.kind = k,
                    ),
                ],
              ),
              const SizedBox(height: VistaSpace.xl),
              Text(d.question, style: VistaType.tab),
              const SizedBox(height: VistaSpace.xs),
              Text(
                d.settles,
                style: VistaType.bodyMedium.copyWith(
                  color: VistaColors.textMuted,
                ),
              ),
              if (d.kind.needsLevel) ...[
                const SizedBox(height: VistaSpace.xl),
                Row(
                  children: [
                    Expanded(child: Text('LEVEL', style: label)),
                    ValueListenableBuilder(
                      valueListenable: MarketPrices.of(d.ticker),
                      builder: (context, price, _) => Text(
                        '${d.ticker} now '
                        '${MarketPrices.format(price, compact: true)}',
                        style: label,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VistaSpace.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VistaSpace.xl,
                    vertical: VistaSpace.lg,
                  ),
                  decoration: BoxDecoration(
                    color: VistaColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(VistaSpace.xl),
                  ),
                  child: Row(
                    children: [
                      Text(
                        r'$',
                        style: VistaType.headline.copyWith(
                          color: VistaColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: VistaSpace.xs),
                      Expanded(
                        child: TextField(
                          controller: d.level,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          style: VistaType.figures(VistaType.headline),
                          cursorColor: VistaColors.accent,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Type a level',
                            hintStyle: VistaType.headline.copyWith(
                              color: VistaColors.textPlaceholder,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: VistaSpace.xl),
              Text('DEADLINE', style: label),
              const SizedBox(height: VistaSpace.sm),
              Wrap(
                spacing: VistaSpace.md,
                runSpacing: VistaSpace.md,
                children: [
                  for (final (i, dl) in battleDeadlines.indexed)
                    VistaFilterChip(
                      label: dl.chip,
                      accent: true,
                      selected: d.deadline == i,
                      onPressed: () => d.deadline = i,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "Make it a battle": the closed state of the builder, under the position.
class MakeBattleButton extends StatelessWidget {
  const MakeBattleButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Make it a battle',
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.98,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: VistaSpace.xl,
            vertical: VistaSpace.lg,
          ),
          decoration: BoxDecoration(
            color: VistaColors.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: VistaColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'VS',
                  style: VistaType.labelStrong.copyWith(
                    color: VistaColors.onAccent,
                  ),
                ),
              ),
              const SizedBox(width: VistaSpace.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Make it a battle', style: VistaType.subhead),
                    const SizedBox(height: VistaSpace.xxs),
                    Text(
                      'Ask a yes/no question others can call on',
                      style: VistaType.bodyMedium.copyWith(
                        color: VistaColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '›',
                style: VistaType.tab.copyWith(color: VistaColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
