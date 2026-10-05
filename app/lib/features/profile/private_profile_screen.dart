import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../market/receipt_screens.dart';
import '../people/follow_list_screen.dart';
import 'profile_mock.dart';

/// A private account with no market (Figma 258:407): the header, a private
/// notice in place of market and holdings, and the public, graded calls.
class PrivateProfileScreen extends StatefulWidget {
  const PrivateProfileScreen({super.key, required this.handle});

  final String handle;

  @override
  State<PrivateProfileScreen> createState() => _PrivateProfileScreenState();
}

class _PrivateProfileScreenState extends State<PrivateProfileScreen> {
  PrivateProfile get _p => privateProfiles[widget.handle]!;

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
                  Padding(padding: gutter, child: _notice()),
                  const SizedBox(height: 4 + 14),
                  Padding(
                    padding: gutter,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Calls', style: VistaType.tab),
                        const SizedBox(height: VistaSpace.sm),
                        Container(
                          width: 20,
                          height: 2,
                          decoration: BoxDecoration(
                            color: VistaColors.accent,
                            borderRadius: BorderRadius.circular(
                              VistaRadius.pill,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6 + 6),
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
    final initial = widget.handle.characters.first.toUpperCase();
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
        Text(widget.handle, style: VistaType.displayNumber),
        gap,
        Container(
          padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
          decoration: BoxDecoration(
            color: VistaColors.surface,
            borderRadius: BorderRadius.circular(VistaRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const VistaIcon(VistaAssets.lockSmall, size: 9.6, height: 11.2),
              const SizedBox(width: 5),
              Text(
                'Private account',
                style: VistaType.chip.copyWith(color: VistaColors.textMuted),
              ),
            ],
          ),
        ),
        gap,
        ValueListenableBuilder(
          valueListenable: Scenario.callReceipts,
          builder: (context, _, _) {
            final m = Scenario.record(widget.handle);
            return Row(
              children: [
                Expanded(
                  child: VistaCountStat(
                    value: '${m.settled}',
                    label: 'Settled',
                  ),
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
                Expanded(
                  child: VistaCountStat(
                    value: '${m.open}',
                    label: 'Open calls',
                  ),
                ),
              ],
            );
          },
        ),
        gap,
        Text(
          _p.bio,
          textAlign: TextAlign.center,
          style: VistaType.bodyRegular.copyWith(height: 1.35),
        ),
        gap,
        ValueListenableBuilder(
          valueListenable: Scenario.followed,
          builder: (context, followed, _) => VistaFollowButton(
            following: followed.contains(widget.handle),
            expand: true,
            onPressed: () => Scenario.toggleFollow(widget.handle),
          ),
        ),
      ],
    );
  }

  Widget _notice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VistaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: VistaColors.surfaceRaised,
              shape: BoxShape.circle,
            ),
            child: const VistaIcon(
              VistaAssets.lockNotice,
              size: 13.2,
              height: 15.4,
            ),
          ),
          const SizedBox(width: VistaSpace.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Positions are private', style: VistaType.subhead),
                const SizedBox(height: 3),
                Text(
                  "${widget.handle} hasn't listed a market or shared a "
                  'portfolio. Their calls are public, and every one is '
                  'graded.',
                  style: VistaType.chip.copyWith(
                    fontWeight: FontWeight.w500,
                    color: VistaColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _calls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TraderRecordPanel(handle: widget.handle),
        CallRecordList(author: widget.handle),
      ],
    );
  }
}
