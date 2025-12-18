import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import 'location_service.dart';

/// Background task name for WorkManager
const String backgroundTaskName = 'com.coordinate.backgroundLocationCheck';

/// Box names - must match StorageService
const String _visitsBoxName = 'country_visits';
const String _settingsBoxName = 'app_settings';
const String _bgTrackingBoxName = 'background_tracking';

/// Number of consecutive checks required to confirm a country change.
/// This prevents flip-flopping near borders.
const int _requiredConfirmationChecks = 2;

/// Alternative: time threshold to confirm country change (15 minutes).
/// If the pending country persists for this duration, commit the change.
const Duration _confirmationTimeThreshold = Duration(minutes: 15);

/// Lock timeout - if a task holds the lock for longer than this, it's considered stale.
/// This prevents deadlocks if a task crashes without releasing the lock.
const Duration _lockTimeout = Duration(minutes: 5);

/// Try to acquire the task lock. Returns true if lock was acquired.
/// Returns false if another task is currently running.
Future<bool> _tryAcquireLock(Box bgBox) async {
  final isRunning = bgBox.get('isRunning') as bool? ?? false;
  final lockTimeStr = bgBox.get('lockAcquiredAt') as String?;
  
  if (isRunning && lockTimeStr != null) {
    final lockTime = DateTime.tryParse(lockTimeStr);
    if (lockTime != null) {
      final elapsed = DateTime.now().toUtc().difference(lockTime);
      if (elapsed < _lockTimeout) {
        debugPrint('BackgroundLocationService: Lock held by another task (${elapsed.inSeconds}s ago)');
        return false;
      }
      debugPrint('BackgroundLocationService: Stale lock detected, overriding');
    }
  }
  
  // Acquire the lock
  await bgBox.put('isRunning', true);
  await bgBox.put('lockAcquiredAt', DateTime.now().toUtc().toIso8601String());
  debugPrint('BackgroundLocationService: Lock acquired');
  return true;
}

/// Release the task lock.
Future<void> _releaseLock(Box bgBox) async {
  await bgBox.put('isRunning', false);
  await bgBox.delete('lockAcquiredAt');
  debugPrint('BackgroundLocationService: Lock released');
}

/// Initialize Hive safely for background isolate.
/// Uses path_provider instead of Hive.initFlutter() which can fail in isolates.
Future<void> _initHiveForBackground() async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    Hive.init(appDir.path);
    debugPrint('BackgroundLocationService: Hive initialized at ${appDir.path}');
  } catch (e) {
    debugPrint('BackgroundLocationService: Hive init error: $e');
    rethrow;
  }
}

/// Register Hive adapters if not already registered.
/// TypeIds are fixed and must never change to avoid data corruption.
void _registerAdaptersIfNeeded() {
  // TypeId 0: CountryVisit
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(CountryVisitAdapter());
  }
  // TypeId 1: LocationAccuracy
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(LocationAccuracyAdapter());
  }
  // TypeId 2: AppSettings
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(AppSettingsAdapter());
  }
}

/// Result of checking if a country change should be committed.
class _CountryChangeResult {
  final bool shouldCommit;
  final String? pendingCountry;
  final int pendingCount;
  final DateTime? pendingFirstSeen;
  
  _CountryChangeResult({
    required this.shouldCommit,
    this.pendingCountry,
    this.pendingCount = 0,
    this.pendingFirstSeen,
  });
}

