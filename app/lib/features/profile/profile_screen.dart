import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../market/trader_market_screen.dart';
import '../people/follow_list_screen.dart';
import '../portfolio/portfolio_mock.dart';
import 'holdings_table.dart';
import 'private_profile_screen.dart';
import 'profile_mock.dart';

/// Someone else's profile (Figma 303:102, "Profile — maya.eth · Arena
/// receipts"). Shows [handle]; the body is the sample profile content.
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
  int _filter = 0; // 0 All, 1 Calls, 2 Arena

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
                  _market(),
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
                      onRowTap: () => _notBuilt('Call details'),
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
        gap,
        Text(
          ProfileMock.recordSince,
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
            const Expanded(
              child: VistaCountStat(
                value: ProfileMock.settled,
                label: 'Settled',
              ),
            ),
            const Expanded(
              child: VistaCountStat(value: ProfileMock.right, label: 'Right'),
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
        const _ProfileChart(),
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
    final receipts = ProfileMock.receipts.where(
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
          onLink: () => _notBuilt('All receipts'),
        ),
        Wrap(
          spacing: VistaSpace.xl,
          children: [
            for (final (text, color) in ProfileMock.summary)
              Text(text, style: VistaType.body.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: VistaSpace.xs),
        Wrap(
          spacing: VistaSpace.md,
          children: [
            for (var i = 0; i < ProfileMock.filters.length; i++)
              VistaFilterChip(
                label:
                    '${ProfileMock.filters[i].$1} ${ProfileMock.filters[i].$2}',
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
          ),
      ],
    );
  }
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
