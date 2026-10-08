import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design_system/design_system.dart';
import 'features/arena/arena_screen.dart';
import 'features/arena/battle_result_sheet.dart';
import 'features/home/home_screen.dart';
import 'features/markets/markets_screen.dart';
import 'features/portfolio/portfolio_screen.dart';

/// Top-level tabs with the floating capsule nav. Tabs keep their state while
/// hidden. The Arena tab's crowd-split panel wraps the nav.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _home = 0;
  static const _explore = 1;
  static const _wallet = 3;

  static const _navItems = [
    VistaNavItem(label: 'Home', asset: VistaAssets.navHome),
    VistaNavItem(label: 'Explore', asset: VistaAssets.navExplore),
    VistaNavItem(label: 'Arena', asset: VistaAssets.navArena),
    VistaNavItem(label: 'Wallet', asset: VistaAssets.navWallet),
  ];

  /// Opening tab; `--dart-define=START_TAB=wallet` opens on Wallet (handy for
  /// screenshots and recording the demo).
  int _tab = const String.fromEnvironment('START_TAB') == 'wallet'
      ? _wallet
      : _home;

  void _notBuilt(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what — not in the demo yet')));
  }

  void _select(int i) {
    setState(() => _tab = i);
  }

  /// Battles count down live; every so often settle any that are done (a
  /// result sheet shows for ones you were in).
  Timer? _settler;

  @override
  void initState() {
    super.initState();
    _settler = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) settleBattles(context);
    });
  }

  @override
  void dispose() {
    _settler?.cancel();
    super.dispose();
  }

  /// Bottom dock timing: the Arena panel folding in and out.
  static const _dock = Duration(milliseconds: 360);
  static const Curve _dockCurve = Cubic(0.2, 0, 0, 1);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    // The nav floats over the tabs with nothing behind it. Tabs are told how
    // much room it takes at the bottom (as safe-area padding) so fixed
    // content keeps clear while lists scroll beneath it.
    // The pill sits low, like iOS's floating tab bar: ~12pt into the home
    // indicator's safe area (28pt off the edge on a 34pt inset), or 10pt
    // off the edge on phones without one.
    final navBottom = bottomInset > 0
        ? math.max(bottomInset - 12, VistaSpace.lg)
        : VistaSpace.lg;
    final navSpace = typing
        ? 0.0
        : VistaSize.navBar + VistaSpace.sm + navBottom;
    final media = MediaQuery.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery(
              data: media.copyWith(
                padding: media.padding.copyWith(bottom: navSpace),
                viewPadding: media.viewPadding.copyWith(bottom: navSpace),
              ),
              child: _FadeThroughStack(
                index: _tab,
                children: [
                  HomeScreen(
                    visible: _tab == _home,
                    onNotBuilt: _notBuilt,
                    onExplore: () => _select(_explore),
                  ),
                  MarketsScreen(onNotBuilt: _notBuilt),
                  ArenaScreen(
                    onNotBuilt: _notBuilt,
                    onExplore: () => _select(_explore),
                  ),
                  PortfolioScreen(onNotBuilt: _notBuilt),
                ],
              ),
            ),
          ),
          // While typing (the bottom search on Explore and Arena) the nav
          // steps aside so the field sits right on the keyboard. One nav for
          // every tab, so it never moves between parents (its sliding pill
          // keeps animating).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: _dock,
              curve: _dockCurve,
              offset: typing ? const Offset(0, 1.5) : Offset.zero,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  VistaSpace.gutter,
                  VistaSpace.sm,
                  VistaSpace.gutter,
                  navBottom,
                ),
                child: VistaBottomNav(
                  items: _navItems,
                  selectedIndex: _tab,
                  onChanged: _select,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tabs that keep their state, switched with a fade-through: the outgoing
/// page fades out quickly, then the incoming one fades in while growing
/// from 97% to full size. Only the current tab takes input and runs
/// animations; the others stay mounted but offstage.
class _FadeThroughStack extends StatefulWidget {
  const _FadeThroughStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_FadeThroughStack> createState() => _FadeThroughStackState();
}

class _FadeThroughStackState extends State<_FadeThroughStack>
    with SingleTickerProviderStateMixin {
  /// Out takes the first 35%, in the rest (Material's 90 / 210 ms split).
  static const double _outShare = 0.35;

  late final AnimationController _switch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );
  int? _outgoing;

  @override
  void didUpdateWidget(_FadeThroughStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _outgoing = old.index;
      _switch.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _switch.dispose();
    _switchRunning.dispose();
    super.dispose();
  }

  // Opacity and scale per role, driven straight off the switch.
  late final Animation<double> _in = _switch.drive(
    CurveTween(curve: const Interval(_outShare, 1, curve: Curves.easeOutCubic)),
  );
  late final Animation<double> _out = _switch.drive(
    Tween<double>(begin: 1, end: 0).chain(
      CurveTween(curve: const Interval(0, _outShare, curve: Curves.easeIn)),
    ),
  );
  late final Animation<double> _grow = _switch.drive(
    Tween<double>(begin: 0.97, end: 1).chain(
      CurveTween(
        curve: const Interval(_outShare, 1, curve: Curves.easeOutCubic),
      ),
    ),
  );
  static const _hidden = AlwaysStoppedAnimation<double>(0);
  static const _full = AlwaysStoppedAnimation<double>(1);

  @override
  Widget build(BuildContext context) {
    // Rebuilds only when a switch starts or ends (to show or hide the
    // outgoing page); the fades themselves run in the transitions.
    return ValueListenableBuilder(
      valueListenable: _switchRunning,
      builder: (context, switching, _) => Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < widget.children.length; i++)
            _page(
              i,
              current: i == widget.index,
              leaving: switching && i == _outgoing,
            ),
        ],
      ),
    );
  }

  late final _switchRunning = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _switch.addStatusListener(
      (status) => _switchRunning.value = status == AnimationStatus.forward,
    );
  }

  Widget _page(int i, {required bool current, required bool leaving}) {
    // Same wrappers for every page, always, so no page loses its state.
    return Offstage(
      offstage: !current && !leaving,
      child: TickerMode(
        enabled: current,
        child: IgnorePointer(
          ignoring: !current,
          child: FadeTransition(
            opacity: current
                ? _in
                : leaving
                ? _out
                : _hidden,
            child: ScaleTransition(
              scale: current ? _grow : _full,
              child: widget.children[i],
            ),
          ),
        ),
      ),
    );
  }
}
