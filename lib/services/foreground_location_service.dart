import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive/hive.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import 'location_service.dart';
import 'background_location_service.dart';

/// Foreground service task handler for Android high-reliability tracking.
/// This runs as a foreground service with a persistent notification.
@pragma('vm:entry-point')
void startForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(ForegroundTaskHandler());
}

/// Task handler for the foreground service.
class ForegroundTaskHandler extends TaskHandler {
  Timer? _timer;
  
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('ForegroundLocationService: Started at $timestamp');
    
    // Start periodic location checks every 5 minutes
    // This is more frequent than WorkManager's 15 minute minimum
    _timer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _performLocationCheck();
    });
    
    // Also check immediately on start
    await _performLocationCheck();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    debugPrint('ForegroundLocationService: Repeat event at $timestamp');
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('ForegroundLocationService: Destroyed at $timestamp');
    _timer?.cancel();
  }

  @override
  void onNotificationPressed() {
    // User tapped the notification - the app will be brought to foreground
    debugPrint('ForegroundLocationService: Notification pressed');
  }

  Future<void> _performLocationCheck() async {
    try {
      debugPrint('ForegroundLocationService: Performing location check...');
      
      final locationService = LocationService();
      
      final hasPermission = await locationService.checkPermission();
      if (!hasPermission) {
        debugPrint('ForegroundLocationService: No permission');
        _updateNotification('Location permission required');
        return;
      }
      
      final locationInfo = await locationService.getCurrentLocationInfo();
      if (locationInfo == null || locationInfo.countryCode.isEmpty) {
        debugPrint('ForegroundLocationService: Could not get location');
        _updateNotification('Could not determine location');
        return;
      }
      
      // Update notification with current country
      _updateNotification('Currently in ${locationInfo.countryName}');
      
      // The actual visit tracking is handled by the BackgroundLocationService
      // This foreground service just ensures more frequent checks
      debugPrint('ForegroundLocationService: In ${locationInfo.countryName}');
      
    } catch (e) {
      debugPrint('ForegroundLocationService: Error - $e');
    }
  }
  
  void _updateNotification(String text) {
    FlutterForegroundTask.updateService(
      notificationText: text,
    );
  }
}

/// Service for high-reliability Android foreground tracking.
/// 
/// This uses a persistent foreground service with a notification,
/// providing more reliable tracking than WorkManager alone.
/// 
/// Trade-offs:
/// - More reliable than WorkManager
/// - Persistent notification (some users may find this annoying)
/// - Higher battery usage than WorkManager alone
class ForegroundLocationService {
  static const String _settingsKey = 'foreground_tracking_enabled';
  
  bool _isEnabled = false;
  bool _isRunning = false;
  
  bool get isEnabled => _isEnabled;
  bool get isRunning => _isRunning;
  
  /// Returns true if foreground service is supported (Android only).
  static bool get isSupported => Platform.isAndroid;
  
  /// Initialize the foreground location service.
  Future<void> initialize() async {
    if (!isSupported) return;
    
    // Load saved preference
    final box = await Hive.openBox('foreground_tracking');
    _isEnabled = box.get(_settingsKey, defaultValue: false) as bool;
    
    // Initialize FlutterForegroundTask
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'coordinate_foreground_service',
        channelName: 'Coordinate Location Tracking',
        channelDescription: 'High-reliability country tracking',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        visibility: NotificationVisibility.VISIBILITY_SECRET,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: _isEnabled,
        autoRunOnMyPackageReplaced: _isEnabled,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    
    // Start if was enabled
    if (_isEnabled) {
      await start();
    }
  }
  
  /// Enable high-reliability tracking with foreground service.
  Future<bool> enable() async {
    if (!isSupported) return false;
    
    try {
      // Request notification permission for foreground service
      final notificationPermission = 
          await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      
      final started = await start();
      if (started) {
        _isEnabled = true;
        final box = await Hive.openBox('foreground_tracking');
        await box.put(_settingsKey, true);
      }
      return started;
    } catch (e) {
      debugPrint('ForegroundLocationService: Enable failed - $e');
      return false;
    }
  }
  
  /// Disable high-reliability tracking.
  Future<void> disable() async {
    if (!isSupported) return;
    
    try {
      await stop();
      _isEnabled = false;
      final box = await Hive.openBox('foreground_tracking');
      await box.put(_settingsKey, false);
    } catch (e) {
      debugPrint('ForegroundLocationService: Disable failed - $e');
    }
  }
  
  /// Start the foreground service.
  Future<bool> start() async {
    if (!isSupported || _isRunning) return _isRunning;
    
    try {
      final result = await FlutterForegroundTask.startService(
        notificationTitle: 'Coordinate Tracking',
        notificationText: 'Tracking your country visits...',
        callback: startForegroundCallback,
      );
      
      // startService returns ServiceRequestResult in 8.x
      // Check if it's a success by checking the enum name
      _isRunning = result.toString().contains('success');
      debugPrint('ForegroundLocationService: Start result - $result');
      return _isRunning;
    } catch (e) {
      debugPrint('ForegroundLocationService: Start failed - $e');
      return false;
    }
  }
  
  /// Stop the foreground service.
  Future<void> stop() async {
    if (!isSupported || !_isRunning) return;
    
    try {
      await FlutterForegroundTask.stopService();
      _isRunning = false;
      debugPrint('ForegroundLocationService: Stopped');
    } catch (e) {
      debugPrint('ForegroundLocationService: Stop failed - $e');
    }
  }
  
  /// Get current status for health screen.
  Map<String, dynamic> getStatus() {
    return {
      'isSupported': isSupported,
      'isEnabled': _isEnabled,
      'isRunning': _isRunning,
    };
  }
}


