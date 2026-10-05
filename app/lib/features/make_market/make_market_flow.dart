import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/design_system.dart';
import '../account/account_state.dart';
import '../market/market_mock.dart';
import 'confetti_burst.dart';
import 'make_market_mock.dart';

/// Make a market: create (Figma 338:102) → before you list (329:102) →
/// live (348:624). Creating lists the market on [AccountState]; nothing is
/// actually listed, minted or signed.
class MakeMarketFlow extends StatefulWidget {
  const MakeMarketFlow({super.key});

  static Route<void> route() => MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => const MakeMarketFlow(),
  );

  @override
  State<MakeMarketFlow> createState() => _MakeMarketFlowState();
}

enum _Step { create, consent, live }

class _MakeMarketFlowState extends State<MakeMarketFlow> {
  _Step _step = _Step.create;
  final _ticker = TextEditingController(text: AccountState.ticker.value);
  final _pitch = TextEditingController(text: MakeMarketMock.defaultPitch);
  final _agreed = List<bool>.filled(MakeMarketMock.consents.length + 1, false);

  @override
  void initState() {
    super.initState();
    _ticker.addListener(() => setState(() {}));
    _pitch.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pitch.dispose();
    super.dispose();
  }

  String get _symbol => _ticker.text;
  bool get _taken => MakeMarketMock.taken.contains(_symbol);
  bool get _tickerOk => _symbol.length >= 2 && !_taken;

  void _notBuilt(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what — not in the demo yet')));
  }

