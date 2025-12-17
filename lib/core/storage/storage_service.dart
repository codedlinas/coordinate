import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/models.dart';

class StorageService {
  static const String visitsBoxName = 'country_visits';
  static const String settingsBoxName = 'app_settings';
  static const String settingsKey = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(CountryVisitAdapter());
    Hive.registerAdapter(LocationAccuracyAdapter());
    Hive.registerAdapter(AppSettingsAdapter());

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


