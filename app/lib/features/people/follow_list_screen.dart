import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
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

  /// The lists and who the user follows, from the store.
  final _follows = Listenable.merge([
    Scenario.followers,
    Scenario.following,
    Scenario.followed,
  ]);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _follows,
    builder: (context, _) => _build(),
  );

  Widget _build() {
    final people =
        (_tab == 0 ? Scenario.followers.value : Scenario.following.value)
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
                        final following = Scenario.followed.value.contains(
                          p.handle,
                        );
                        return VistaPersonRow(
                          name: p.handle,
                          stats: p.stats,
                          emphasis: p.market,
                          locked: p.private,
                          badge: p.followsYou ? 'Follows you' : null,
                          onPressed: () =>
                              Navigator.of(context)
                                  .push(ProfileScreen.route(p.handle)),
                          trailing: VistaFollowButton(
                            following: following,
                            onPressed: () => Scenario.toggleFollow(p.handle),
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
