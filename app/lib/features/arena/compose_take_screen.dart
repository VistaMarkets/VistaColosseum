import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../live/market_prices.dart';
import '../portfolio/portfolio_mock.dart';
import '../trade/trade_mock.dart';
import '../calls/calls_store.dart';
import '../markets/markets_mock.dart';
import 'arena_mock.dart';
import 'battle_builder.dart';
import 'take_card.dart';

/// Writing a take, like writing a post on X: Cancel and Post on top, the
/// viewer's avatar beside the text, and under the text the position that
/// backs it, live. Pops with the new [Take] on Post.
class ComposeTakeScreen extends StatefulWidget {
  const ComposeTakeScreen({super.key, required this.position});

  final PortfolioPosition position;

  static const maxLength = 280;

  static Route<Take> route(PortfolioPosition position) =>
      MaterialPageRoute(builder: (_) => ComposeTakeScreen(position: position));

  /// The position as the order a backed take shows, in the market's own
  /// prices.
  static CallerPost backing(PortfolioPosition p) {
    final d = p.detail;
    final base = MarketPrices.base(d.symbol);
    return CallerPost(
      handle: PortfolioMock.handle,
      age: 'now',
      side: p.side,
      leverage: p.leverage,
      entryRatio: base == 0 ? 1 : d.entry / base,
      size: double.tryParse(d.size.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
      takeProfit: d.takeProfit / d.entry,
      stopLoss: d.stopLoss / d.entry,
      message: '',
    );
  }

  @override
  State<ComposeTakeScreen> createState() => _ComposeTakeScreenState();
}

class _ComposeTakeScreenState extends State<ComposeTakeScreen> {
  final _text = TextEditingController();

  /// Set while the call is also starting a battle.
  BattleSpec? _battle;

  /// Set instead when the call goes on a battle that's already live.
  LiveBattle? _joined;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// Opens the battle page; set up there, the battle rides on this call.
  Future<void> _editBattle() async {
    final p = widget.position;
    final choice = await Navigator.of(context).push(
      BattleSetupScreen.route(
        ticker: p.detail.symbol,
        side: p.side,
        initial: _battle,
      ),
    );
    if (choice == null || !mounted) return;
    setState(() {
      _battle = choice.spec;
      _joined = choice.live;
    });
  }

  bool get _canPost => _text.text.trim().isNotEmpty && (_battle?.valid ?? true);

  void _post() {
    final p = widget.position;
    final battle = _battle;
    final joined = _joined;
    HapticFeedback.lightImpact();
    // Joining a live battle: one more call on it, on this side.
    if (joined != null) {
      BattlesStore.join(joined, long: p.side == TradeSide.long);
    }
    // Starting a battle: it goes live with this call as its first.
    if (battle != null) {
      BattlesStore.add(
        battle.start(
          change: _changeOf(p.detail.symbol),
          long: p.side == TradeSide.long,
        ),
      );
    }
    Navigator.of(context).pop(
      Take(
        handle: PortfolioMock.handle,
        side: p.side,
        accuracy: '82% right',
        age: 'now',
        ticker: p.detail.symbol,
        body: _text.text.trim(),
        likes: 0,
        call: ComposeTakeScreen.backing(p),
        battle: battle?.question ?? joined?.question,
      ),
    );
  }

