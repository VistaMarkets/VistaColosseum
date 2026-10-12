import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'design_system/design_system.dart';
import 'app_shell.dart';
import 'features/simulation/simulation_indicator.dart';

void main() {
  runApp(const VistaColosseumApp());
}

/// The one-time toast a browser visitor sees: the judge controls live in
/// the pill, a strip the README explains and a page visitor has not read.
const kLaunchHint =
    'Tap the Simulated pill at the bottom to switch persona or play the '
    'copy story';

class VistaColosseumApp extends StatelessWidget {
  const VistaColosseumApp({
    super.key,
    this.home = const AppShell(),
    this.web = kIsWeb,
  });

  /// The first route. Tests start on a deeper screen inside the app's real
  /// builder (text clamp and simulated pill).
  final Widget home;

  /// On the web, the app sits in a centred 390-wide phone frame (every
  /// layout is phone-designed) and shows [kLaunchHint] once.
  final bool web;

  static final _navigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VistaColosseum',
      debugShowCheckedModeBanner: false,
      theme: VistaTheme.dark(),
      navigatorKey: _navigator,
      // A mouse drag swipes like a finger, so pagers work on desktop builds
      // (VC-DEM-001's PC input equivalent).
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
      // Cap system text scaling so fixed-height rows (44pt bars, 46pt pills,
      // 64pt nav) stay intact; beyond 1.3× the feed card would clip. The
      // simulated pill sits over every route and sheet.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: web
            ? _LaunchHint(
                navigator: _navigator,
                child: _phoneFrame(
                  context,
                  SimulationIndicator(navigator: _navigator, child: child!),
                ),
              )
            : SimulationIndicator(navigator: _navigator, child: child!),
      ),
      home: home,
    );
  }

  /// A 390-wide column in the window's centre, with the media size the app
  /// reads narrowed to match, so sheets and pagers stay inside the frame.
  static Widget _phoneFrame(BuildContext context, Widget child) {
    final size = MediaQuery.sizeOf(context);
    final w = math.min(390.0, size.width);
    return ColoredBox(
      color: VistaColors.background,
      child: Center(
        child: SizedBox(
          width: w,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(size: Size(w, size.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Shows [kLaunchHint] for 8 seconds after the first frame, once per page
/// load.
class _LaunchHint extends StatefulWidget {
  const _LaunchHint({required this.navigator, required this.child});

  final GlobalKey<NavigatorState> navigator;
  final Widget child;

  @override
  State<_LaunchHint> createState() => _LaunchHintState();
}

class _LaunchHintState extends State<_LaunchHint> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = widget.navigator.currentContext;
      if (context == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(kLaunchHint),
          duration: Duration(seconds: 8),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