/// Check if a country change should be committed based on debounce rules.
/// Returns whether to commit and updates pending state.
_CountryChangeResult _checkCountryChangeDebounce({
  required Box bgBox,
  required String? currentCountryCode,
  required String detectedCountryCode,
}) {
  // If no change detected, clear any pending state
  if (currentCountryCode == detectedCountryCode) {
    return _CountryChangeResult(
      shouldCommit: false,
      pendingCountry: null,
      pendingCount: 0,
    );
  }
  
  // Country change detected - check debounce state
  final pendingCountry = bgBox.get('pendingCountryCode') as String?;
  final pendingCount = bgBox.get('pendingCountryCheckCount') as int? ?? 0;
  final pendingFirstSeenStr = bgBox.get('pendingCountryFirstSeen') as String?;
  final pendingFirstSeen = pendingFirstSeenStr != null 
      ? DateTime.tryParse(pendingFirstSeenStr) 
      : null;
  
  // If this is a new pending country (different from what we're tracking)
  if (pendingCountry != detectedCountryCode) {
    debugPrint('BackgroundLocationService: New pending country: $detectedCountryCode (was: $pendingCountry)');
    return _CountryChangeResult(
      shouldCommit: false,
      pendingCountry: detectedCountryCode,
      pendingCount: 1,
      pendingFirstSeen: DateTime.now().toUtc(),
    );
  }
  
  // Same pending country - increment count
  final newCount = pendingCount + 1;
  final now = DateTime.now().toUtc();
  
  // Check if we should commit:
  // 1. Required number of consecutive checks reached, OR
  // 2. Pending country has been detected for longer than time threshold
  final timeConfirmed = pendingFirstSeen != null && 
      now.difference(pendingFirstSeen) >= _confirmationTimeThreshold;
  final countConfirmed = newCount >= _requiredConfirmationChecks;
  
  if (countConfirmed || timeConfirmed) {
    debugPrint('BackgroundLocationService: Country change confirmed '
        '(count: $newCount, time: ${pendingFirstSeen != null ? now.difference(pendingFirstSeen).inMinutes : 0}min)');
    return _CountryChangeResult(
      shouldCommit: true,
      pendingCountry: null,  // Clear pending on commit
      pendingCount: 0,
    );
  }
  
  debugPrint('BackgroundLocationService: Pending country $detectedCountryCode '
      '(count: $newCount/$_requiredConfirmationChecks)');
  return _CountryChangeResult(
    shouldCommit: false,
    pendingCountry: detectedCountryCode,
    pendingCount: newCount,
    pendingFirstSeen: pendingFirstSeen,
  );
}

/// Callback dispatcher for WorkManager - must be top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    Box? bgBox;
    bool lockAcquired = false;
    
    try {
      debugPrint('BackgroundLocationService: Executing background task');
      
      // Initialize Hive safely for background isolate
      await _initHiveForBackground();
      _registerAdaptersIfNeeded();
      
      // Open boxes with correct names matching StorageService
      final visitsBox = await Hive.openBox<CountryVisit>(_visitsBoxName);
      await Hive.openBox<AppSettings>(_settingsBoxName);
      bgBox = await Hive.openBox(_bgTrackingBoxName);
      
      // Try to acquire lock - exit early if another task is running
      lockAcquired = await _tryAcquireLock(bgBox);
      if (!lockAcquired) {
        debugPrint('BackgroundLocationService: Skipping - another task is running');
        return true; // Return true to not trigger retry
      }
      
      // Check location
      final locationService = LocationService();
      
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
      
      // Update last check time and geocode info
      final now = DateTime.now().toUtc();
      await bgBox.put('lastUpdate', now.toIso8601String());
      await bgBox.put('lastGeocodeTime', now.toIso8601String());
      await bgBox.put('lastError', null);
      
      // Store last coordinates (for debugging only)
      if (locationInfo.latitude != null && locationInfo.longitude != null) {
        await bgBox.put('lastLatitude', locationInfo.latitude);
        await bgBox.put('lastLongitude', locationInfo.longitude);
      }
      
      // Get current visit directly from box (not through StorageService)
      final currentVisit = visitsBox.values
          .cast<CountryVisit?>()
          .where((v) => v?.exitTime == null)
          .firstOrNull;
      
      final currentCountryCode = currentVisit?.countryCode;
      
      // Check country change with debounce to prevent border flip-flop
      final debounceResult = _checkCountryChangeDebounce(
        bgBox: bgBox,
        currentCountryCode: currentCountryCode,
        detectedCountryCode: locationInfo.countryCode,
      );
      
      // Update pending state in box
      if (debounceResult.pendingCountry != null) {
        await bgBox.put('pendingCountryCode', debounceResult.pendingCountry);
        await bgBox.put('pendingCountryCheckCount', debounceResult.pendingCount);
        if (debounceResult.pendingFirstSeen != null) {
          await bgBox.put('pendingCountryFirstSeen', debounceResult.pendingFirstSeen!.toIso8601String());
        }
      } else {
        // Clear pending state
        await bgBox.delete('pendingCountryCode');
        await bgBox.delete('pendingCountryCheckCount');
        await bgBox.delete('pendingCountryFirstSeen');
      }
      
      // Only commit country change if debounce confirms it
      if (debounceResult.shouldCommit) {
        debugPrint('BackgroundLocationService: Committing country change to ${locationInfo.countryCode}');
        
        // End current visit if exists
        if (currentVisit != null) {
          final updated = currentVisit.copyWith(exitTime: now);
          await visitsBox.put(currentVisit.id, updated);
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
        
        await visitsBox.put(id, visit);
        await bgBox.put('lastCountryCode', locationInfo.countryCode);
        await bgBox.put('lastCountrySource', 'fresh');
        
        // TODO: Trigger local notification for country change
      } else if (currentCountryCode == locationInfo.countryCode) {
        debugPrint('BackgroundLocationService: Still in ${locationInfo.countryName}');
        await bgBox.put('lastCountrySource', 'cached');
      } else {
        debugPrint('BackgroundLocationService: Waiting for country change confirmation...');
      }
      
      return true;
    } catch (e) {
      debugPrint('BackgroundLocationService: Error in background task: $e');
      return false;
    } finally {
      // Always release the lock
      if (lockAcquired && bgBox != null) {
        await _releaseLock(bgBox);
      }
    }
  });
}

