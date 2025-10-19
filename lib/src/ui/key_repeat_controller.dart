import 'dart:async';

import 'package:flutter/services.dart';

/// Synthesizes key repeat behaviour for platforms that do not emit native
/// repeat events. The controller tracks a single active key and invokes the
/// supplied [onRepeat] callback after an initial delay followed by a fixed
/// interval until the key is released or native repeat events are observed.
class KeyRepeatController {
  KeyRepeatController({
    this.initialDelay = const Duration(milliseconds: 300),
    this.repeatInterval = const Duration(milliseconds: 33),
  });

  final Duration initialDelay;
  final Duration repeatInterval;

  PhysicalKeyboardKey? _trackedPhysicalKey;
  VoidCallback? _repeatCallback;
  Timer? _delayTimer;
  Timer? _repeatTimer;
  bool _platformRepeating = false;

  /// Starts tracking [event] for potential synthetic repeats. If the same key
  /// is already being tracked the call is interpreted as a native repeat and
  /// synthetic timers are cancelled.
  void handleKeyDown(KeyDownEvent event, {required VoidCallback onRepeat}) {
    if (_trackedPhysicalKey == event.physicalKey) {
      _platformRepeating = true;
      _cancelTimers();
      return;
    }

    _cancelAll();
    _trackedPhysicalKey = event.physicalKey;
    _repeatCallback = onRepeat;
    _platformRepeating = false;

    _delayTimer = Timer(initialDelay, () {
      if (_platformRepeating || _repeatCallback == null) {
        return;
      }
      _repeatTimer = Timer.periodic(repeatInterval, (_) {
        _repeatCallback?.call();
      });
    });
  }

  /// Cancels synthetic repeat timers when a native repeat event is observed.
  void handleKeyRepeat(KeyRepeatEvent event) {
    if (event.physicalKey != _trackedPhysicalKey) {
      return;
    }
    _platformRepeating = true;
    _cancelTimers();
  }

  /// Stops tracking the active key when it is released.
  void handleKeyUp(KeyUpEvent event) {
    if (event.physicalKey != _trackedPhysicalKey) {
      return;
    }
    _cancelAll();
  }

  /// Cancels any pending timers and clears internal state.
  void cancel() {
    _cancelAll();
  }

  void dispose() {
    _cancelAll();
  }

  void _cancelTimers() {
    _delayTimer?.cancel();
    _delayTimer = null;
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  void _cancelAll() {
    _cancelTimers();
    _trackedPhysicalKey = null;
    _repeatCallback = null;
    _platformRepeating = false;
  }
}
