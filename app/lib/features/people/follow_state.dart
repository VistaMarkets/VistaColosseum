import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../../scenario/scenario.dart';
import '../portfolio/portfolio_mock.dart';

/// Who the viewer follows, shared by call cards, profiles and the Home
/// feed's Following tab and ranking: a view of [Scenario.followed], the one
/// follow set, so Reset demo clears it with everything else.
abstract final class FollowState {
  static ValueNotifier<Set<String>> get following => Scenario.followed;

  static bool isFollowing(String handle) => following.value.contains(handle);

  static void toggle(String handle) => Scenario.toggleFollow(handle);
}

/// "Follow" on a call card, for callers the viewer doesn't follow yet (and
/// never on their own calls). Tapped, it reads "Following" (tap again to
/// undo) and is gone the next time the card is drawn, as on X.
class FollowChip extends StatefulWidget {
  const FollowChip({super.key, required this.handle});

  final String handle;

  @override
  State<FollowChip> createState() => _FollowChipState();
}

class _FollowChipState extends State<FollowChip> {
  /// Shown at all: decided once, so following doesn't make it vanish
  /// under the finger.
  late final bool _offered =
      widget.handle != PortfolioMock.handle &&
      !FollowState.isFollowing(widget.handle);

  @override
  Widget build(BuildContext context) {
    if (!_offered) return const SizedBox.shrink();
    return ValueListenableBuilder(
      valueListenable: FollowState.following,
      builder: (context, following, _) {
        final on = following.contains(widget.handle);
        return Semantics(
          button: true,
          toggled: on,
          label: on ? 'Following ${widget.handle}' : 'Follow ${widget.handle}',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              FollowState.toggle(widget.handle);
            },
            child: SizedBox(
              height: VistaSize.tapTarget,
              child: Center(
                child: AnimatedSwitcher(
                  duration: VistaMotion.state,
                  child: Text(
                    on ? 'Following' : 'Follow',
                    key: ValueKey(on),
                    style: VistaType.body.copyWith(
                      color: on ? VistaColors.textMuted : VistaColors.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
