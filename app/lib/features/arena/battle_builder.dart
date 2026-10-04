import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../live/market_prices.dart';
import 'arena_mock.dart';

/// The statements a battle can make. Each maps to one long or short on the
/// market, so every call on it can be backed (Figma BATTLE-FLOW-TYPES).
enum BattleKind {
  closesAbove('Closes above', 'closes above a level by the deadline'),
  closesBelow('Closes below', 'closes below a level by the deadline'),
  touches('Touches', 'trades at a level any time before the deadline'),
  endsHigher('Ends higher', 'ends higher than it is now'),
  endsLower('Ends lower', 'ends lower than it is now');

  const BattleKind(this.label, this.explain);
  final String label;

  /// "ETH [explain]", for the option rows.
  final String explain;

  bool get needsLevel => this != endsHigher && this != endsLower;

  /// The statements that agree with a position's side: a long says the
  /// market goes up, a short that it goes down. First is the default.
  static List<BattleKind> forSide(TradeSide side) => side == TradeSide.long
      ? const [closesAbove, touches, endsHigher]
      : const [closesBelow, touches, endsLower];
}

/// When a battle settles: the chip's label, how the question says it, and
/// the time left (mock).
typedef BattleDeadline = ({String chip, String phrase, int minutes});

const battleDeadlines = <BattleDeadline>[
  (chip: 'Today', phrase: 'today', minutes: 480),
  (chip: 'Fri', phrase: 'Friday', minutes: 2880),
  (chip: 'End of month', phrase: 'month end', minutes: 20160),
];

/// A battle as set up: its statement, level (if it needs one) and deadline
/// on one market.
@immutable
class BattleSpec {
  const BattleSpec({
    required this.ticker,
    required this.kind,
    this.level,
    this.deadline = 1,
  });

  final String ticker;
  final BattleKind kind;
  final double? level;
  final int deadline;

  bool get valid => !kind.needsLevel || (level != null && level! > 0);

  String get _levelText =>
      level == null ? r'$…' : MarketPrices.format(level!, compact: true);

  /// The question, as the battle will read: "ETH closes above $3,200 by
  /// Friday".
  String get question {
    final by = battleDeadlines[deadline].phrase;
    return switch (kind) {
      BattleKind.closesAbove => '$ticker closes above $_levelText by $by',
      BattleKind.closesBelow => '$ticker closes below $_levelText by $by',
      BattleKind.touches => '$ticker touches $_levelText before $by',
      BattleKind.endsHigher => '$ticker ends higher than now by $by',
      BattleKind.endsLower => '$ticker ends lower than now by $by',
    };
  }

  /// What makes it right, in plain words.
  String get settles {
    final by = battleDeadlines[deadline].phrase;
    return switch (kind) {
      BattleKind.closesAbove || BattleKind.closesBelow =>
        "Settles on $ticker's mark price at the deadline ($by).",
      BattleKind.touches =>
        'Right the moment $ticker trades at $_levelText, any time before '
            '$by.',
      BattleKind.endsHigher || BattleKind.endsLower =>
        "Settles on $ticker's price at the deadline against its price now.",
    };
  }

  /// The battle this starts, with the poster's call as its first.
  LiveBattle start({required String change, required bool long}) => LiveBattle(
    ticker: ticker,
    change: change,
    question: question,
    longShare: long ? 1 : 0,
    minutesLeft: battleDeadlines[deadline].minutes,
    takes: 1,
  );
}

/// Setting up a battle, opened from the composer's "Make it a battle": the
/// statements that agree with the position's side (the first picked), a
/// typed level, a deadline and the question as it will read. Pops with the
/// [BattleSpec] on Add battle.
class BattleSetupScreen extends StatefulWidget {
  const BattleSetupScreen({
    super.key,
    required this.ticker,
    required this.side,
    this.initial,
  });

  final String ticker;
  final TradeSide side;

  /// The battle being edited, if any.
  final BattleSpec? initial;

