import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import 'location_service.dart';

/// Background task name for WorkManager
const String backgroundTaskName = 'com.coordinate.backgroundLocationCheck';

/// Callback dispatcher for WorkManager - must be top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('BackgroundLocationService: Executing background task');
      
      // Initialize Hive for background isolate
      await Hive.initFlutter();
      
      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CountryVisitAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(AppSettingsAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(LocationAccuracyAdapter());
      }
      
      // Open boxes
      await Hive.openBox<CountryVisit>('visits');
      await Hive.openBox<AppSettings>('settings');
      final bgBox = await Hive.openBox('background_tracking');
      
      // Check location
      final locationService = LocationService();
      final visitsRepository = VisitsRepository();
      
      final hasPermission = await locationService.checkPermission();
      if (!hasPermission) {
        debugPrint('BackgroundLocationService: No permission');
        await bgBox.put('lastError', 'No location permission');
        return true;
      }
      
      final locationInfo = await locationService.getCurrentLocationInfo();
      if (locationInfo == null || locationInfo.countryCode.isEmpty) {
        debugPrint('BackgroundLocationService: Could not get location');
        await bgBox.put('lastError', 'Could not determine location');
        return true;
      }
      
      // Update last check time
      await bgBox.put('lastUpdate', DateTime.now().toUtc().toIso8601String());
      await bgBox.put('lastError', null);
      
      // Get current visit
      final currentVisit = visitsRepository.getCurrentVisit();
      final lastCountryCode = bgBox.get('lastCountryCode') as String?;
      
      // Check if country changed
      if (currentVisit == null || currentVisit.countryCode != locationInfo.countryCode) {
        debugPrint('BackgroundLocationService: Country change detected');
        
        final now = DateTime.now().toUtc();
        
        // End current visit if exists
        if (currentVisit != null) {
          await visitsRepository.endCurrentVisit(now);
        }
        
        // Start new visit
        final id = '${locationInfo.countryCode}_${now.millisecondsSinceEpoch}';
        final visit = CountryVisit(
          id: id,
          countryCode: locationInfo.countryCode,
          countryName: locationInfo.countryName,
          entryTime: now,
          entryLatitude: locationInfo.latitude ?? 0,
          entryLongitude: locationInfo.longitude ?? 0,
          city: locationInfo.city,
          region: locationInfo.region,
        );
        
        await visitsRepository.addVisit(visit);
        await bgBox.put('lastCountryCode', locationInfo.countryCode);
        
        // TODO: Trigger local notification for country change
      } else {
        debugPrint('BackgroundLocationService: Still in ${locationInfo.countryName}');
      }
      
      return true;
    } catch (e) {
      debugPrint('BackgroundLocationService: Error in background task: $e');
      return false;
    }
  });
}

/// Service for background location tracking focused on country changes only.
/// 
/// WARNING: Background location has significant OS limitations:
/// - Android: WorkManager handles periodic tasks, minimum 15 min interval
/// - iOS: Background fetch is unreliable, iOS controls frequency
/// - Both: Battery optimization can prevent background execution
/// 
/// TODO: Test on various Android OEMs (Samsung, Xiaomi, etc.) which have
/// aggressive battery optimization that can kill background tasks.
class BackgroundLocationService extends ChangeNotifier {
  final VisitsRepository _visitsRepository;
  final LocationService _locationService;
  
  bool _isBackgroundEnabled = false;
  DateTime? _lastBackgroundUpdate;
  String? _lastError;
  String _permissionStatus = 'unknown';
  
  // Persistence box for background state
  static const String _boxName = 'background_tracking';
  Box? _box;
  
  BackgroundLocationService(this._visitsRepository, this._locationService);
  
  bool get isBackgroundEnabled => _isBackgroundEnabled;
  DateTime? get lastBackgroundUpdate => _lastBackgroundUpdate;
  String? get lastError => _lastError;
  String get permissionStatus => _permissionStatus;
  
  /// Initialize the background location service.
  /// Call this once at app startup.
  Future<void> initialize() async {
    try {
      _box = await Hive.openBox(_boxName);
      _isBackgroundEnabled = _box?.get('enabled', defaultValue: false) ?? false;
      
      final lastUpdateStr = _box?.get('lastUpdate') as String?;
      _lastBackgroundUpdate = lastUpdateStr != null 
          ? DateTime.tryParse(lastUpdateStr) 
          : null;
      _lastError = _box?.get('lastError') as String?;
      
      await _updatePermissionStatus();
      
      // Initialize WorkManager
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      
      // If was enabled before, restart
      if (_isBackgroundEnabled) {
        await _startBackgroundTracking();
      }
      
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to initialize: $e';
      debugPrint('BackgroundLocationService: $_lastError');
      notifyListeners();
    }
  }
  
