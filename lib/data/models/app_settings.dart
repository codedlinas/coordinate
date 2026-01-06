import 'package:hive/hive.dart';

part 'app_settings.g.dart';

// ⚠️ MIGRATION NOTE: The generated app_settings.g.dart file has been manually
// modified to handle null values for fields 7-9 (travel reminder settings).
// This allows migration from older app data that doesn't have these fields.
// If you regenerate with `build_runner`, you MUST re-apply the null-safe fix:
//   travelRemindersEnabled: (fields[7] as bool?) ?? false,
//   travelReminderHour: (fields[8] as int?) ?? 8,
//   travelReminderMinute: (fields[9] as int?) ?? 0,

@HiveType(typeId: 1)
enum LocationAccuracy {
  @HiveField(0)
  low, // ~500m, battery efficient
  @HiveField(1)
  medium, // ~100m, balanced
  @HiveField(2)
  high, // ~10m, higher battery usage
}

@HiveType(typeId: 2)
class AppSettings extends HiveObject {
  @HiveField(0)
  LocationAccuracy accuracy;

  @HiveField(1)
  bool notificationsEnabled;

  @HiveField(2)
  bool countryChangeNotifications;

  @HiveField(3)
  bool weeklyDigestNotifications;

  @HiveField(4)
  int trackingIntervalMinutes;

  @HiveField(5)
  bool trackingEnabled;

  @HiveField(6)
  DateTime? lastTrackingTime;

  @HiveField(7)
  bool travelRemindersEnabled;

  @HiveField(8)
  int travelReminderHour;

  @HiveField(9)
  int travelReminderMinute;

  AppSettings({
    this.accuracy = LocationAccuracy.medium,
    this.notificationsEnabled = true,
    this.countryChangeNotifications = true,
    this.weeklyDigestNotifications = false,
    this.trackingIntervalMinutes = 15,
    this.trackingEnabled = false,
    this.lastTrackingTime,
    this.travelRemindersEnabled = false,
    this.travelReminderHour = 8,  // Default: 8:00 AM
    this.travelReminderMinute = 0,
  });

  AppSettings copyWith({
    LocationAccuracy? accuracy,
    bool? notificationsEnabled,
    bool? countryChangeNotifications,
    bool? weeklyDigestNotifications,
    int? trackingIntervalMinutes,
    bool? trackingEnabled,
    DateTime? lastTrackingTime,
    bool? travelRemindersEnabled,
    int? travelReminderHour,
    int? travelReminderMinute,
  }) {
    return AppSettings(
      accuracy: accuracy ?? this.accuracy,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      countryChangeNotifications:
          countryChangeNotifications ?? this.countryChangeNotifications,
      weeklyDigestNotifications:
          weeklyDigestNotifications ?? this.weeklyDigestNotifications,
      trackingIntervalMinutes:
          trackingIntervalMinutes ?? this.trackingIntervalMinutes,
      trackingEnabled: trackingEnabled ?? this.trackingEnabled,
      lastTrackingTime: lastTrackingTime ?? this.lastTrackingTime,
      travelRemindersEnabled: travelRemindersEnabled ?? this.travelRemindersEnabled,
      travelReminderHour: travelReminderHour ?? this.travelReminderHour,
      travelReminderMinute: travelReminderMinute ?? this.travelReminderMinute,
    );
  }

  String get accuracyDescription {
    switch (accuracy) {
      case LocationAccuracy.low:
        return 'Battery Saver (~500m)';
      case LocationAccuracy.medium:
        return 'Balanced (~100m)';
      case LocationAccuracy.high:
        return 'High Precision (~10m)';
    }
  }

  String get trackingIntervalDescription {
    if (trackingIntervalMinutes < 60) {
      return 'Every $trackingIntervalMinutes minutes';
    } else {
      final hours = trackingIntervalMinutes ~/ 60;
      return 'Every $hours hour${hours > 1 ? 's' : ''}';
    }
  }

  /// Get formatted travel reminder time string.
  String get travelReminderTimeDescription {
    final hour = travelReminderHour;
    final minute = travelReminderMinute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}










