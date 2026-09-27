import 'package:flutter/material.dart';

import 'design_system/design_system.dart';
import 'features/home/home_screen.dart';
import 'features/markets/markets_screen.dart';
import 'features/portfolio/portfolio_screen.dart';

/// Top-level tabs with the floating capsule nav. Tabs keep their state while
/// hidden; People is not built yet.
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
    VistaNavItem(label: 'People', asset: VistaAssets.navPeople),
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
    if (i == _home || i == _explore || i == _wallet) {
      setState(() => _tab = i);
    } else {
      _notBuilt(_navItems[i].label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: switch (_tab) {
                _explore => 1,
                _wallet => 2,
                _ => 0,
              },
              children: [
                HomeScreen(visible: _tab == _home, onNotBuilt: _notBuilt),
                MarketsScreen(onNotBuilt: _notBuilt),
                PortfolioScreen(onNotBuilt: _notBuilt),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              VistaSpace.gutter,
              18,
              VistaSpace.gutter,
              VistaSpace.sm + bottomInset,
            ),
            child: VistaBottomNav(
              items: _navItems,
              selectedIndex: _tab,
              onChanged: _select,
            ),
          ),
        ],
      ),
    );
  }
}
