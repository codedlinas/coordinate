import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/models.dart';
import '../data/models/trip.dart';
import '../data/repositories/repositories.dart';
import '../services/auth_service.dart';
import '../services/background_location_service.dart';
import '../services/foreground_location_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/profile_sync_service.dart';
import '../services/sync_service.dart';
import '../services/time_ticker_service.dart';

// Repository providers
final visitsRepositoryProvider = Provider((ref) => VisitsRepository());
final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

// Auth service provider (singleton)
final authServiceProvider = Provider((ref) => AuthService.instance);

// Auth state provider - stream of authentication state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  return AuthService.instance.authStateChanges;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.session?.user);
});

// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// Sync service provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final visitsRepo = ref.watch(visitsRepositoryProvider);
  final authService = ref.watch(authServiceProvider);
  final service = SyncService(visitsRepo, authService);
  
  // Dispose when provider is disposed
  ref.onDispose(() => service.dispose());
  
  return service;
});

// Profile sync service provider
final profileSyncServiceProvider = Provider<ProfileSyncService>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final authService = ref.watch(authServiceProvider);
  return ProfileSyncService(settingsRepo, authService);
});

// Sync status stream provider - listens to SyncService status changes
final syncStatusStreamProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.statusStream;
});

// Sync status provider (current status, not stream)
final syncStatusProvider = Provider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.status;
});

// Location service provider - singleton instance shared across the app
final locationServiceProvider = Provider((ref) => LocationService());

// Background location service provider
// TODO: When adding remote sync, ensure background updates are reconciled
//       with server state to avoid duplicate/conflicting segments.
final backgroundLocationServiceProvider = Provider<BackgroundLocationService>((ref) {
  final visitsRepo = ref.watch(visitsRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  return BackgroundLocationService(visitsRepo, locationService);
});

// Foreground location service provider (Android high-reliability mode)
final foregroundLocationServiceProvider = Provider<ForegroundLocationService>((ref) {
  return ForegroundLocationService();
});

// Settings state
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repository;
  final ProfileSyncService? _profileSyncService;

  SettingsNotifier(this._repository, [this._profileSyncService]) 
      : super(_repository.getSettings());

  void refresh() {
    state = _repository.getSettings();
  }
  
  /// Mark settings as modified and optionally sync to cloud.
  Future<void> _onSettingsChanged({bool shouldSync = true}) async {
    if (shouldSync && _profileSyncService != null) {
      // Mark as modified for background sync
      await _profileSyncService.markLocalSettingsModified();
      // Attempt immediate upload (fails gracefully if offline)
      await _profileSyncService.uploadSettingsNow();
    }
  }

  Future<void> setAccuracy(LocationAccuracy accuracy) async {
    await _repository.updateAccuracy(accuracy);
    refresh();
    await _onSettingsChanged();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _repository.setNotificationsEnabled(enabled);
    refresh();
    await _onSettingsChanged();
    
    // If disabling notifications, also cancel any scheduled reminders
    if (!enabled) {
      await NotificationService().cancelTravelReminder();
    } else {
      // If re-enabling and travel reminders were on, reschedule
      final settings = _repository.getSettings();
      if (settings.travelRemindersEnabled) {
        await NotificationService().scheduleDailyTravelReminder(
          hour: settings.travelReminderHour,
          minute: settings.travelReminderMinute,
        );
      }
    }
  }

  Future<void> setCountryChangeNotifications(bool enabled) async {
    await _repository.setCountryChangeNotifications(enabled);
    refresh();
    await _onSettingsChanged();
  }

  Future<void> setWeeklyDigestNotifications(bool enabled) async {
    await _repository.setWeeklyDigestNotifications(enabled);
    refresh();
    await _onSettingsChanged();
  }

  Future<void> setTrackingInterval(int minutes) async {
    await _repository.setTrackingInterval(minutes);
    refresh();
    await _onSettingsChanged();
  }

  Future<void> setTrackingEnabled(bool enabled) async {
    await _repository.setTrackingEnabled(enabled);
    refresh();
    // Don't sync trackingEnabled - it's device-specific
  }

  Future<void> setTravelRemindersEnabled(bool enabled) async {
    await _repository.setTravelRemindersEnabled(enabled);
    refresh();
    await _onSettingsChanged();
    
    // Schedule or cancel the daily reminder notification
    final notificationService = NotificationService();
    if (enabled) {
      final settings = _repository.getSettings();
      await notificationService.scheduleDailyTravelReminder(
        hour: settings.travelReminderHour,
        minute: settings.travelReminderMinute,
      );
    } else {
      await notificationService.cancelTravelReminder();
    }
  }

  Future<void> setTravelReminderTime(int hour, int minute) async {
    await _repository.setTravelReminderTime(hour, minute);
    refresh();
    await _onSettingsChanged();
    
    // Reschedule the notification with the new time (if enabled)
    final settings = _repository.getSettings();
    if (settings.travelRemindersEnabled && settings.notificationsEnabled) {
      await NotificationService().scheduleDailyTravelReminder(
        hour: hour,
        minute: minute,
      );
    }
  }

  Future<void> resetSettings() async {
    await _repository.resetSettings();
    refresh();
    await _onSettingsChanged();
  }
  
  /// Refresh settings from remote profile (e.g., after login).
  Future<void> syncFromRemote() async {
    if (_profileSyncService != null) {
      await _profileSyncService.downloadSettingsNow();
      refresh();
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final profileSyncService = ref.watch(profileSyncServiceProvider);
  return SettingsNotifier(settingsRepo, profileSyncService);
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

// Global stats provider - uses repository's cached aggregated stats
final globalStatsProvider = Provider<GlobalStats>((ref) {
  // Watch visitsProvider to trigger rebuild when visits change
  final visits = ref.watch(visitsProvider);
  final repository = ref.read(visitsRepositoryProvider);

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

// Time ticker service provider (singleton)
final _timeTickerService = TimeTickerService();

/// Stream provider that emits every 60 seconds to trigger time-based UI updates.
/// Watch this in screens that display time-relative data (e.g., "Last 24 Hours").
final timeTickerProvider = StreamProvider<DateTime>((ref) {
  _timeTickerService.start();
  ref.onDispose(() {
    // Don't stop the service on dispose - it's a singleton shared across the app
  });
  return _timeTickerService.tickStream;
});