  /// The market's day change as the battle tiles show it ("+1.2%").
  static String _changeOf(String ticker) {
    for (final m in MarketsMock.assets) {
      if (m.id == ticker) {
        final c = m.changePct;
        return '${c >= 0 ? '+' : '−'}${c.abs().toStringAsFixed(1)}%';
      }
    }
    return '+0.0%';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.position;
    final body = VistaType.subheadMuted.copyWith(
      fontWeight: FontWeight.w400,
      color: VistaColors.textPrimary,
      height: 21 / 15,
    );
    final left = ComposeTakeScreen.maxLength - _text.text.characters.length;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Cancel · Post
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VistaSpace.gutter,
              ),
              child: SizedBox(
                height: VistaSize.tapTarget + VistaSpace.md,
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).maybePop(),
                      child: SizedBox(
                        height: VistaSize.tapTarget,
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: VistaType.subhead.copyWith(
                              color: VistaColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      enabled: _canPost,
                      label: _battle == null ? 'Post' : 'Start debate',
                      excludeSemantics: true,
                      child: VistaPressable(
                        onTap: _canPost ? _post : null,
                        child: SizedBox(
                          height: VistaSize.tapTarget,
                          child: Center(
                            child: AnimatedOpacity(
                              duration: VistaMotion.state,
                              opacity: _canPost ? 1 : 0.4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: VistaSpace.gutter + VistaSpace.xs,
                                  vertical: VistaSpace.md,
                                ),
                                decoration: BoxDecoration(
                                  color: VistaColors.accent,
                                  borderRadius: BorderRadius.circular(
                                    VistaRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  _battle == null ? 'Post' : 'Start debate',
                                  style: VistaType.subhead.copyWith(
                                    color: VistaColors.onAccent,
                                  ),
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
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  VistaSpace.gutter + VistaSpace.xs,
                  VistaSpace.md,
                  VistaSpace.gutter + VistaSpace.xs,
                  VistaSpace.gutter,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: VistaSize.avatarLarge,
                      height: VistaSize.avatarLarge,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: VistaColors.surfaceRaised,
                        shape: BoxShape.circle,
                        border: Border.all(color: p.side.color, width: 2),
                      ),
                      // The feed's initial avatar, until real avatars.
                      child: Text(
                        PortfolioMock.handle[0].toUpperCase(),
                        style: VistaType.subhead.copyWith(height: 1),
                      ),
                    ),
                    const SizedBox(width: VistaSpace.xl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Who's posting and what on, as the take will read.
                          Row(
                            children: [
                              Text(
                                PortfolioMock.handle,
                                style: VistaType.subhead,
                              ),
                              const SizedBox(width: VistaSpace.sm),
                              Text(
                                '${p.side.label.toUpperCase()} ${p.detail.symbol}',
                                style: VistaType.labelStrong.copyWith(
                                  color: p.side.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: VistaSpace.sm),
                          TextField(
                            controller: _text,
                            autofocus: true,
                            minLines: 3,
                            maxLines: null,
                            maxLength: ComposeTakeScreen.maxLength,
                            maxLengthEnforcement: MaxLengthEnforcement.enforced,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            style: body,
                            cursorColor: VistaColors.accent,
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              counterText: '',
                              hintText: "What's your call?",
                              hintStyle: body.copyWith(
                                color: VistaColors.textPlaceholder,
                              ),
                            ),
                          ),
                          const SizedBox(height: VistaSpace.xl),
                          // The position under the text, as on the posted take.
                          BackedPositionCard(
                            post: ComposeTakeScreen.backing(p),
                            ticker: p.detail.symbol,
                          ),
                          const SizedBox(height: VistaSpace.xl),
                          // A call by default; this turns it into a battle.
                          if (_battle case final b?)
                            BattleSummaryCard(
                              label: 'DEBATE',
                              question: b.question,
                              detail: b.settles,
                              onEdit: _editBattle,
                              onRemove: () => setState(() => _battle = null),
                            )
                          else if (_joined case final j?)
                            BattleSummaryCard(
                              label: 'LIVE DEBATE',
                              question: j.question,
                              detail:
                                  'Your call joins it · ${j.takes} calls · '
                                  '${j.timeLeft}',
                              onEdit: _editBattle,
                              onRemove: () => setState(() => _joined = null),
                            )
                          else
                            MakeBattleButton(onTap: _editBattle),
                          const SizedBox(height: VistaSpace.md),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$left',
                              style: VistaType.bodyMedium.copyWith(
                                color: left < 20
                                    ? VistaColors.short
                                    : VistaColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
