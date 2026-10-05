import 'package:flutter/material.dart';

import 'design_system/design_system.dart';
import 'features/arena/arena_screen.dart';
import 'features/arena/crowd_filter_panel.dart';
import 'features/home/home_screen.dart';
import 'features/markets/markets_screen.dart';
import 'features/portfolio/portfolio_screen.dart';

/// Top-level tabs with the floating capsule nav. Tabs keep their state while
/// hidden. The Arena tab's crowd-split panel wraps the nav.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// The selected tab, so a sheet anywhere can switch it (View in Wallet).
  static final tab = ValueNotifier<int>(0);
  static const wallet = 3;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _home = 0;
  static const _arena = 2;
  static const _wallet = AppShell.wallet;

  static const _navItems = [
    VistaNavItem(label: 'Home', asset: VistaAssets.navHome),
    VistaNavItem(label: 'Explore', asset: VistaAssets.navExplore),
    VistaNavItem(label: 'Arena', asset: VistaAssets.navArena),
    VistaNavItem(label: 'Wallet', asset: VistaAssets.navWallet),
  ];

  /// Opening tab; `--dart-define=START_TAB=wallet` opens on Wallet (handy for
  /// screenshots and recording the demo).
  int get _tab => AppShell.tab.value;

  @override
  void initState() {
    super.initState();
    AppShell.tab
      ..value = const String.fromEnvironment('START_TAB') == 'wallet'
          ? _wallet
          : _home
      ..addListener(_onTab);
  }

  void _onTab() => setState(() {});

  @override
  void dispose() {
    AppShell.tab.removeListener(_onTab);
    super.dispose();
  }

  void _notBuilt(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what — not in the demo yet')));
  }

  void _select(int i) {
    AppShell.tab.value = i;
  }

  /// Bottom dock timing: the Arena panel folding in and out.
  static const _dock = Duration(milliseconds: 360);
  static const Curve _dockCurve = Cubic(0.2, 0, 0, 1);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final arena = _tab == _arena;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _FadeThroughStack(
              index: _tab,
              children: [
                HomeScreen(visible: _tab == _home, onNotBuilt: _notBuilt),
                MarketsScreen(onNotBuilt: _notBuilt),
                ArenaScreen(onNotBuilt: _notBuilt),
                PortfolioScreen(onNotBuilt: _notBuilt),
              ],
            ),
          ),
          // One dock for every tab, so the nav never moves between parents
          // (its sliding pill keeps animating). On the Arena tab the crowd
          // panel folds open above the nav and the sheet eases in behind it.
          AnimatedContainer(
            duration: _dock,
            curve: _dockCurve,
            decoration: BoxDecoration(
              color: arena
                  ? VistaColors.surface
                  : VistaColors.surface.withValues(alpha: 0),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, arena ? 0.25 : 0),
                  offset: const Offset(0, -4),
                  blurRadius: 4,
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
              VistaSpace.gutter,
              arena ? 14 : 18,
              VistaSpace.gutter,
              VistaSpace.sm + bottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRect(
                  child: AnimatedAlign(
                    duration: _dock,
                    curve: _dockCurve,
                    alignment: Alignment.topCenter,
                    heightFactor: arena ? 1 : 0,
                    child: AnimatedOpacity(
                      duration: _dock,
                      curve: arena ? const Interval(0.3, 1) : Curves.easeOut,
                      opacity: arena ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !arena,
                        child: ExcludeSemantics(
                          excluding: !arena,
                          // Kept mounted so its filter survives tab switches.
                          child: const CrowdFilterPanel(),
                        ),
                      ),
                    ),
                  ),
                ),
                VistaBottomNav(
                  items: _navItems,
                  selectedIndex: _tab,
                  onChanged: _select,
                ),
              ],
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
