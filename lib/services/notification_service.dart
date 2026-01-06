import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Service for managing local notifications.
/// 
/// Handles:
/// - Country change notifications ("Welcome to Germany!")
/// - Travel reminder notifications (scheduled daily reminders)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Notification IDs
  static const int countryChangeNotificationId = 1;
  static const int travelReminderNotificationId = 2;

  // Channel IDs
  static const String countryChangeChannelId = 'country_change';
  static const String travelReminderChannelId = 'travel_reminder';

  /// Initialize the notification service.
  /// Call this once at app startup.
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data for scheduled notifications
    tz_data.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We'll request manually
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels on Android
    if (Platform.isAndroid) {
      await _createAndroidChannels();
    }

    _initialized = true;
    debugPrint('NotificationService: Initialized successfully');
  }

  /// Request notification permissions.
  /// Returns true if permissions were granted.
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return result ?? false;
    }
    return false;
  }

  /// Check if notifications are permitted.
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return result ?? false;
    }
    // iOS doesn't have a simple check, assume enabled if we've requested
    return true;
  }

  /// Show a country change notification.
  /// 
  /// [countryName] - The name of the country (e.g., "Germany")
  /// [countryCode] - The ISO country code (e.g., "DE") for flag emoji
  Future<void> showCountryChangeNotification({
    required String countryName,
    required String countryCode,
  }) async {
    if (!_initialized) {
      debugPrint('NotificationService: Not initialized, skipping notification');
      return;
    }

    final flagEmoji = _countryCodeToEmoji(countryCode);
    
    final androidDetails = AndroidNotificationDetails(
      countryChangeChannelId,
      'Country Changes',
      channelDescription: 'Notifications when you enter a new country',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      ticker: 'Welcome to $countryName!',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      countryChangeNotificationId,
      'Welcome to $countryName! $flagEmoji',
      'Your trip is being tracked.',
      details,
    );

    debugPrint('NotificationService: Showed country change notification for $countryName');
  }

  /// Show a travel reminder notification.
  Future<void> showTravelReminderNotification() async {
    if (!_initialized) return;

    final androidDetails = AndroidNotificationDetails(
      travelReminderChannelId,
      'Travel Reminders',
      channelDescription: 'Reminders to open Coordinate when traveling',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      travelReminderNotificationId,
      'Traveling today? ✈️',
      'Open Coordinate to track your trip!',
      details,
    );

    debugPrint('NotificationService: Showed travel reminder notification');
  }

  /// Schedule a daily travel reminder notification.
  /// 
  /// [hour] - Hour of day (0-23)
  /// [minute] - Minute (0-59)
  Future<void> scheduleDailyTravelReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) return;

    // Cancel any existing scheduled reminder
    await cancelTravelReminder();

    final androidDetails = AndroidNotificationDetails(
      travelReminderChannelId,
      'Travel Reminders',
      channelDescription: 'Reminders to open Coordinate when traveling',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule daily at the specified time
    await _notifications.zonedSchedule(
      travelReminderNotificationId,
      'Traveling today? ✈️',
      'Open Coordinate to track your trip!',
      _nextInstanceOfTime(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );

    debugPrint('NotificationService: Scheduled daily travel reminder for $hour:${minute.toString().padLeft(2, '0')}');
  }

  /// Cancel the scheduled travel reminder.
  Future<void> cancelTravelReminder() async {
    await _notifications.cancel(travelReminderNotificationId);
    debugPrint('NotificationService: Cancelled travel reminder');
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    debugPrint('NotificationService: Cancelled all notifications');
  }

  // Private methods

  Future<void> _createAndroidChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Country change channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        countryChangeChannelId,
        'Country Changes',
        description: 'Notifications when you enter a new country',
        importance: Importance.high,
      ),
    );

    // Travel reminder channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        travelReminderChannelId,
        'Travel Reminders',
        description: 'Reminders to open Coordinate when traveling',
        importance: Importance.defaultImportance,
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to specific screen
    debugPrint('NotificationService: Notification tapped: ${response.payload}');
  }

  /// Convert a country code to a flag emoji.
  /// Uses regional indicator symbols.
  String _countryCodeToEmoji(String countryCode) {
    if (countryCode.length != 2) return '🌍';
    
    final code = countryCode.toUpperCase();
    final firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    
    return String.fromCharCodes([firstLetter, secondLetter]);
  }
}

