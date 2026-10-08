import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/design_system.dart';
import '../market/trader_market_screen.dart';
import '../people/follow_list_screen.dart';
import '../portfolio/portfolio_mock.dart';
import 'holdings_table.dart';
import 'trader_profile.dart';
import '../live/market_prices.dart';
import '../markets/market_chart_card.dart';
import 'private_profile_screen.dart';
import '../people/follow_state.dart';
import 'edit_profile_screen.dart';
import 'profile_mock.dart';
import 'receipts_screen.dart';

/// Someone else's profile (Figma 303:102, "Profile — maya.eth · Arena
/// receipts"). Shows [handle]; the body is the sample profile content.
/// The pinned market-price bar (for tests).
const pinnedPriceKey = Key('profile.pinnedPrice');

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.handle});

  /// Opens [handle]'s profile, or the private layout for private accounts
  /// without a market.
  static Route<void> route(String handle) => MaterialPageRoute(
    builder: (_) => privateProfiles.containsKey(handle)
        ? PrivateProfileScreen(handle: handle)
        : ProfileScreen(handle: handle),
  );

  final String handle;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _span = PortfolioMock.defaultSpan;

  /// Your own profile (shows your edits).
  bool get _mine => widget.handle == PortfolioMock.handle;

  /// This trader's own figures (yours are the designed ones).
  TraderProfile get _p => TraderProfile.of(widget.handle);
  int _filter = 0; // 0 All, 1 Calls, 2 Arena

  final _scroll = ScrollController();

  /// On the market's price row, to tell when it has scrolled away.
  final _priceKey = GlobalKey();

  /// On the scrolling area, whose top edge the price row scrolls under.
  final _listKey = GlobalKey();

  /// The price row is out of view: show it pinned at the top instead.
  bool _pinned = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // Measured after the frame: during the scroll callback the list hasn't
  // been laid out at its new offset yet, so positions would be stale.
  void _onScroll() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

  void _measure() {
    if (!mounted) return;
    final row = _priceKey.currentContext?.findRenderObject() as RenderBox?;
    final list = _listKey.currentContext?.findRenderObject() as RenderBox?;
    bool pinned;
    // No market, no price to pin.
    if (_p.market == null) {
      pinned = false;
    } else if (row == null || !row.attached || list == null) {
      // Built lazily: once it's been dropped it's well off the top.
      pinned = _scroll.offset > 0;
    } else {
      final bottom = row.localToGlobal(Offset(0, row.size.height)).dy;
      pinned = bottom < list.localToGlobal(Offset.zero).dy;
    }
    if (pinned != _pinned) setState(() => _pinned = pinned);
  }

  void _openMarket() =>
      Navigator.of(context).push(TraderMarketScreen.route(widget.handle));

  void _notBuilt(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what — not in the demo yet')));
  }

  @override
  Widget build(BuildContext context) {
    const gutter = EdgeInsets.symmetric(horizontal: VistaSpace.gutter);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: VistaSpace.xs),
              child: VistaTitleBar(
                onBack: () => Navigator.of(context).maybePop(),
                actions: [
                  VistaGlyphButton(
                    glyph: '↗',
                    size: 20,
                    semanticLabel: 'Share',
                    onPressed: () => _notBuilt('Share'),
                  ),
                  VistaGlyphButton(
                    glyph: '•••',
                    semanticLabel: 'More',
                    onPressed: () => _notBuilt('More'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                key: _listKey,
                children: [
                  ListView(
                    controller: _scroll,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom + 24,
                    ),
                    children: [
                      Padding(padding: gutter, child: _header()),
                      const SizedBox(height: VistaSpace.sectionLg),
                      if (_p.market != null) ...[
                        _market(),
                        const SizedBox(height: VistaSpace.sectionLg),
                      ],
                      const Padding(
                        padding: gutter,
                        child: VistaSectionHead(
                          title: 'HOLDING NOW',
                          note: 'Shared live',
                        ),
                      ),
                      const SizedBox(height: VistaSpace.xl),
                      Padding(
                        padding: gutter,
                        child: HoldingsTable(
                          holdings: _p.holdings,
                          cashShare: _p.cashShare,
                          onRowTap: (h) =>
                              showReceiptSheet(context, holdingReceipt(h)),
                        ),
                      ),
                      const SizedBox(height: VistaSpace.sectionLg),
                      Padding(padding: gutter, child: _calls()),
                    ],
                  ),
                  // The market price stays in reach while scrolling: pinned
                  // under the title bar once its row has scrolled away.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: IgnorePointer(
                      ignoring: !_pinned,
                      child: AnimatedSlide(
                        offset: _pinned ? Offset.zero : const Offset(0, -0.4),
                        duration: VistaMotion.state,
                        curve: VistaMotion.enter,
                        child: AnimatedOpacity(
                          key: pinnedPriceKey,
                          opacity: _pinned ? 1 : 0,
                          duration: VistaMotion.state,
                          child: _pinnedPrice(),
                        ),
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

  /// "$0.4400 · Market cap … · +4.27%" in a slim bar; tapping opens the
  /// market.
  Widget _pinnedPrice() {
    return Semantics(
      button: true,
      label:
          '${widget.handle} market, '
          '${MarketPrices.format(MarketPrices.of(widget.handle).value, compact: true)}, '
          '${_changeText(_p)}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openMarket,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
          decoration: const BoxDecoration(
            color: VistaColors.background,
            border: Border(bottom: BorderSide(color: VistaColors.hairline)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LivePrice(
                handle: widget.handle,
                style: VistaType.figures(VistaType.headline),
              ),
              const SizedBox(width: VistaSpace.sm),
              Expanded(
                child: Text(
                  "${widget.handle}'s market",
                  style: VistaType.body.copyWith(color: VistaColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _changeText(_p),
                style: VistaType.figures(VistaType.body)
                    .copyWith(color: vistaChangeColor(_p.change ?? 0)),
              ),
              const SizedBox(width: VistaSpace.xs),
              Text(
                '›',
                style: VistaType.tab.copyWith(color: VistaColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    const gap = SizedBox(height: VistaSpace.xl);
    final initial = widget.handle.isEmpty
        ? '?'
        : widget.handle.characters.first.toUpperCase();
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: VistaColors.surface,
            shape: BoxShape.circle,
          ),
          child: Text(
            initial,
            style: VistaType.displayMedium.copyWith(
              color: VistaColors.textSecondary,
            ),
          ),
        ),
        gap,
        // Your own name from Edit profile, over your handle.
        if (_mine)
          ValueListenableBuilder(
            valueListenable: ProfileEdits.name,
            builder: (context, name, _) => name.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: VistaSpace.xs),
                    child: Text(
                      name,
                      style: VistaType.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
        Text(
          widget.handle,
          style: VistaType.displayNumber,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        gap,
        Text(
          _p.recordSince,
          style: VistaType.caption.copyWith(color: VistaColors.textMuted),
        ),
        gap,
        const VistaIcon(
          VistaAssets.verdictsLast10,
          size: 136,
          height: 10,
          semanticLabel: 'Last 10 verdicts',
        ),
        gap,
        Row(
          children: [
            Expanded(
              child: VistaCountStat(value: '${_p.settled}', label: 'Settled'),
            ),
            Expanded(
              child: VistaCountStat(value: '${_p.right}', label: 'Right'),
            ),
            Expanded(
              child: VistaCountStat(
                value: _p.followers,
                label: 'Followers',
                onPressed: () =>
                    Navigator.of(context).push(FollowListScreen.route()),
              ),
            ),
            // Their market's cap; a dash without one.
            Expanded(
              child: VistaCountStat(
                value: _p.market?.cap ?? '—',
                label: 'Market',
                valueColor: _p.market == null
                    ? VistaColors.textMuted
                    : VistaColors.accent,
                onPressed: _p.market == null ? null : _openMarket,
              ),
            ),
          ],
        ),
        gap,
        ValueListenableBuilder(
          valueListenable: ProfileEdits.bio,
          builder: (context, bio, _) => Text(
            _mine ? bio : _p.bio,
            textAlign: TextAlign.center,
            style: VistaType.bodyRegular.copyWith(height: 1.35),
          ),
        ),
        gap,
        Row(
          children: [
            Expanded(
              // Shared with call cards and the Home feed; nothing is sent.
              child: ValueListenableBuilder(
                valueListenable: FollowState.following,
                builder: (context, following, _) => VistaFollowButton(
                  following: following.contains(widget.handle),
                  onPressed: () => FollowState.toggle(widget.handle),
                  expand: true,
                ),
              ),
            ),
            if (_p.market != null) ...[
              const SizedBox(width: VistaSpace.lg),
              VistaChevronPill(
                label: 'market',
                chevron: false,
                large: true,
                onPressed: _openMarket,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _market() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
          child: Row(
            key: _priceKey,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              _LivePrice(handle: widget.handle, style: VistaType.displaySmall),
              const SizedBox(width: VistaSpace.sm),
              Expanded(
                child: Text(
                  '${_p.market!.cap} cap',
                  style: VistaType.body.copyWith(color: VistaColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _changeText(_p),
                style: VistaType.headline.copyWith(
                  color: vistaChangeColor(_p.change ?? 0),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VistaSpace.lg),
        // Yours is the designed chart; everyone else's, the app's line.
        if (_mine)
          const _ProfileChart()
        else
          ValueListenableBuilder(
            valueListenable: MarketPrices.of(widget.handle),
            builder: (context, price, _) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VistaSpace.gutter,
              ),
              child: MarketLineChart(
                id: widget.handle,
                changePct: _p.change ?? 0,
                price: price,
                height: 160,
              ),
            ),
          ),
        const SizedBox(height: VistaSpace.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VistaSpace.md),
          child: VistaSpanSelector(
            labels: PortfolioMock.spans,
            selectedIndex: _span,
            onChanged: (i) => setState(() => _span = i),
          ),
        ),
      ],
    );
  }

  Widget _calls() {
    final p = _p;
    final receipts = p.receipts.where(
      (r) => switch (_filter) {
        1 => r.kind == ReceiptKind.call,
        2 => r.kind == ReceiptKind.arena,
        _ => true,
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VistaSectionHead(
          title: 'CALLS',
          linkLabel: 'All receipts',
          linkSize: 13,
          onLink: () =>
              Navigator.of(context).push(ReceiptsScreen.route(widget.handle)),
        ),
        Wrap(
          spacing: VistaSpace.xl,
          children: [
            for (final (text, color) in p.summary)
              Text(text, style: VistaType.body.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: VistaSpace.xs),
        Wrap(
          spacing: VistaSpace.md,
          children: [
            for (var i = 0; i < p.filters.length; i++)
              VistaFilterChip(
                label: '${p.filters[i].$1} ${p.filters[i].$2}',
                selected: i == _filter,
                onPressed: () => setState(() => _filter = i),
              ),
          ],
        ),
        const SizedBox(height: VistaSpace.xs),
        for (final r in receipts)
          VistaReceipt(
            railAsset: r.rail,
            title: r.title,
            versus: r.versus,
            lead: r.lead,
            leadColor: r.leadColor,
            detail: r.detail,
            onTap: () => showReceiptSheet(context, r),
          ),
      ],
    );
  }
}

/// "+4.27%" for the market's 7d change; empty without a market.
String _changeText(TraderProfile p) {
  final c = p.change;
  if (c == null) return '';
  return '${c >= 0 ? '+' : '−'}${c.abs().toStringAsFixed(2)}%';
}

/// The market's live price.
class _LivePrice extends StatelessWidget {
  const _LivePrice({required this.handle, required this.style});

  final String handle;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: MarketPrices.of(handle),
    builder: (context, price, _) =>
        Text(MarketPrices.format(price, compact: true), style: style),
  );
}

/// Market price chart, edge to edge (static Figma vectors on a 402×180 box;
/// x stretches with the screen).
class _ProfileChart extends StatelessWidget {
  const _ProfileChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: LayoutBuilder(
        builder: (context, c) {
          final sx = c.maxWidth / 402;
          Widget layer(String asset, Rect r) => Positioned(
            left: r.left * sx,
            top: r.top,
            width: r.width * sx,
            height: r.height,
            child: SvgPicture.asset(asset, fit: BoxFit.fill),
          );
          return ClipRect(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                layer(
                  VistaAssets.profileDotLattice,
                  const Rect.fromLTWH(0, 0, 402, 180),
                ),
                layer(
                  VistaAssets.profileBaseline,
                  const Rect.fromLTWH(0, 129.39, 402, 1),
                ),
                layer(
                  VistaAssets.profileClipAbove,
                  const Rect.fromLTWH(-5, -6, 412, 136.385),
                ),
                layer(
                  VistaAssets.profileClipBelow,
                  const Rect.fromLTWH(-5, 130.39, 412, 55.615),
                ),
                Positioned(
                  right: VistaSpace.gutter,
                  top: 134.39,
                  child: Text(
                    ProfileMock.openPrice,
                    style: VistaType.micro.copyWith(
                      fontWeight: FontWeight.w600,
                      color: VistaColors.textSecondary,
                    ),
                  ),
                ),
                // Live dot at the latest point (centre 8 in from the right).
                Positioned(
                  right: 1,
                  top: 5.26,
                  child: const VistaIcon(VistaAssets.markerLiveHalo, size: 14),
                ),
                Positioned(
                  right: 4.5,
                  top: 8.76,
                  child: const VistaIcon(VistaAssets.markerLive, size: 7),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
