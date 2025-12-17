import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import 'location_service.dart';

class TrackingService extends ChangeNotifier {
  final LocationService _locationService;
  final VisitsRepository _visitsRepository;
  final SettingsRepository _settingsRepository;

  Timer? _trackingTimer;
  bool _isTracking = false;
  CountryVisit? _currentVisit;

  TrackingService(
    this._locationService,
    this._visitsRepository,
    this._settingsRepository,
  );

  bool get isTracking => _isTracking;

  CountryVisit? get currentVisit => _currentVisit;

  Future<void> startTracking() async {
    if (_isTracking) return;

    // Check permissions
    final hasPermission = await _locationService.checkPermission();
    if (!hasPermission) {
      throw Exception('Location permissions not granted');
    }

    _isTracking = true;
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
    notifyListeners();
  }

  Future<void> _checkLocation() async {
    try {
      final settings = _settingsRepository.getSettings();
      final locationInfo = await _locationService.getCurrentLocationInfo(
        accuracy: settings.accuracy,
      );

      if (locationInfo == null || locationInfo.latitude == null) {
        debugPrint('Tracking: No location info available');
        return;
      }

      debugPrint('Tracking: Got location - ${locationInfo.countryName} (${locationInfo.countryCode})');

      final currentVisit = _visitsRepository.getCurrentVisit();

      if (currentVisit == null) {
        // No current visit - start a new one
        debugPrint('Tracking: Starting new visit for ${locationInfo.countryName}');
        await _startNewVisit(locationInfo);
      } else if (currentVisit.countryCode != locationInfo.countryCode) {
        // Country changed - end current and start new
        debugPrint('Tracking: Country changed from ${currentVisit.countryName} to ${locationInfo.countryName}');
        await _endCurrentVisit();
        await _startNewVisit(locationInfo);
      } else {
        debugPrint('Tracking: Still in ${currentVisit.countryName}');
      }
      // Otherwise, we're still in the same country - do nothing
    } catch (e) {
      debugPrint('Tracking error: $e');
    }
  }

  Future<void> _startNewVisit(LocationInfo locationInfo) async {
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
    debugPrint('Tracking: Created new visit for ${visit.countryName} (ID: ${visit.id})');
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

