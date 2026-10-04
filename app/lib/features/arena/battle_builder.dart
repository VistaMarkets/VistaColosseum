import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../live/market_prices.dart';
import '../calls/calls_store.dart';
import 'arena_mock.dart';
import 'opinions_screen.dart';

/// The statements a battle can make. Each maps to one long or short on the
/// market, so every call on it can be backed (Figma BATTLE-FLOW-TYPES).
enum BattleKind {
  closesAbove('Closes above', 'closes above'),
  closesBelow('Closes below', 'closes below'),
  touches('Touches', 'touches'),
  staysAbove('Stays above', 'stays above'),
  staysBelow('Stays below', 'stays below'),
  endsHigher('Ends higher', 'ends higher'),
  endsLower('Ends lower', 'ends lower');

  const BattleKind(this.label, this.verb);

  /// The option chip.
  final String label;

  /// The statement's part in the sentence: "ETH [closes above] $3,200".
  final String verb;

  bool get needsLevel => this != endsHigher && this != endsLower;

  /// The statements that agree with a position's side: a long says the
  /// market goes up, a short that it goes down. First is the default.
  static List<BattleKind> forSide(TradeSide side) => side == TradeSide.long
      ? const [closesAbove, touches, staysAbove, endsHigher]
      : const [closesBelow, touches, staysBelow, endsLower];
}

/// When a battle settles: the chip's label, the sentence's part, how the
/// saved question says it, and the time left (mock).
typedef BattleDeadline = ({
  String chip,
  String part,
  String phrase,
  int minutes,
});

