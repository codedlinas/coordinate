import 'dart:async';

/// A lightweight service that emits periodic time ticks.
/// Used to trigger UI recomputation for time-based displays
/// (e.g., "Last 24 Hours") without draining battery.
class TimeTickerService {
  static const Duration _tickInterval = Duration(seconds: 60);
  
  Timer? _timer;
  final _controller = StreamController<DateTime>.broadcast();
  
  /// Stream of UTC timestamps emitted every [_tickInterval].
  Stream<DateTime> get tickStream => _controller.stream;
  
  /// Current UTC time (for initial state).
  DateTime get currentTime => DateTime.now().toUtc();
  
  /// Start the ticker. Safe to call multiple times.
  void start() {
    if (_timer != null && _timer!.isActive) return;
    
    // Emit immediately
    _controller.add(DateTime.now().toUtc());
    
    // Then emit periodically
    _timer = Timer.periodic(_tickInterval, (_) {
      _controller.add(DateTime.now().toUtc());
    });
  }
  
  /// Stop the ticker and release resources.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
  
  /// Dispose the service completely.
  void dispose() {
    stop();
    _controller.close();
  }
}

