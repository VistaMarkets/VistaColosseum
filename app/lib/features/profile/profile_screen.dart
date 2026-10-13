import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_shell.dart';
import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../live/market_prices.dart';
import '../market/market_mock.dart';
import '../market/receipt_screens.dart';
import '../market/trader_market_mock.dart';
import '../market/trader_market_screen.dart';
import '../markets/market_chart_card.dart';
import '../people/follow_list_screen.dart';
import '../people/follow_state.dart';
import '../portfolio/portfolio_mock.dart';
import '../portfolio/series_chart.dart';
import 'edit_profile_screen.dart';
import 'holdings_table.dart';
import 'private_profile_screen.dart';
import 'profile_mock.dart';
import 'trader_profile.dart';

/// The pinned market-price bar (for tests).
const pinnedPriceKey = Key('profile.pinnedPrice');

/// [author]'s settled calls as dots, oldest to newest, the last 10 at
/// most, each in its receipt's colour (right long, wrong short). Order is
/// the store's, which lists each profile trader's calls oldest first.
/// Settled is as [Scenario.record] counts it at the clock, so the strip's
/// count is the header's Settled. With nothing settled it shows nothing.
class VerdictStrip extends StatelessWidget {
  const VerdictStrip({super.key, required this.author});

  final String author;

  @override
  Widget build(BuildContext context) {
    final at = Scenario.clock.value;
    final settled = [
      for (final c in Scenario.callReceipts.value)
        if (c.author == author &&
            switch (Scenario.outcomeAt(c, at)) {
              CallOutcome.right || CallOutcome.wrong => true,
              _ => false,
            })
          c,
    ];
    if (settled.isEmpty) return const SizedBox.shrink();
    final last = settled.length > 10
        ? settled.sublist(settled.length - 10)
        : settled;
    return Padding(
      padding: const EdgeInsets.only(bottom: VistaSpace.xl),
      child: Semantics(
        container: true,
        label: 'Last ${last.length} verdicts',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, c) in last.indexed) ...[
              if (i > 0) const SizedBox(width: VistaSpace.xs),
              SizedBox.square(
                dimension: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Someone's profile (Figma 303:102, "Profile — maya.eth · Arena
/// receipts"). Shows [handle] with their own figures and market, and the
/// record and calls the store holds for them.
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

  /// Their market block shows when they have a market and a settled call;
  /// with no settled call, no chart and no index copy.
  bool get _showMarket =>
      _p.market != null && Scenario.record(widget.handle).settled > 0;

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
    // No market block, no price to pin.
    if (!_showMarket) {
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
                      _record(),
                      const SizedBox(height: VistaSpace.sectionLg),
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
                          onRowTap: (h) => Navigator.of(context).push(
                            CallReceiptScreen.forHolding(widget.handle, h),
                          ),
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

  /// "$0.4400   maya.eth's market   +4.27%" in a slim bar; tapping opens
  /// the market.
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
        ValueListenableBuilder(
          valueListenable: Scenario.callReceipts,
          builder: (context, calls, _) {
            // Dated from the trader's first call (the store lists each
            // profile trader's oldest first); with none, no line.
            final since = calls
                .where((c) => c.author == widget.handle)
                .firstOrNull
                ?.entryAt;
            if (since == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: VistaSpace.xl),
              child: Text(
                'Record since $since',
                style: VistaType.caption.copyWith(color: VistaColors.textMuted),
              ),
            );
          },
        ),
        gap,
        ValueListenableBuilder(
          valueListenable: Scenario.callReceipts,
          builder: (context, _, _) {
            final m = Scenario.record(widget.handle);
            return Column(
              children: [
                VerdictStrip(author: widget.handle),
                _stats(m),
              ],
            );
          },
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

  /// Settled and Right as the store counts them ([m]); followers and the
  /// market's cap are the trader's own.
  Widget _stats(RecordMetrics m) {
    final market = _p.market;
    return Row(
      children: [
        Expanded(
          child: VistaCountStat(value: '${m.settled}', label: 'Settled'),
        ),
        Expanded(
          child: VistaCountStat(value: '${m.right}', label: 'Right'),
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
            value: market?.cap ?? '—',
            label: 'Market',
            valueColor: market == null
                ? VistaColors.textMuted
                : VistaColors.accent,
            onPressed: market == null ? null : _openMarket,
          ),
        ),
      ],
    );
  }

  /// The market block and, under it, the record it is based on.
  Widget _record() {
    return ValueListenableBuilder(
      valueListenable: Scenario.callReceipts,
      builder: (context, _, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showMarket) ...[
            _market(),
            const SizedBox(height: VistaSpace.lg),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VistaSpace.gutter),
            child: TraderRecordPanel(handle: widget.handle),
          ),
        ],
      ),
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
        // Yours is the designed chart, or, while your freshly listed market
        // has no history (VC-MKT-001), a flat line at its cap; everyone
        // else's is the app's line.
        if (_mine && !TraderMarketMock.ownHasHistory)
          SizedBox(
            height: 180,
            child: SeriesChart(
              focus: List.filled(48, TraderMarketMock.ownCapCents / 100),
            ),
          )
        else if (_mine)
          const ProfileIndexChart()
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

  /// The trader's call receipts under a CALLS heading; with none, no
  /// heading, and the empty state instead.
  Widget _calls() {
    return ValueListenableBuilder(
      valueListenable: Scenario.callReceipts,
      builder: (context, calls, _) {
        if (!calls.any((c) => c.author == widget.handle)) {
          return VistaEmptyState(
            message:
                'No call receipts for ${widget.handle} in ${Scenario.fixtureVersion}',
            actionLabel: 'Explore markets',
            onAction: () => AppShell.showExplore(context),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VistaSectionHead(
              title: 'CALLS',
              linkLabel: 'All receipts',
              linkSize: 13,
              onLink: () =>
                  Navigator.of(context)
                      .push(ReceiptsScreen.route(widget.handle)),
            ),
            CallRecordList(author: widget.handle),
          ],
        );
      },
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

/// Your illustrative index chart on your own Profile, edge to edge (static
/// Figma vectors on a 402×180 box; x stretches with the screen). Other
/// traders' profiles plot their market's line instead.
class ProfileIndexChart extends StatelessWidget {
  const ProfileIndexChart({super.key});

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
