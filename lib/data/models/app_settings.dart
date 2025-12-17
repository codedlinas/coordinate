import 'package:hive/hive.dart';

part 'app_settings.g.dart';

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

  AppSettings({
    this.accuracy = LocationAccuracy.medium,
    this.notificationsEnabled = true,
    this.countryChangeNotifications = true,
    this.weeklyDigestNotifications = false,
    this.trackingIntervalMinutes = 15,
    this.trackingEnabled = false,
    this.lastTrackingTime,
  });

  AppSettings copyWith({
    LocationAccuracy? accuracy,
    bool? notificationsEnabled,
    bool? countryChangeNotifications,
    bool? weeklyDigestNotifications,
    int? trackingIntervalMinutes,
    bool? trackingEnabled,
    DateTime? lastTrackingTime,
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
}