  void _create() {
    // Simulated: records the market in app state only.
    AccountState.listMarket(_symbol);
    setState(() => _step = _Step.live);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step != _Step.consent,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step = _Step.create);
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: switch (_step) {
            _Step.create => _createStep(),
            _Step.consent => _consentStep(),
            _Step.live => _liveStep(),
          },
        ),
      ),
    );
  }

  // ─── Shared pieces ────────────────────────────────────────────────────

  Widget _topBar({
    required String title,
    required bool close,
    required VoidCallback onLeading,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VistaSpace.xs),
      child: Row(
        children: [
          close
              ? VistaGlyphButton(
                  glyph: '×',
                  size: 17,
                  semanticLabel: 'Close',
                  onPressed: onLeading,
                )
              : VistaIconButton(
                  asset: VistaAssets.back,
                  semanticLabel: 'Back',
                  iconSize: VistaSize.icon,
                  onPressed: onLeading,
                ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: VistaType.tab,
            ),
          ),
          const SizedBox.square(dimension: VistaSize.tapTarget),
        ],
      ),
    );
  }

  Widget _footer(List<Widget> children) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        VistaSpace.gutter,
        VistaSpace.md,
        VistaSpace.gutter,
        bottomInset > 0 ? bottomInset : 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  // ─── 1 · Create ───────────────────────────────────────────────────────

  Widget _createStep() {
    const gap = SizedBox(height: VistaSpace.xxl);
    return SafeArea(
      key: const ValueKey(_Step.create),
      bottom: false,
      child: Column(
        children: [
          _topBar(
            title: 'Make a market',
            close: true,
            onLeading: () => Navigator.of(context).maybePop(),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 10),
            child: VistaStepDots(count: 3, index: 0),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                horizontal: VistaSpace.gutter,
              ),
              children: [
                _previewCard(),
                gap,
                _tickerField(),
                gap,
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: VistaColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Name',
                        style: VistaType.bodyMedium.copyWith(
                          color: VistaColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(MakeMarketMock.name, style: VistaType.subhead),
                    ],
                  ),
                ),
                gap,
                _pitchField(),
                gap,
              ],
            ),
          ),
          _footer([
            Text(
              'Free to create · nothing is minted',
              textAlign: TextAlign.center,
              style: VistaType.chip.copyWith(
                fontWeight: FontWeight.w500,
                color: VistaColors.textSecondary,
              ),
            ),
            const SizedBox(height: VistaSpace.lg),
            VistaPrimaryButton(
              label: 'Continue with \$$_symbol',
              trailing: '→',
              glow: true,
              enabled: _tickerOk,
              onPressed: () {
                FocusScope.of(context).unfocus();
                setState(() => _step = _Step.consent);
              },
            ),
          ]),
        ],
      ),
    );
  }

  /// Live preview of the market card: lattice, sample chart, the market
  /// image, ticker and pitch, updating as the fields change.
  Widget _previewCard() {
    final initial = _symbol.isEmpty ? '?' : _symbol[0];
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 236,
        color: VistaColors.surface,
        child: Stack(
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                VistaAssets.mmCardLattice,
                fit: BoxFit.fill,
              ),
            ),
            Positioned.fill(
              child: SvgPicture.asset(
                VistaAssets.mmPreviewChart,
                fit: BoxFit.fill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(VistaSpace.gutter),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC161616),
                        borderRadius: BorderRadius.circular(VistaRadius.pill),
                      ),
                      child: Text(
                        'New',
                        style: VistaType.micro.copyWith(
                          color: VistaColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: VistaSpace.md),
                  _marketImage(initial),
                  const SizedBox(height: VistaSpace.md),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '\$$_symbol',
                      style: VistaType.display.copyWith(letterSpacing: -1),
                    ),
                  ),
                  const SizedBox(height: VistaSpace.md),
                  SizedBox(
                    width: 300,
                    child: Text(
                      _pitch.text,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: VistaType.body.copyWith(
                        color: VistaColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 80pt market image with its green ring (glow drawn here: the export's
  /// SVG filter doesn't render) and the add-image button.
  Widget _marketImage(String initial) {
    return SizedBox.square(
      dimension: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 1,
            top: 1,
            width: 78,
            height: 78,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x805AA6DE), blurRadius: 16),
                ],
              ),
            ),
          ),
          const Positioned(
            left: -16,
            top: -16,
            child: VistaIcon(VistaAssets.mmImageGlow, size: 112),
          ),
          const Positioned(
            left: 5,
            top: 5,
            child: VistaIcon(VistaAssets.mmImageInner, size: 70),
          ),
          Center(
            child: Text(
              initial,
              style: VistaType.display.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: VistaColors.textPrimary.withValues(alpha: 0.85),
              ),
            ),
          ),
          Positioned(
            left: 46.28,
            top: 46.28,
            child: Semantics(
              button: true,
              label: 'Change market image',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => _notBuilt('Market image'),
                child: const VistaIcon(VistaAssets.mmAddImage, size: 44),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tickerField() {
    final (status, statusColor) = _symbol.length < 2
        ? ('2–8 letters', VistaColors.textSecondary)
        : _taken
        ? ('× Taken', VistaColors.short)
        : ('✓ Available', VistaColors.long);
    final big = VistaType.displayNumber.copyWith(fontSize: 22);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Ticker', style: VistaType.body),
            const Spacer(),
            Text(status, style: VistaType.chip.copyWith(color: statusColor)),
          ],
        ),
        const SizedBox(height: VistaSpace.md),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
          decoration: BoxDecoration(
            color: VistaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _taken ? VistaColors.short : VistaColors.accent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Text('\$', style: big.copyWith(color: VistaColors.accent)),
              const SizedBox(width: VistaSpace.xxs),
              Expanded(
                child: TextField(
                  controller: _ticker,
                  style: big,
                  cursorColor: VistaColors.accent,
                  cursorWidth: 2,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(MakeMarketMock.maxTicker),
                    TextInputFormatter.withFunction(
                      (_, v) => v.copyWith(text: v.text.toUpperCase()),
                    ),
                  ],
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              Text(
                '${_symbol.length}/${MakeMarketMock.maxTicker}',
                style: VistaType.chip.copyWith(
                  color: VistaColors.textSecondary,
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
            for (final s in MakeMarketMock.suggestions)
              Semantics(
                button: true,
                selected: s == _symbol,
                label: 'Use \$$s',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _ticker.text = s,
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 10),

                    decoration: BoxDecoration(
                      color: s == _symbol
                          ? VistaColors.textPrimary
                          : VistaColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(VistaRadius.pill),
                    ),
                    // Centre the label without filling the Wrap's width.
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        '\$$s',
                        style: VistaType.chip.copyWith(
                          fontWeight: FontWeight.w700,
                          color: s == _symbol
                              ? VistaColors.ink
                              : VistaColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _pitchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: VistaColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'One-line pitch',
                style: VistaType.chip.copyWith(
                  fontWeight: FontWeight.w500,
                  color: VistaColors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                '${_pitch.text.length}/${MakeMarketMock.maxPitch}',
                style: VistaType.label.copyWith(
                  fontWeight: FontWeight.w500,
                  color: VistaColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: VistaSpace.xs),
          TextField(
            controller: _pitch,
            maxLines: null,
            style: VistaType.subhead.copyWith(fontWeight: FontWeight.w500),
            cursorColor: VistaColors.accent,
            inputFormatters: [
              LengthLimitingTextInputFormatter(MakeMarketMock.maxPitch),
            ],
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2 · Before you list ──────────────────────────────────────────────

  Widget _consentStep() {
    final t = '\$$_symbol';
    final muted = VistaType.bodyMedium.copyWith(color: VistaColors.textMuted);
    Widget side(String arrow, Color c, String title, String sub) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: VistaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              arrow,
              style: VistaType.headline.copyWith(fontSize: 18, color: c),
            ),
            const SizedBox(height: VistaSpace.sm),
            Text(
              title,
              style: VistaType.subhead.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: VistaSpace.sm),
            Text(
              sub,
              style: VistaType.chip.copyWith(
                fontWeight: FontWeight.w500,
                color: VistaColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
    Widget term(String label, String value, {Color? color}) => Row(
      children: [
        Expanded(child: Text(label, style: muted)),
        Text(
          value,
          style: VistaType.body.copyWith(
            color: color ?? VistaColors.textPrimary,
          ),
        ),
      ],
    );
    final link = VistaType.bodyMedium.copyWith(
      fontWeight: FontWeight.w600,
      color: VistaColors.accent,
    );

    return SafeArea(
      key: const ValueKey(_Step.consent),
      bottom: false,
      child: Column(
        children: [
          _topBar(
            title: 'Before you list',
            close: false,
            onLeading: () => setState(() => _step = _Step.create),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 8),
            child: VistaStepDots(count: 3, index: 1),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                VistaSpace.gutter,
                4,
                VistaSpace.gutter,
                VistaSpace.gutter,
              ),
              children: [
                Text(
                  'Your market has two sides',
                  style: VistaType.displayNumber.copyWith(fontSize: 22),
                ),
                const SizedBox(height: VistaSpace.lg),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      side(
                        '▲',
                        VistaColors.long,
                        'Some will buy $t',
                        'betting your price rises',
                      ),
                      const SizedBox(width: VistaSpace.lg),
                      side(
                        '▼',
                        VistaColors.short,
                        'Some will short $t',
                        'betting your price falls',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        'You earn ${YourMarketMock.creatorSharePct}% of the '
                        'fees from both',
                        textAlign: TextAlign.center,
                        style: VistaType.bodyStrong.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: VistaSpace.xxs),
                      Text(
                        YourMarketMock.shareLabel,
                        textAlign: TextAlign.center,
                        style: VistaType.caption.copyWith(
                          color: VistaColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VistaSpace.gutter,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: VistaColors.surface,
                    borderRadius: BorderRadius.circular(VistaRadius.card),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: VistaColors.surfaceRaised,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _symbol.isEmpty ? '?' : _symbol[0],
                              style: VistaType.chip.copyWith(
                                color: VistaColors.textPrimary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: VistaSpace.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t,
                                  style: VistaType.subhead.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  MakeMarketMock.name,
                                  style: VistaType.label.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: VistaColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'TERMS',
                            style: VistaType.labelStrong.copyWith(
                              color: VistaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: VistaSpace.md),
                      SizedBox(
                        height: 1,
                        child: SvgPicture.asset(
                          VistaAssets.termsDashedLine,
                          fit: BoxFit.fill,
                        ),
                      ),
                      const SizedBox(height: VistaSpace.md),
                      term('Supply', MakeMarketMock.supply),
                      const SizedBox(height: VistaSpace.md),
                      term('Most anyone can lose', 'What they put in'),
                      const SizedBox(height: VistaSpace.md),
                      term(
                        'Trading your own market',
                        'Not allowed',
                        color: VistaColors.short,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _footer([
            for (var i = 0; i < MakeMarketMock.consents.length; i++) ...[
              VistaCheckRow(
                checked: _agreed[i],
                semanticLabel: MakeMarketMock.consents[i],
                onChanged: (v) => setState(() => _agreed[i] = v),
                child: Text(
                  MakeMarketMock.consents[i],
                  style: VistaType.bodyMedium.copyWith(
                    fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: VistaSpace.lg),
            ],
            VistaCheckRow(
              checked: _agreed.last,
              semanticLabel:
                  'I agree to the Terms of Service and Market Listing Terms',
              onChanged: (v) => setState(() => _agreed.last = v),
              child: Text.rich(
                TextSpan(
                  text: 'I agree to the ',
                  children: [
                    TextSpan(text: 'Terms of Service', style: link),
                    const TextSpan(text: ' and '),
                    TextSpan(text: 'Market Listing Terms', style: link),
                  ],
                ),
                style: VistaType.bodyMedium,
              ),
            ),
            const SizedBox(height: VistaSpace.xxl),
            VistaPrimaryButton(
              label: 'Create $t',
              height: 52,
              enabled: _agreed.every((a) => a),
              onPressed: _create,
            ),
          ]),
        ],
      ),
    );
  }

  // ─── 3 · Live ─────────────────────────────────────────────────────────

  Widget _liveStep() {
    final t = '\$$_symbol';
    return Stack(
      key: const ValueKey(_Step.live),
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: VistaSpace.xs),
                  child: VistaGlyphButton(
                    glyph: '×',
                    size: 17,
                    semanticLabel: 'Close',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              SizedBox(
                height: 250,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned.fill(
                      child: SvgPicture.asset(
                        VistaAssets.mmLiveLattice,
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      top: 60,
                      child: SizedBox.square(
                        dimension: 88,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const VistaIcon(VistaAssets.mmLiveAvatar, size: 88),
                            Text(
                              _symbol.isEmpty ? '?' : _symbol[0],
                              style: VistaType.display.copyWith(
                                fontSize: 34,
                                fontWeight: FontWeight.w600,
                                color: VistaColors.textPrimary.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 170,
                      left: VistaSpace.gutter,
                      right: VistaSpace.gutter,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          t,
                          style: VistaType.display.copyWith(
                            fontSize: 40,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VistaSpace.md),
              Text('Your market is open', style: VistaType.tab),
              const SizedBox(height: 12),
              Text(
                'Your market cap is',
                style: VistaType.bodyMedium.copyWith(
                  fontSize: 14,
                  color: VistaColors.textMuted,
                ),
              ),
              const SizedBox(height: VistaSpace.xxs),
              Text(
                MakeMarketMock.startingCap,
                style: VistaType.display.copyWith(fontSize: 34),
              ),
              const Spacer(),
              _footer([
                VistaPrimaryButton(
                  label: 'Make your first call',
                  onPressed: () => _notBuilt('Make a call'),
                ),
                const SizedBox(height: VistaSpace.lg),
                Semantics(
                  button: true,
                  label: 'Share $t',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _notBuilt('Share'),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: VistaColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(VistaRadius.pill),
                      ),
                      child: Text(
                        'Share $t',
                        style: VistaType.subhead.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
        // Burst from the market image (Figma frame units).
        const Positioned.fill(child: ConfettiBurst(origin: Offset(201, 158))),
      ],
    );
  }
}
