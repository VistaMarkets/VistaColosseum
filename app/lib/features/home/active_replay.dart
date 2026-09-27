import 'package:flutter/widgets.dart';

/// Plays [replay] from the start whenever the host widget becomes active (its
/// card settles on screen) or the app returns to the foreground while it is
/// active; resets it when the widget goes inactive so the next visit replays.
/// With reduced motion on, it jumps straight to the finished state.
mixin ActiveReplay<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  AnimationController get replay;

  /// Reads the host widget's "is on screen" flag.
  bool isActive(T widget);

  bool _primed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // First point where MediaQuery (reduced motion) can be read.
    if (!_primed) {
      _primed = true;
      if (isActive(widget)) _play();
    }
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    final now = isActive(widget);
    if (now && !isActive(oldWidget)) {
      _play();
    } else if (!now && isActive(oldWidget)) {
      replay.value = 0;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isActive(widget)) _play();
  }

  void _play() {
    if (MediaQuery.disableAnimationsOf(context)) {
      replay.value = 1;
    } else {
      replay.forward(from: 0);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
