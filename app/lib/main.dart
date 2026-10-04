import 'package:flutter/material.dart';

import 'design_system/design_system.dart';
import 'app_shell.dart';
import 'features/simulation/simulation_indicator.dart';

void main() {
  runApp(const VistaColosseumApp());
}

class VistaColosseumApp extends StatelessWidget {
  const VistaColosseumApp({super.key});

  static final _navigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VistaColosseum',
      debugShowCheckedModeBanner: false,
      theme: VistaTheme.dark(),
      navigatorKey: _navigator,
      // Cap system text scaling so fixed-height rows (44pt bars, 46pt pills,
      // 64pt nav) stay intact; beyond 1.3× the feed card would clip. The
      // simulated pill sits over every route and sheet.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: SimulationIndicator(navigator: _navigator, child: child!),
      ),
      home: const AppShell(),
    );
  }
}
