import '../../core/storage/storage_service.dart';
import '../models/models.dart';

class SettingsRepository {
  static const String _settingsKey = 'app_settings';

  AppSettings getSettings() {
    final settings = StorageService.settingsBox.get(_settingsKey);
    return settings ?? AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await StorageService.settingsBox.put(_settingsKey, settings);
  }

  Future<void> updateAccuracy(LocationAccuracy accuracy) async {
    final settings = getSettings();
    final updated = settings.copyWith(accuracy: accuracy);
    await saveSettings(updated);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final settings = getSettings();
    final updated = settings.copyWith(notificationsEnabled: enabled);
    await saveSettings(updated);
  }

  Future<void> setCountryChangeNotifications(bool enabled) async {
    final settings = getSettings();
    final updated = settings.copyWith(countryChangeNotifications: enabled);
    await saveSettings(updated);
  }

  Future<void> setWeeklyDigestNotifications(bool enabled) async {
    final settings = getSettings();
    final updated = settings.copyWith(weeklyDigestNotifications: enabled);
    await saveSettings(updated);
  }

  Future<void> setTrackingInterval(int minutes) async {
    final settings = getSettings();
    final updated = settings.copyWith(trackingIntervalMinutes: minutes);
    await saveSettings(updated);
  }

  Future<void> setTrackingEnabled(bool enabled) async {
    final settings = getSettings();
    final updated = settings.copyWith(trackingEnabled: enabled);
    await saveSettings(updated);
  }

  Future<void> updateLastTrackingTime(DateTime time) async {
    final settings = getSettings();
    final updated = settings.copyWith(lastTrackingTime: time);
    await saveSettings(updated);
  }

  Future<void> resetSettings() async {
    await saveSettings(AppSettings());
  }
}