  static Route<BattleSpec> route({
    required String ticker,
    required TradeSide side,
    BattleSpec? initial,
  }) => MaterialPageRoute(
    builder: (_) =>
        BattleSetupScreen(ticker: ticker, side: side, initial: initial),
  );

  @override
  State<BattleSetupScreen> createState() => _BattleSetupScreenState();
}

class _BattleSetupScreenState extends State<BattleSetupScreen> {
  late final _kinds = BattleKind.forSide(widget.side);
  late BattleKind _kind = widget.initial?.kind ?? _kinds.first;
  late int _deadline = widget.initial?.deadline ?? 1;
  late final _level = TextEditingController(
    text: widget.initial?.level == null
        ? ''
        : widget.initial!.level!.toStringAsFixed(
            widget.initial!.level! % 1 == 0 ? 0 : 2,
          ),
  );

  @override
  void initState() {
    super.initState();
    _level.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _level.dispose();
    super.dispose();
  }

  BattleSpec get _spec => BattleSpec(
    ticker: widget.ticker,
    kind: _kind,
    level: double.tryParse(_level.text.replaceAll(RegExp(r'[^0-9.]'), '')),
    deadline: _deadline,
  );

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    final t = widget.ticker;
    final label = VistaType.label.copyWith(
      color: VistaColors.textMuted,
      letterSpacing: 0.6,
    );
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.md,
                VistaSpace.gutter,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: VistaIconButton(
                  asset: VistaAssets.backSmall,
                  semanticLabel: 'Back',
                  iconSize: VistaSize.icon,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  VistaSpace.gutter + VistaSpace.xs,
                  VistaSpace.md,
                  VistaSpace.gutter + VistaSpace.xs,
                  VistaSpace.section,
                ),
                children: [
                  Text('Make it a battle', style: VistaType.displaySmall),
                  const SizedBox(height: VistaSpace.sm),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: "You're "),
                        TextSpan(
                          text: '${widget.side.label.toUpperCase()} $t',
                          style: TextStyle(color: widget.side.color),
                        ),
                        TextSpan(
                          text: widget.side == TradeSide.long
                              ? ', so your battle says $t goes up.'
                              : ', so your battle says $t goes down.',
                        ),
                      ],
                    ),
                    style: VistaType.subheadMuted.copyWith(
                      color: VistaColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: VistaSpace.section),
                  Text('STATEMENT', style: label),
                  const SizedBox(height: VistaSpace.md),
                  for (final k in _kinds) ...[
                    _KindRow(
                      kind: k,
                      ticker: t,
                      selected: k == _kind,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _kind = k);
                      },
                    ),
                    const SizedBox(height: VistaSpace.md),
                  ],
                  if (_kind.needsLevel) ...[
                    const SizedBox(height: VistaSpace.lg),
                    Row(
                      children: [
                        Expanded(child: Text('LEVEL', style: label)),
                        ValueListenableBuilder(
                          valueListenable: MarketPrices.of(t),
                          builder: (context, price, _) {
                            final lv = spec.level;
                            final away = lv == null || price == 0
                                ? ''
                                : ' · ${lv >= price ? '+' : '−'}'
                                      '${((lv - price) / price * 100).abs().toStringAsFixed(1)}%'
                                      ' away';
                            return Text(
                              '$t now '
                              '${MarketPrices.format(price, compact: true)}'
                              '$away',
                              style: label,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: VistaSpace.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VistaSpace.gutter,
                        vertical: VistaSpace.xl,
                      ),
                      decoration: BoxDecoration(
                        color: VistaColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Text(
                            r'$',
                            style: VistaType.displaySmall.copyWith(
                              color: VistaColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: VistaSpace.xs),
                          Expanded(
                            child: TextField(
                              controller: _level,
                              autofocus: widget.initial == null,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]'),
                                ),
                              ],
                              style: VistaType.figures(VistaType.displaySmall),
                              cursorColor: VistaColors.accent,
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: 'Type a level',
                                hintStyle: VistaType.displaySmall.copyWith(
                                  color: VistaColors.textPlaceholder,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: VistaSpace.section),
                  Text('DEADLINE', style: label),
                  const SizedBox(height: VistaSpace.md),
                  Wrap(
                    spacing: VistaSpace.md,
                    runSpacing: VistaSpace.md,
                    children: [
                      for (final (i, d) in battleDeadlines.indexed)
                        VistaFilterChip(
                          label: d.chip,
                          accent: true,
                          selected: _deadline == i,
                          onPressed: () => setState(() => _deadline = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: VistaSpace.section),
                  // The question as the battle will read.
                  Container(
                    padding: const EdgeInsets.all(VistaSpace.xxl),
                    decoration: BoxDecoration(
                      color: VistaColors.surface,
                      borderRadius: BorderRadius.circular(VistaRadius.card),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('YOUR BATTLE', style: label),
                        const SizedBox(height: VistaSpace.sm),
                        Text(spec.question, style: VistaType.tab),
                        const SizedBox(height: VistaSpace.xs),
                        Text(
                          spec.settles,
                          style: VistaType.bodyMedium.copyWith(
                            color: VistaColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                VistaSpace.md,
                VistaSpace.gutter,
                bottomInset > 0 ? bottomInset : VistaSpace.gutter,
              ),
              child: VistaPillButton(
                label: widget.initial == null ? 'Add battle' : 'Save battle',
                variant: VistaPillVariant.accent,
                onPressed: spec.valid
                    ? () => Navigator.of(context).pop(spec)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One statement option: its name and what it says about the market;
/// picked shows in the accent tint.
class _KindRow extends StatelessWidget {
  const _KindRow({
    required this.kind,
    required this.ticker,
    required this.selected,
    required this.onTap,
  });

  final BattleKind kind;
  final String ticker;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: kind.label,
      excludeSemantics: true,
      child: VistaPressable(
        scale: 0.98,
        onTap: onTap,
        child: AnimatedContainer(
          duration: VistaMotion.state,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: VistaSpace.gutter,
            vertical: VistaSpace.xl,
          ),
          decoration: BoxDecoration(
            color: selected
                ? VistaColors.accent.withValues(alpha: 0.16)
                : VistaColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kind.label,
                style: VistaType.subhead.copyWith(
                  color: selected ? VistaColors.accent : null,
                ),
              ),
              const SizedBox(height: VistaSpace.xxs),
              Text(
                '$ticker ${kind.explain}',
                style: VistaType.bodyMedium.copyWith(
                  color: VistaColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The battle on a call in the composer: the question, how it settles, and
/// Edit / Remove.
class BattleSummaryCard extends StatelessWidget {
  const BattleSummaryCard({
    super.key,
    required this.spec,
    required this.onEdit,
    required this.onRemove,
  });

  final BattleSpec spec;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    Widget action(String text, VoidCallback onTap, Color color) =>
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: VistaSize.tapTarget,
            child: Center(
              child: Text(text, style: VistaType.body.copyWith(color: color)),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(
        VistaSpace.xxl,
        VistaSpace.xs,
        VistaSpace.xxl,
        VistaSpace.xxl,
      ),
      decoration: BoxDecoration(
        color: VistaColors.surface,
        borderRadius: BorderRadius.circular(VistaRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'BATTLE',
                  style: VistaType.label.copyWith(
                    color: VistaColors.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              action('Edit', onEdit, VistaColors.accent),
              const SizedBox(width: VistaSpace.gutter),
              action('Remove', onRemove, VistaColors.textMuted),
            ],
          ),
          Text(spec.question, style: VistaType.tab),
          const SizedBox(height: VistaSpace.xs),
          Text(
            spec.settles,
            style: VistaType.bodyMedium.copyWith(color: VistaColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// "Make it a battle": under the position in the composer; opens the
/// battle setup page.
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
