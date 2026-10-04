import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../live/market_prices.dart';
import '../portfolio/portfolio_mock.dart';
import '../trade/trade_mock.dart';
import 'arena_mock.dart';
import 'take_card.dart';

/// Takes the viewer posted this session, newest first. In memory only: the
/// demo sends nothing.
abstract final class PostedTakes {
  static final posted = ValueNotifier<List<Take>>(const []);

  static void add(Take t) =>
      posted.value = List.unmodifiable([t, ...posted.value]);

  static void reset() => posted.value = const [];
}

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

  bool get _canPost => _text.text.trim().isNotEmpty;

  void _post() {
    final p = widget.position;
    HapticFeedback.lightImpact();
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
      ),
    );
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
                      label: 'Post',
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
                                  'Post',
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
                      decoration: BoxDecoration(
                        color: VistaColors.surfaceRaised,
                        shape: BoxShape.circle,
                        border: Border.all(color: p.side.color, width: 2),
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
                              hintText: "What's your take?",
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
