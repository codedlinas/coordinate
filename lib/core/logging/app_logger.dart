import 'package:flutter/foundation.dart';

/// Centralized logging utility for the app.
/// 
/// Benefits:
/// - Easy to disable all logging in production
/// - Consistent log format with tags
/// - Can be extended to log to remote services
class AppLogger {
  static const bool _enableLogging = kDebugMode;
  
  /// Log a debug message
  static void debug(String tag, String message) {
    if (_enableLogging) {
      debugPrint('[$tag] $message');
    }
  }
  
  /// Log an error message
  static void error(String tag, String message, [Object? error]) {
    if (_enableLogging) {
      debugPrint('[$tag] ERROR: $message');
      if (error != null) {
        debugPrint('[$tag] Details: $error');
      }
    }
  }
  
  /// Log location service messages
  static void location(String message) => debug('Location', message);
  
  /// Log background service messages
  static void background(String message) => debug('Background', message);
  
  /// Log tracking service messages
  static void tracking(String message) => debug('Tracking', message);
}

