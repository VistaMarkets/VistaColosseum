import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../profile/profile_screen.dart';
import 'follow_mock.dart';

/// Followers / Following for a profile (Figma 308:102 and 308:244). Opens on
/// [initialTab]: 0 = Followers, 1 = Following.
class FollowListScreen extends StatefulWidget {
  const FollowListScreen({super.key, this.initialTab = 0});

  static Route<void> route({int initialTab = 0}) => MaterialPageRoute(
    builder: (_) => FollowListScreen(initialTab: initialTab),
  );

  final int initialTab;

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  late int _tab = widget.initialTab;
  final _search = TextEditingController();
  String _query = '';

  /// Follow state by handle; seeded from the mock, toggled locally.
  final Map<String, bool> _following = {
    for (final p in [...FollowMock.followers, ...FollowMock.following])
      p.handle: p.following,
  };

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _privateNotBuilt() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Private profile — not in the demo yet')),
      );
  }

  void _selectTab(int i) {
    if (i == _tab) return;
    setState(() {
      _tab = i;
      _query = '';
      _search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final people = (_tab == 0 ? FollowMock.followers : FollowMock.following)
        .where((p) => p.handle.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            VistaTitleBar(
              title: FollowMock.owner,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: VistaSegmentedTabs(
                labels: const ['Followers', 'Following'],
                counts: const [
                  FollowMock.followerCount,
                  FollowMock.followingCount,
                ],
                selectedIndex: _tab,
                onChanged: _selectTab,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VistaSpace.gutter,
                vertical: VistaSpace.md,
              ),
              child: VistaSearchField(
                controller: _search,
                hint: _tab == 0 ? 'Search followers' : 'Search following',
                onChanged: (q) => setState(() => _query = q),
              ),
            ),
            Expanded(
              child: people.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text('No matches', style: VistaType.bodyRegular),
                    )
                  : ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(
                        top: 4,
                        bottom: MediaQuery.paddingOf(context).bottom + 16,
                      ),
                      itemCount: people.length,
                      separatorBuilder: (_, _) => const VistaListDivider(),
                      itemBuilder: (context, i) {
                        final p = people[i];
                        final following = _following[p.handle] ?? false;
                        return VistaPersonRow(
                          name: p.handle,
                          stats: p.stats,
                          emphasis: p.market,
                          locked: p.private,
                          badge: p.followsYou ? 'Follows you' : null,
                          onPressed: () => p.private
                              ? _privateNotBuilt()
                              : Navigator.of(context)
                                    .push(ProfileScreen.route(p.handle)),
                          trailing: VistaFollowButton(
                            following: following,
                            // Local only: nothing is sent anywhere.
                            onPressed: () => setState(
                              () => _following[p.handle] = !following,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
