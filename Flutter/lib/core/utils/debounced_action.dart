import 'dart:async';

/// Runs an action after a quiet period.
///
/// This is intentionally dependency-free and safe to use from UI code that
/// would otherwise write to storage or run expensive work on every keystroke,
/// scroll tick, or selection change.
class DebouncedAction {
  DebouncedAction(this.delay);

  final Duration delay;
  Timer? _timer;

  bool get isPending => _timer?.isActive ?? false;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      _timer = null;
      action();
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