  Future<void> _updatePermissionStatus() async {
    try {
      final permission = await geo.Geolocator.checkPermission();
      
      switch (permission) {
        case geo.LocationPermission.denied:
          _permissionStatus = 'Denied';
          break;
        case geo.LocationPermission.deniedForever:
          _permissionStatus = 'Denied Forever';
          break;
        case geo.LocationPermission.whileInUse:
          _permissionStatus = 'When In Use';
          break;
        case geo.LocationPermission.always:
          _permissionStatus = 'Always';
          break;
        case geo.LocationPermission.unableToDetermine:
          _permissionStatus = 'Unknown';
          break;
      }
    } catch (e) {
      _permissionStatus = 'Error: $e';
    }
  }
  
  /// Enable background location tracking.
  /// Returns true if successfully enabled.
  Future<bool> enableBackgroundTracking() async {
    try {
      _lastError = null;
      
      // Check permission first
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        _lastError = 'Location permission denied. Please enable in Settings.';
        await _updatePermissionStatus();
        notifyListeners();
        return false;
      }
      
      // For background tracking, we ideally want "always" permission
      // but "when in use" can work with foreground service on Android
      if (permission == geo.LocationPermission.whileInUse) {
        // Try to request "always" permission
        // Note: On iOS this requires a second permission request
        debugPrint('BackgroundLocationService: Have "when in use", background may be limited');
      }
      
      await _startBackgroundTracking();
      
      _isBackgroundEnabled = true;
      await _box?.put('enabled', true);
      await _updatePermissionStatus();
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to enable: $e';
      debugPrint('BackgroundLocationService: $_lastError');
      notifyListeners();
      return false;
    }
  }
  
  Future<void> _startBackgroundTracking() async {
    try {
      // Register periodic task
      // WARNING: Android minimum is 15 minutes, iOS is unreliable
      // TODO: On Android, consider using a foreground service for more reliable tracking
      await Workmanager().registerPeriodicTask(
        backgroundTaskName,
        backgroundTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 5),
      );
      
      debugPrint('BackgroundLocationService: Periodic task registered');
    } catch (e) {
      debugPrint('BackgroundLocationService: Start failed - $e');
      rethrow;
    }
  }
  
  /// Disable background location tracking.
  Future<void> disableBackgroundTracking() async {
    try {
      await Workmanager().cancelByUniqueName(backgroundTaskName);
      _isBackgroundEnabled = false;
      await _box?.put('enabled', false);
      _lastError = null;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to disable: $e';
      debugPrint('BackgroundLocationService: $_lastError');
      notifyListeners();
    }
  }
  
  /// Get current tracking state info for health screen.
  Future<Map<String, dynamic>> getHealthInfo() async {
    await _updatePermissionStatus();
    
    // Reload from box in case background task updated it
    _lastBackgroundUpdate = _box?.get('lastUpdate') != null
        ? DateTime.tryParse(_box!.get('lastUpdate'))
        : null;
    _lastError = _box?.get('lastError') as String?;
    final lastCountry = _box?.get('lastCountryCode') as String?;
    
    return {
      'isEnabled': _isBackgroundEnabled,
      'isTracking': _isBackgroundEnabled,
      'permissionStatus': _permissionStatus,
      'lastUpdate': _lastBackgroundUpdate?.toIso8601String(),
      'lastError': _lastError,
      'currentCountry': lastCountry,
      'isMoving': null, // Not available with WorkManager approach
    };
  }
  
  /// Force a location check now (useful for testing).
  Future<void> forceLocationCheck() async {
    try {
      _lastError = null;
      
      final hasPermission = await _locationService.checkPermission();
      if (!hasPermission) {
        _lastError = 'No location permission';
        notifyListeners();
        return;
      }
      
      final locationInfo = await _locationService.getCurrentLocationInfo();
      if (locationInfo == null || locationInfo.countryCode.isEmpty) {
        _lastError = 'Could not determine location';
        notifyListeners();
        return;
      }
      
      _lastBackgroundUpdate = DateTime.now().toUtc();
      await _box?.put('lastUpdate', _lastBackgroundUpdate!.toIso8601String());
      
      // Check for country change
      final currentVisit = _visitsRepository.getCurrentVisit();
      
      if (currentVisit == null || currentVisit.countryCode != locationInfo.countryCode) {
        final now = DateTime.now().toUtc();
        
        if (currentVisit != null) {
          await _visitsRepository.endCurrentVisit(now);
        }
        
        final id = '${locationInfo.countryCode}_${now.millisecondsSinceEpoch}';
        final visit = CountryVisit(
          id: id,
          countryCode: locationInfo.countryCode,
          countryName: locationInfo.countryName,
          entryTime: now,
          entryLatitude: locationInfo.latitude ?? 0,
          entryLongitude: locationInfo.longitude ?? 0,
          city: locationInfo.city,
          region: locationInfo.region,
        );
        
        await _visitsRepository.addVisit(visit);
        await _box?.put('lastCountryCode', locationInfo.countryCode);
      }
      
      notifyListeners();
    } catch (e) {
      _lastError = 'Force check failed: $e';
      debugPrint('BackgroundLocationService: $_lastError');
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    // Don't stop background tracking on dispose - it should continue
    super.dispose();
  }
}
