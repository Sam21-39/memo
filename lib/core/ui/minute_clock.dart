import 'dart:async';

import 'package:flutter/widgets.dart';

/// ponytail: one app-wide ticker; runs only while something listens and the app is foreground.
class MinuteClock extends ValueNotifier<DateTime> {
  MinuteClock._() : super(DateTime.now());

  static final instance = MinuteClock._();

  Timer? _timer;
  AppLifecycleListener? _life;

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      _start();
      _life = AppLifecycleListener(onResume: _start, onPause: _stop);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _stop();
      _life?.dispose();
      _life = null;
    }
  }

  /// Sets the time now, then again at the next whole minute.
  void _start() {
    value = DateTime.now();
    _timer?.cancel();
    final now = DateTime.now();
    _timer = Timer(
      Duration(seconds: 60 - now.second, milliseconds: -now.millisecond),
      _start,
    );
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }
}
