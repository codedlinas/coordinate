import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../data/models/trip.dart';
import '../data/repositories/repositories.dart';
import '../services/background_location_service.dart';
import '../services/location_service.dart';

// Repository providers
final visitsRepositoryProvider = Provider((ref) => VisitsRepository());
final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

// Background location service provider
// TODO: When adding remote sync, ensure background updates are reconciled
//       with server state to avoid duplicate/conflicting segments.
final backgroundLocationServiceProvider = Provider<BackgroundLocationService>((ref) {
  final visitsRepo = ref.watch(visitsRepositoryProvider);
  final locationService = LocationService();
  return BackgroundLocationService(visitsRepo, locationService);
});

// Settings state
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(_repository.getSettings());

  void refresh() {
    state = _repository.getSettings();
  }

  Future<void> setAccuracy(LocationAccuracy accuracy) async {
    await _repository.updateAccuracy(accuracy);
    refresh();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _repository.setNotificationsEnabled(enabled);
    refresh();
  }

  Future<void> setCountryChangeNotifications(bool enabled) async {
    await _repository.setCountryChangeNotifications(enabled);
    refresh();
  }

  Future<void> setWeeklyDigestNotifications(bool enabled) async {
    await _repository.setWeeklyDigestNotifications(enabled);
    refresh();
  }

  Future<void> setTrackingInterval(int minutes) async {
    await _repository.setTrackingInterval(minutes);
    refresh();
  }

  Future<void> setTrackingEnabled(bool enabled) async {
    await _repository.setTrackingEnabled(enabled);
    refresh();
  }

  Future<void> resetSettings() async {
    await _repository.resetSettings();
    refresh();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});

// Visits state
class VisitsNotifier extends StateNotifier<List<CountryVisit>> {
  final VisitsRepository _repository;

  VisitsNotifier(this._repository) : super(_repository.getAllVisits());

  void refresh() {
    state = _repository.getAllVisits();
  }

  Future<void> addVisit(CountryVisit visit) async {
    await _repository.addVisit(visit);
    refresh();
  }

  Future<void> updateVisit(CountryVisit visit) async {
    await _repository.updateVisit(visit);
    refresh();
  }

  Future<void> deleteVisit(String id) async {
    await _repository.deleteVisit(id);
    refresh();
  }

  Future<void> endCurrentVisit(DateTime exitTime) async {
    await _repository.endCurrentVisit(exitTime);
    refresh();
  }

  Future<void> clearAllVisits() async {
    await _repository.clearAllVisits();
    refresh();
  }

  Future<int> importFromJson(List<dynamic> jsonData) async {
    final count = await _repository.importFromJson(jsonData);
    refresh();
    return count;
  }
}

final visitsProvider =
    StateNotifierProvider<VisitsNotifier, List<CountryVisit>>((ref) {
  return VisitsNotifier(ref.watch(visitsRepositoryProvider));
});

// Trips provider - derived from visits
final tripsProvider = Provider<List<Trip>>((ref) {
  final visits = ref.watch(visitsProvider);

  // TODO: When background tracking adds finer-grained segments or
  //       remote sync introduces partial segments, consider merging
  //       consecutive segments in the same country into a single Trip.
  final trips = visits.map(Trip.fromVisit).toList()
    ..sort((a, b) => b.arrivalDateUtc.compareTo(a.arrivalDateUtc));

  return trips;
});

// Current visit provider
final currentVisitProvider = Provider<CountryVisit?>((ref) {
  final visits = ref.watch(visitsProvider);
  return visits.where((v) => v.isOngoing).firstOrNull;
});

// Unique countries provider
final uniqueCountriesProvider = Provider<Set<String>>((ref) {
  final visits = ref.watch(visitsProvider);
  return visits.map((v) => v.countryCode).toSet();
});

// Country stats provider
final countryStatsProvider =
    Provider.family<CountryStats, String>((ref, countryCode) {
  final repository = ref.watch(visitsRepositoryProvider);
  final visits = repository.getVisitsForCountry(countryCode);
  final totalDuration = repository.getDurationForCountry(countryCode);

  return CountryStats(
    countryCode: countryCode,
    visits: visits,
    totalVisits: visits.length,
    totalDuration: totalDuration,
    firstVisit: visits.isNotEmpty ? visits.last.entryTime : null,
    lastVisit: visits.isNotEmpty ? visits.first.entryTime : null,
  );
});

// Stats data class
class CountryStats {
  final String countryCode;
  final List<CountryVisit> visits;
  final int totalVisits;
  final Duration totalDuration;
  final DateTime? firstVisit;
  final DateTime? lastVisit;

  CountryStats({
    required this.countryCode,
    required this.visits,
    required this.totalVisits,
    required this.totalDuration,
    this.firstVisit,
    this.lastVisit,
  });

  String get countryName =>
      visits.isNotEmpty ? visits.first.countryName : countryCode;
}

// Global stats provider
final globalStatsProvider = Provider<GlobalStats>((ref) {
  final repository = ref.watch(visitsRepositoryProvider);
  final visits = ref.watch(visitsProvider);

  return GlobalStats(
    totalCountries: repository.getTotalCountries(),
    totalVisits: visits.length,
    totalDuration: repository.getTotalDuration(),
    firstVisit: repository.getFirstVisitDate(),
    lastVisit: repository.getLastVisitDate(),
  );
});

class GlobalStats {
  final int totalCountries;
  final int totalVisits;
  final Duration totalDuration;
  final DateTime? firstVisit;
  final DateTime? lastVisit;

  GlobalStats({
    required this.totalCountries,
    required this.totalVisits,
    required this.totalDuration,
    this.firstVisit,
    this.lastVisit,
  });
}