const battleDeadlines = <BattleDeadline>[
  (chip: 'Today', part: 'today 16:00', phrase: 'today', minutes: 480),
  (chip: 'Fri', part: 'Fri 16:00', phrase: 'Friday', minutes: 2880),
  (chip: 'next week', part: 'next Fri', phrase: 'next Friday', minutes: 12960),
  (chip: 'next month', part: 'month end', phrase: 'month end', minutes: 43200),
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

  /// The word between the level and the deadline in the sentence.
  String get joiner => switch (kind) {
    BattleKind.touches => 'before',
    BattleKind.staysAbove || BattleKind.staysBelow => 'until',
    BattleKind.endsHigher || BattleKind.endsLower => 'than now by',
    _ => 'by',
  };

  /// The question, as the battle will read: "ETH closes above $3,200 by
  /// Friday".
  String get question {
    final by = battleDeadlines[deadline].phrase;
    final lv = kind.needsLevel ? ' $_levelText' : '';
    return '$ticker ${kind.verb}$lv $joiner $by';
  }

  /// What makes it right, in plain words.
  String get settles {
    final at = battleDeadlines[deadline].part;
    return switch (kind) {
      BattleKind.closesAbove ||
      BattleKind.closesBelow => "Settles on $ticker's mark price at $at UTC.",
      BattleKind.touches =>
        'Right the moment $ticker trades at $_levelText, any time before '
            '$at UTC.',
      BattleKind.staysAbove =>
        'Wrong the moment $ticker trades below $_levelText before $at UTC.',
      BattleKind.staysBelow =>
        'Wrong the moment $ticker trades above $_levelText before $at UTC.',
      BattleKind.endsHigher || BattleKind.endsLower =>
        "Settles on $ticker's mark price at $at UTC against its price now.",
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

/// Setting up a battle (Figma 517:205), opened from the composer's "Make it
/// a battle": the statements that agree with the position's side (first
/// picked), the battle as a sentence whose parts can be tapped, a typed
/// level with shortcuts, deadline chips, a live battle like it, and the
/// side the position sets. Pops with the [BattleSpec] on Add battle.
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
    text: widget.initial?.level == null ? '' : _plain(widget.initial!.level!),
  );
  final _levelFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _level.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _level.dispose();
    _levelFocus.dispose();
    super.dispose();
  }

  bool get _long => widget.side == TradeSide.long;

  BattleSpec get _spec => BattleSpec(
    ticker: widget.ticker,
    kind: _kind,
    level: double.tryParse(_level.text.replaceAll(RegExp(r'[^0-9.]'), '')),
    deadline: _deadline,
  );

  /// A level as the field shows it: "3,200", or "1.25" under 100.
  static String _plain(double v) {
    if (v < 100) return v.toStringAsFixed(2);
    return _GroupDigits.group(v.round().toString());
  }

  /// Levels a tap fills in: the week's extreme, 5% and 10% away, and a
  /// round number past them (mock week high/low).
  List<(String, double)> _shortcuts(double price) {
    final mag = math.pow(10, (math.log(price) / math.ln10).floor()) / 2;
    if (_long) {
      return [
        (
          'Week high ${MarketPrices.format(price * 1.058, compact: true)}',
          price * 1.058,
        ),
        ('+5%', price * 1.05),
        ('+10%', price * 1.10),
        () {
          final r = (price * 1.10 / mag).ceil() * mag;
          return (MarketPrices.format(r, compact: true), r.toDouble());
        }(),
      ];
    }
    return [
      (
        'Week low ${MarketPrices.format(price * 0.945, compact: true)}',
        price * 0.945,
      ),
      ('−5%', price * 0.95),
      ('−10%', price * 0.90),
      () {
        final r = (price * 0.90 / mag).floor() * mag;
        return (MarketPrices.format(r, compact: true), r.toDouble());
      }(),
    ];
  }

  void _setLevel(double v) {
    HapticFeedback.selectionClick();
    final text = _plain(v);
    _level.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    final t = widget.ticker;
    final side = widget.side;
    final label = VistaType.label.copyWith(color: VistaColors.textMuted);
    final big = VistaType.displayMedium;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final similar = [
      for (final b in BattlesStore.all.value)
        if (b.ticker == t) b,
    ];

    Widget part(String text, Color fill, VoidCallback onTap, String hint) =>
        Semantics(
          button: true,
          label: hint,
          excludeSemantics: true,
          child: VistaPressable(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.lg,
                VistaSpace.xs,
                VistaSpace.md,
                VistaSpace.xs,
              ),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(VistaSpace.xl),
              ),
              child: Text(
                text,
                style: VistaType.figures(big)
                    .copyWith(color: VistaColors.onAccent),
              ),
            ),
          ),
        );

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
              child: Row(
                children: [
                  VistaIconButton(
                    asset: VistaAssets.backSmall,
                    semanticLabel: 'Back',
                    iconSize: VistaSize.icon,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: VistaSpace.xs),
                  Text('Make it a battle', style: VistaType.title),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  VistaSpace.gutter + VistaSpace.xs,
                  VistaSpace.gutter,
                  VistaSpace.gutter + VistaSpace.xs,
                  VistaSpace.section,
                ),
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: "You're "),
                        TextSpan(
                          text: '${side.label.toUpperCase()} $t',
                          style: TextStyle(
                            color: side.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' so it says $t goes ${_long ? 'up' : 'down'}',
                        ),
                      ],
                    ),
                    style: VistaType.subheadMuted.copyWith(
                      color: VistaColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: VistaSpace.gutter),
                  Text('STATEMENT', style: label),
                  const SizedBox(height: VistaSpace.md),
                  Wrap(
                    spacing: VistaSpace.md,
                    runSpacing: VistaSpace.md,
                    children: [
                      for (final k in _kinds)
                        VistaFilterChip(
                          label: k.label,
                          accent: true,
                          selected: k == _kind,
                          onPressed: () => setState(() => _kind = k),
                        ),
                    ],
                  ),
                  const SizedBox(height: VistaSpace.gutter),
                  // The battle as a sentence; each coloured part changes
                  // its piece: the statement, the level, the deadline.
                  Wrap(
                    spacing: VistaSpace.md,
                    runSpacing: VistaSpace.lg,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(t, style: big),
                      part(_kind.verb, side.color, () {
                        final i = _kinds.indexOf(_kind);
                        setState(() => _kind = _kinds[(i + 1) % _kinds.length]);
                      }, 'Statement: ${_kind.label}'),
                      if (_kind.needsLevel)
                        part(
                          spec.level == null
                              ? r'$…'
                              : MarketPrices.format(spec.level!, compact: true),
                          VistaColors.surfaceSelected,
                          _levelFocus.requestFocus,
                          'Level',
                        ),
                      for (final w in spec.joiner.split(' '))
                        Text(w, style: big),
                      part(
                        battleDeadlines[_deadline].part,
                        VistaColors.accent,
                        () => setState(
                          () => _deadline =
                              (_deadline + 1) % battleDeadlines.length,
                        ),
                        'Deadline: ${battleDeadlines[_deadline].chip}',
                      ),
                    ],
                  ),
                  const SizedBox(height: VistaSpace.gutter),
                  Text(
                    spec.settles,
                    style: VistaType.bodyMedium.copyWith(
                      color: VistaColors.textMuted,
                    ),
                  ),
                  if (_kind.needsLevel) ...[
                    const SizedBox(height: VistaSpace.gutter),
                    ValueListenableBuilder(
                      valueListenable: MarketPrices.of(t),
                      builder: (context, price, _) {
                        final lv = spec.level;
                        final away = lv == null || price == 0
                            ? ''
                            : ' · ${lv >= price ? '+' : '−'}'
                                  '${((lv - price) / price * 100).abs().toStringAsFixed(1)}%'
                                  ' away';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text('LEVEL', style: label)),
                                Text(
                                  '$t now '
                                  '${MarketPrices.format(price, compact: true)}'
                                  '$away',
                                  style: label,
                                ),
                              ],
                            ),
                            const SizedBox(height: VistaSpace.md),
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
                                      focusNode: _levelFocus,
                                      autofocus: widget.initial == null,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [_GroupDigits()],
                                      style: VistaType.figures(
                                        VistaType.displaySmall,
                                      ),
                                      cursorColor: VistaColors.accent,
                                      decoration: InputDecoration(
                                        isCollapsed: true,
                                        border: InputBorder.none,
                                        hintText: 'Type a level',
                                        hintStyle: VistaType.displaySmall
                                            .copyWith(
                                              color:
                                                  VistaColors.textPlaceholder,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: VistaSpace.md),
                            Wrap(
                              spacing: VistaSpace.md,
                              runSpacing: VistaSpace.md,
                              children: [
                                for (final (text, v) in _shortcuts(price))
                                  _Shortcut(
                                    text: text,
                                    onTap: () => _setLevel(v),
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: VistaSpace.gutter),
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
                  // A live battle on the same market: call on it instead.
                  if (similar.isNotEmpty) ...[
                    const SizedBox(height: VistaSpace.gutter),
                    _SimilarBattle(
                      battle: similar.first,
                      onTap: () =>
                          Navigator.of(context).push(OpinionsScreen.route()),
                    ),
                  ],
                  const SizedBox(height: VistaSpace.gutter),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VistaSpace.xl,
                      vertical: VistaSpace.sm,
                    ),
                    child: Text(
                      'Your call: ${side.label.toUpperCase()} $t',
                      style: VistaType.body.copyWith(color: side.color),
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
              child: Semantics(
                button: true,
                enabled: spec.valid,
                label: widget.initial == null ? 'Add battle' : 'Save battle',
                excludeSemantics: true,
                child: VistaPressable(
                  onTap: spec.valid
                      ? () => Navigator.of(context).pop(spec)
                      : null,
                  child: AnimatedOpacity(
                    duration: VistaMotion.state,
                    opacity: spec.valid ? 1 : 0.4,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: VistaColors.accent,
                        borderRadius: BorderRadius.circular(VistaRadius.pill),
                      ),
                      child: Text(
                        widget.initial == null ? 'Add battle' : 'Save battle',
                        style: VistaType.tab.copyWith(
                          color: VistaColors.onAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A level shortcut chip: fills the field.
class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return VistaPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VistaSpace.lg,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: VistaColors.surfaceRaised,
          borderRadius: BorderRadius.circular(VistaRadius.pill),
        ),
        child: Text(
          text,
          style: VistaType.figures(VistaType.body)
              .copyWith(color: VistaColors.textChip),
        ),
      ),
    );
  }
}

/// "A close battle is live": a live battle on the same market.
class _SimilarBattle extends StatelessWidget {
  const _SimilarBattle({required this.battle, required this.onTap});

  final LiveBattle battle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = battle.takes;
    return VistaPressable(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VistaSpace.xxl,
          vertical: VistaSpace.xl,
        ),
        decoration: BoxDecoration(
          color: VistaColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('A close battle is live', style: VistaType.body),
                  const SizedBox(height: VistaSpace.xxs),
                  Text(
                    '${battle.question} · $n ${n == 1 ? 'call' : 'calls'}',
                    style: VistaType.bodyMedium.copyWith(
                      color: VistaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: VistaSpace.xl),
            Text(
              'Call on it ›',
              style: VistaType.body.copyWith(color: VistaColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps a typed level readable: digits grouped in threes ("3,200"), one
/// decimal point.
class _GroupDigits extends TextInputFormatter {
  static String group(String digits) {
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write(',');
      b.write(digits[i]);
    }
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final dot = raw.indexOf('.');
    final whole = dot < 0 ? raw : raw.substring(0, dot);
    final frac = dot < 0 ? '' : raw.substring(dot).replaceAll('.', '');
    final text = group(whole) + (dot < 0 ? '' : '.$frac');
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
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
