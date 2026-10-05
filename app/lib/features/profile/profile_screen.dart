import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../market/market_mock.dart';
import '../market/receipt_screens.dart';
import '../market/trader_market_screen.dart';
import '../people/follow_list_screen.dart';
import '../portfolio/portfolio_mock.dart';
import 'holdings_table.dart';
import 'private_profile_screen.dart';
import 'profile_mock.dart';
import '../../app_shell.dart';

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

/// Someone else's profile (Figma 303:102, "Profile — maya.eth · Arena
/// receipts"). Shows [handle] with their own record and calls; the rest is
/// the sample profile content.
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
              child: ListView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 24,
                ),
                children: [
                  Padding(padding: gutter, child: _header()),
                  const SizedBox(height: 18 + 16),
                  _record(),
                  const SizedBox(height: 8 + 22),
                  const Padding(
                    padding: gutter,
                    child: VistaSectionHead(
                      title: 'HOLDING NOW',
                      note: 'Shared live',
                    ),
                  ),
                  const SizedBox(height: 4 + 8),
                  Padding(
                    padding: gutter,
                    child: HoldingsTable(
                      onRowTap: (h) => Navigator.of(context)
                          .push(CallReceiptScreen.forHolding(widget.handle, h)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(padding: gutter, child: _calls()),
                ],
              ),
            ),
          ],
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
            style: VistaType.body.copyWith(
              fontSize: 26,
              color: VistaColors.textSecondary,
            ),
          ),
        ),
        gap,
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
        Text(
          ProfileMock.bio,
          textAlign: TextAlign.center,
          style: VistaType.bodyRegular.copyWith(height: 1.35),
        ),
        gap,
        Row(
          children: [
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Scenario.followed,
                builder: (context, followed, _) => VistaFollowButton(
                  following: followed.contains(widget.handle),
                  onPressed: () => Scenario.toggleFollow(widget.handle),
                  expand: true,
                ),
              ),
            ),
            const SizedBox(width: VistaSpace.lg),
            VistaChevronPill(
              label: 'market',
              chevron: false,
              large: true,
              onPressed: _openMarket,
            ),
          ],
        ),
      ],
    );
  }

  Widget _stats(RecordMetrics m) {
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
            value: ProfileMock.followers,
            label: 'Followers',
            onPressed: () =>
                Navigator.of(context).push(FollowListScreen.route()),
          ),
        ),
        Expanded(
          child: VistaCountStat(
            value: ProfileMock.market,
            label: 'Market',
            valueColor: VistaColors.accent,
            onPressed: _openMarket,
          ),
        ),
      ],
    );
  }

  /// The illustrative index chart and the record it is based on; with no
  /// settled call, no chart and no index copy.
  Widget _record() {
    return ValueListenableBuilder(
      valueListenable: Scenario.callReceipts,
      builder: (context, _, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (Scenario.record(widget.handle).settled > 0) ...[
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
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                ProfileMock.price,
                style: VistaType.displayNumber.copyWith(fontSize: 24),
              ),
              const SizedBox(width: VistaSpace.sm),
              Expanded(
                child: Text(
                  ProfileMock.cap,
                  style: VistaType.body.copyWith(color: VistaColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                ProfileMock.change,
                style: VistaType.headline.copyWith(color: VistaColors.long),
              ),
            ],
          ),
        ),
        const SizedBox(height: VistaSpace.lg),
        const ProfileIndexChart(),
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
            message: 'No calls from ${widget.handle} yet',
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

/// The trader's illustrative index chart on Profile, edge to edge (static
/// Figma vectors on a 402×180 box; x stretches with the screen). It is not
/// the trader-market route's chart, which plots the market's price series.
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
