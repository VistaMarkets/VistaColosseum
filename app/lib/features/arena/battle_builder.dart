import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../live/market_prices.dart';
import '../calls/calls_store.dart';
import 'arena_mock.dart';
import 'take_card.dart';

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

/// A level as a price: whole dollars from $100 up ("$200", "$3,200"),
/// cents below.
String battleLevel(double v) => v >= 100
    ? '\$${_GroupDigits.group(v.round().toString())}'
    : MarketPrices.format(v, compact: true);

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

  String get _levelText => level == null ? r'$…' : battleLevel(level!);

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

/// What the battle page hands back: a new battle to start, or a live one
/// on the same market to put the call on instead.
@immutable
class BattleChoice {
  const BattleChoice.start(BattleSpec this.spec) : live = null;
  const BattleChoice.join(LiveBattle this.live) : spec = null;

  final BattleSpec? spec;
  final LiveBattle? live;
}

/// Setting up a battle (Figma 517:205), opened from the composer's "Make it
/// a battle": the statements that agree with the position's side (first
/// picked) in one scrolling line, the battle as a sentence, a typed level
/// with shortcuts, deadline chips, and the side the position sets. Add
/// battle first offers any live battles on the same market; pops with a
/// [BattleChoice]. Pops with the [BattleSpec] on Add battle.
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

  static Route<BattleChoice> route({
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
        ('Week high ${battleLevel(price * 1.058)}', price * 1.058),
        ('+5%', price * 1.05),
        ('+10%', price * 1.10),
        () {
          final r = (price * 1.10 / mag).ceil() * mag;
          return (battleLevel(r.toDouble()), r.toDouble());
        }(),
      ];
    }
    return [
      ('Week low ${battleLevel(price * 0.945)}', price * 0.945),
      ('−5%', price * 0.95),
      ('−10%', price * 0.90),
      () {
        final r = (price * 0.90 / mag).floor() * mag;
        return (battleLevel(r.toDouble()), r.toDouble());
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

  /// Add battle: if battles on this market are already live, offer them
  /// first so the call can join one instead of starting a near-copy.
  Future<void> _add(BattleSpec spec) async {
    final live = [
      for (final b in BattlesStore.all.value)
        if (b.ticker == widget.ticker) b,
    ];
    if (live.isEmpty) {
      Navigator.of(context).pop(BattleChoice.start(spec));
      return;
    }
    final choice = await showVistaSheet<BattleChoice>(
      context,
      color: VistaColors.background,
      builder: (_) =>
          _LiveBattlesSheet(ticker: widget.ticker, battles: live, spec: spec),
    );
    if (choice != null && mounted) Navigator.of(context).pop(choice);
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    final t = widget.ticker;
    final side = widget.side;
    final label = VistaType.label.copyWith(color: VistaColors.textMuted);
    final big = VistaType.displayMedium;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Widget part(String text, Color fill, VoidCallback? onTap, String hint) =>
        Semantics(
          button: onTap != null,
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
                  Text('Make it a debate', style: VistaType.title),
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
                  // One line that scrolls sideways, out to the screen edge.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        for (final (i, k) in _kinds.indexed) ...[
                          if (i > 0) const SizedBox(width: VistaSpace.md),
                          VistaFilterChip(
                            label: k.label,
                            accent: true,
                            selected: k == _kind,
                            onPressed: () => setState(() => _kind = k),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: VistaSpace.gutter),
                  // The battle as a sentence; the level and deadline parts
                  // can be tapped to change them.
                  Wrap(
                    spacing: VistaSpace.md,
                    runSpacing: VistaSpace.lg,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(t, style: big),
                      // Set by the chips above; not a button itself.
                      part(_kind.verb, side.color, null, _kind.label),
                      if (_kind.needsLevel)
                        part(
                          spec.level == null ? r'$…' : battleLevel(spec.level!),
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
                label: widget.initial == null ? 'Add debate' : 'Save debate',
                excludeSemantics: true,
                child: VistaPressable(
                  onTap: spec.valid ? () => _add(spec) : null,
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
                        widget.initial == null ? 'Add debate' : 'Save debate',
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

/// After Add battle, when the market already has live battles: tap one to
/// put the call on it, or start the new battle anyway.
class _LiveBattlesSheet extends StatelessWidget {
  const _LiveBattlesSheet({
    required this.ticker,
    required this.battles,
    required this.spec,
  });

  final String ticker;
  final List<LiveBattle> battles;
  final BattleSpec spec;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom > 0 ? bottom : VistaSpace.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VistaSpace.gutter + VistaSpace.xs,
              VistaSpace.lg,
              VistaSpace.gutter + VistaSpace.xs,
              VistaSpace.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$ticker debates already live', style: VistaType.title),
                const SizedBox(height: VistaSpace.xs),
                Text(
                  'Put your call on one of these, or start yours anyway.',
                  style: VistaType.subheadMuted.copyWith(
                    color: VistaColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final b in battles)
                  BattleTile.row(
                    battle: b,
                    onTap: () =>
                        Navigator.of(context).pop(BattleChoice.join(b)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VistaSpace.gutter,
              VistaSpace.gutter,
              VistaSpace.gutter,
              0,
            ),
            child: VistaPillButton(
              label: 'Start my debate anyway',
              onPressed: () =>
                  Navigator.of(context).pop(BattleChoice.start(spec)),
            ),
          ),
        ],
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
    required this.label,
    required this.question,
    required this.detail,
    required this.onEdit,
    required this.onRemove,
  });

  /// "BATTLE" for a new one, "LIVE BATTLE" when joining one.
  final String label;
  final String question;

  /// How it settles, or what joining it means.
  final String detail;
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
                  label,
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
          Text(question, style: VistaType.tab),
          const SizedBox(height: VistaSpace.xs),
          Text(
            detail,
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
      label: 'Make it a debate',
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
                    Text('Make it a debate', style: VistaType.subhead),
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
