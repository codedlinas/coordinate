import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/models.dart';

/// Central constants for Hive box names - use these everywhere to avoid duplication
class HiveBoxNames {
  static const String visits = 'country_visits';
  static const String settings = 'app_settings';
  static const String backgroundTracking = 'background_tracking';
  
  HiveBoxNames._(); // Prevent instantiation
}

class StorageService {
  static const String visitsBoxName = HiveBoxNames.visits;
  static const String settingsBoxName = HiveBoxNames.settings;
  static const String settingsKey = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(CountryVisitAdapter());
    Hive.registerAdapter(LocationAccuracyAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
    Hive.registerAdapter(SyncStateAdapter());

    // Open boxes
    await Hive.openBox<CountryVisit>(visitsBoxName);
    await Hive.openBox<AppSettings>(settingsBoxName);
  }

  static Box<CountryVisit> get visitsBox => Hive.box<CountryVisit>(visitsBoxName);
  static Box<AppSettings> get settingsBox => Hive.box<AppSettings>(settingsBoxName);

  static Future<void> close() async {
    await Hive.close();
  }

  static Future<void> clearAllData() async {
    await visitsBox.clear();
    await settingsBox.clear();
  }
}










