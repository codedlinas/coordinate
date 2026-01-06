import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/logging/app_logger.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import 'location_service.dart';
import 'notification_service.dart';

class TrackingService extends ChangeNotifier {
  final LocationService _locationService;
  final VisitsRepository _visitsRepository;
  final SettingsRepository _settingsRepository;

  Timer? _trackingTimer;
  bool _isTracking = false;
  CountryVisit? _currentVisit;
  bool _initialized = false;

  TrackingService(
    this._locationService,
    this._visitsRepository,
    this._settingsRepository,
  );

  bool get isTracking => _isTracking;

  CountryVisit? get currentVisit => _currentVisit;

  /// Initialize tracking service and restore previous tracking state.
  /// Call this once after app startup.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Check if tracking was previously enabled
    final settings = _settingsRepository.getSettings();
    if (settings.trackingEnabled) {
      AppLogger.tracking('Restoring tracking state - was enabled');
      try {
        await startTracking(restoring: true);
      } catch (e) {
        AppLogger.error('Tracking', 'Failed to restore tracking state', e);
        // If we can't restore (e.g., permissions revoked), disable the setting
        await _settingsRepository.setTrackingEnabled(false);
      }
    }
  }

  Future<void> startTracking({bool restoring = false}) async {
    if (_isTracking) return;

    // Check permissions
    final hasPermission = await _locationService.checkPermission();
    if (!hasPermission) {
      throw Exception('Location permissions not granted');
    }

    _isTracking = true;
    
    // Persist the tracking state (skip if just restoring to avoid redundant write)
    if (!restoring) {
      await _settingsRepository.setTrackingEnabled(true);
    }
    
    notifyListeners();

    // Do initial check
    await _checkLocation();

    // Get interval from settings
    final settings = _settingsRepository.getSettings();
    final interval = Duration(minutes: settings.trackingIntervalMinutes);

    // Set up periodic checking
    _trackingTimer = Timer.periodic(interval, (_) async {
      await _checkLocation();
    });
  }

  Future<void> stopTracking() async {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _isTracking = false;
    
    // Persist the tracking state
    await _settingsRepository.setTrackingEnabled(false);
    
    notifyListeners();
  }

  Future<void> _checkLocation() async {
    try {
      final settings = _settingsRepository.getSettings();
      final locationInfo = await _locationService.getCurrentLocationInfo(
        accuracy: settings.accuracy,
      );

      if (locationInfo == null || locationInfo.latitude == null) {
        AppLogger.tracking('No location info available');
        return;
      }

      AppLogger.tracking('Got location - ${locationInfo.countryName} (${locationInfo.countryCode})');

      final currentVisit = _visitsRepository.getCurrentVisit();

      if (currentVisit == null) {
        // No current visit - start a new one
        AppLogger.tracking('Starting new visit for ${locationInfo.countryName}');
        await _startNewVisit(locationInfo, isCountryChange: false);
      } else if (currentVisit.countryCode != locationInfo.countryCode) {
        // Country changed - end current and start new
        AppLogger.tracking('Country changed from ${currentVisit.countryName} to ${locationInfo.countryName}');
        await _endCurrentVisit();
        await _startNewVisit(locationInfo, isCountryChange: true);
      } else {
        AppLogger.tracking('Still in ${currentVisit.countryName}');
      }
      // Otherwise, we're still in the same country - do nothing
    } catch (e) {
      AppLogger.error('Tracking', 'Error checking location', e);
    }
  }

  Future<void> _startNewVisit(LocationInfo locationInfo, {bool isCountryChange = false}) async {
    final now = DateTime.now();
    final id = '${locationInfo.countryCode}_${now.millisecondsSinceEpoch}';

    final visit = CountryVisit(
      id: id,
      countryCode: locationInfo.countryCode,
      countryName: locationInfo.countryName,
      entryTime: now,
      entryLatitude: locationInfo.latitude!,
      entryLongitude: locationInfo.longitude!,
      city: locationInfo.city,
      region: locationInfo.region,
    );

    await _visitsRepository.addVisit(visit);
    _currentVisit = visit;
    AppLogger.tracking('Created new visit for ${visit.countryName} (ID: ${visit.id})');
    
    // Show country change notification if enabled
    if (isCountryChange) {
      final settings = _settingsRepository.getSettings();
      if (settings.notificationsEnabled && settings.countryChangeNotifications) {
        await NotificationService().showCountryChangeNotification(
          countryName: locationInfo.countryName,
          countryCode: locationInfo.countryCode,
        );
      }
    }
    
    notifyListeners();
  }

  Future<void> _endCurrentVisit() async {
    final current = _visitsRepository.getCurrentVisit();
    if (current != null) {
      await _visitsRepository.endCurrentVisit(DateTime.now());
      _currentVisit = _visitsRepository.getCurrentVisit();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