/// Service for background location tracking focused on country changes only.
/// 
/// Platform Strategy:
/// - Android: WorkManager for periodic background checks (+ optional foreground service)
/// - iOS: Foreground-only tracking (WorkManager/BGTaskScheduler is unreliable on iOS)
/// 
/// WARNING: Background location has significant OS limitations:
/// - Android: Battery optimization, Doze mode, OEM-specific restrictions
/// - iOS: Background fetch is controlled by iOS and may be very infrequent
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
  
  /// Returns true if running on iOS where background tracking is limited to foreground-only.
  static bool get isIOS => Platform.isIOS;
  
  /// Returns true if running on Android where WorkManager background tracking is available.
  static bool get isAndroid => Platform.isAndroid;
  
  /// Returns a user-friendly description of the tracking strategy for this platform.
  static String get platformTrackingDescription {
    if (isIOS) {
      return 'iOS: Foreground tracking only. Location is checked when the app is open. '
          'For accurate tracking, open the app periodically or use manual edits.';
    } else if (isAndroid) {
      return 'Android: Background tracking via WorkManager (checks every ~15 min). '
          'For best reliability, disable battery optimization for Coordinate.';
    } else {
      return 'Background tracking may be limited on this platform.';
    }
  }
  
  /// Returns true if true background tracking is supported (Android only).
  static bool get supportsBackgroundTracking => isAndroid;
  
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
      
      // Only initialize WorkManager on Android - iOS uses foreground-only tracking
      if (isAndroid) {
        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: kDebugMode,
        );
        
        // If was enabled before, restart background task
        if (_isBackgroundEnabled) {
          await _startBackgroundTracking();
        }
      } else if (isIOS) {
        debugPrint('BackgroundLocationService: iOS detected - using foreground-only tracking');
        // On iOS, we don't register background tasks
        // Tracking happens when the app is in foreground via onAppLifecycleChanged
      }
      
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to initialize: $e';
      debugPrint('BackgroundLocationService: $_lastError');
      notifyListeners();
    }
  }
  
  /// Called when app lifecycle changes (iOS foreground tracking).
  /// Should be called from the app's lifecycle observer when app resumes.
  Future<void> onAppResumed() async {
    if (!_isBackgroundEnabled) return;
    
    debugPrint('BackgroundLocationService: App resumed - checking location');
    // Use force check without debounce bypass for normal lifecycle checks
    await forceLocationCheck(bypassDebounce: false);
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
    // Only register WorkManager task on Android
    if (!isAndroid) {
      debugPrint('BackgroundLocationService: Skipping WorkManager on non-Android platform');
      return;
    }
    
    try {
      // Register periodic task for Android
      // WARNING: Android minimum is 15 minutes
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
      // Only cancel WorkManager task on Android
      if (isAndroid) {
        await Workmanager().cancelByUniqueName(backgroundTaskName);
      }
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
    
    // Get debounce/pending state
    final pendingCountry = _box?.get('pendingCountryCode') as String?;
    final pendingCount = _box?.get('pendingCountryCheckCount') as int? ?? 0;
    final pendingFirstSeenStr = _box?.get('pendingCountryFirstSeen') as String?;
    
    // Get geocode info
    final lastGeocodeTimeStr = _box?.get('lastGeocodeTime') as String?;
    final lastLatitude = _box?.get('lastLatitude') as double?;
    final lastLongitude = _box?.get('lastLongitude') as double?;
    final lastCountrySource = _box?.get('lastCountrySource') as String?;
    
    // Get lock status
    final isLocked = _box?.get('isRunning') as bool? ?? false;
    final lockAcquiredAtStr = _box?.get('lockAcquiredAt') as String?;
    
    return {
      'isEnabled': _isBackgroundEnabled,
      'isTracking': _isBackgroundEnabled,
      'permissionStatus': _permissionStatus,
      'lastUpdate': _lastBackgroundUpdate?.toIso8601String(),
      'lastError': _lastError,
      'currentCountry': lastCountry,
      'isMoving': null, // Not available with WorkManager approach
      // Debounce state
      'pendingCountry': pendingCountry,
      'pendingCount': pendingCount,
      'pendingFirstSeen': pendingFirstSeenStr,
      // Geocode info
      'lastGeocodeTime': lastGeocodeTimeStr,
      'lastLatitude': lastLatitude,
      'lastLongitude': lastLongitude,
      'lastCountrySource': lastCountrySource,
      // Lock status
      'isLocked': isLocked,
      'lockAcquiredAt': lockAcquiredAtStr,
      // Platform info
      'platform': isIOS ? 'iOS' : (isAndroid ? 'Android' : 'Other'),
      'trackingMode': isIOS ? 'foreground_only' : 'background',
      'supportsBackgroundTracking': supportsBackgroundTracking,
    };
  }
  
  /// Force a location check now (useful for testing).
  /// Set [bypassDebounce] to true to immediately commit country changes.
  Future<void> forceLocationCheck({bool bypassDebounce = false}) async {
    bool lockAcquired = false;
    
    try {
      _lastError = null;
      
      // Try to acquire lock
      if (_box != null) {
        lockAcquired = await _tryAcquireLock(_box!);
        if (!lockAcquired) {
          _lastError = 'Another location check is in progress';
          notifyListeners();
          return;
        }
      }
      
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
      
      final now = DateTime.now().toUtc();
      _lastBackgroundUpdate = now;
      await _box?.put('lastUpdate', now.toIso8601String());
      await _box?.put('lastGeocodeTime', now.toIso8601String());
      
      // Store last coordinates for debugging
      if (locationInfo.latitude != null && locationInfo.longitude != null) {
        await _box?.put('lastLatitude', locationInfo.latitude);
        await _box?.put('lastLongitude', locationInfo.longitude);
      }
      
      // Check for country change
      final currentVisit = _visitsRepository.getCurrentVisit();
      final currentCountryCode = currentVisit?.countryCode;
      
      bool shouldCommit = false;
      
      if (bypassDebounce) {
        // Bypass debounce - commit immediately if different
        shouldCommit = currentCountryCode != locationInfo.countryCode;
        // Clear any pending state
        await _box?.delete('pendingCountryCode');
        await _box?.delete('pendingCountryCheckCount');
        await _box?.delete('pendingCountryFirstSeen');
      } else if (_box != null) {
        // Use debounce logic
        final debounceResult = _checkCountryChangeDebounce(
          bgBox: _box!,
          currentCountryCode: currentCountryCode,
          detectedCountryCode: locationInfo.countryCode,
        );
        
        // Update pending state
        if (debounceResult.pendingCountry != null) {
          await _box?.put('pendingCountryCode', debounceResult.pendingCountry);
          await _box?.put('pendingCountryCheckCount', debounceResult.pendingCount);
          if (debounceResult.pendingFirstSeen != null) {
            await _box?.put('pendingCountryFirstSeen', debounceResult.pendingFirstSeen!.toIso8601String());
          }
        } else {
          await _box?.delete('pendingCountryCode');
          await _box?.delete('pendingCountryCheckCount');
          await _box?.delete('pendingCountryFirstSeen');
        }
        
        shouldCommit = debounceResult.shouldCommit;
      }
      
      if (shouldCommit) {
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
        await _box?.put('lastCountrySource', 'fresh');
      } else if (currentCountryCode == locationInfo.countryCode) {
        await _box?.put('lastCountrySource', 'cached');
      }
      
      notifyListeners();
    } catch (e) {
      _lastError = 'Force check failed: $e';
      debugPrint('BackgroundLocationService: $_lastError');
      notifyListeners();
    } finally {
      // Always release the lock
      if (lockAcquired && _box != null) {
        await _releaseLock(_box!);
      }
    }
  }
  
  @override
  void dispose() {
    // Don't stop background tracking on dispose - it should continue
    super.dispose();
  }
}
