import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/app_settings.dart';
import '../data/repositories/settings_repository.dart';
import 'auth_service.dart';

/// Box name for profile sync settings persistence
const String _profileSyncBoxName = 'profile_sync_settings';

/// Service for syncing user profile/settings between local Hive storage and Supabase.
/// 
/// Implements bidirectional sync with conflict resolution (latest wins).
/// 
/// Synced settings:
/// - accuracy
/// - tracking_interval_minutes
/// - notifications_enabled
/// - country_change_notifications
/// - weekly_digest_notifications
/// - travel_reminders_enabled
/// - travel_reminder_hour
/// - travel_reminder_minute
class ProfileSyncService {
  final SettingsRepository _settingsRepo;
  final AuthService _authService;
  
  Box? _syncBox;
  
  /// Last profile sync timestamp (persisted)
  DateTime? _lastProfileSync;
  DateTime? get lastProfileSync => _lastProfileSync;
  
  /// Local settings modification time
  DateTime? _localSettingsModifiedAt;
  
  ProfileSyncService(this._settingsRepo, this._authService);
  
  /// The Supabase client
  SupabaseClient get _client => Supabase.instance.client;
  
  /// Whether profile sync is available (user authenticated)
  bool get canSync => _authService.isAuthenticated;
  
  /// Initialize the profile sync service.
  Future<void> initialize() async {
    try {
      _syncBox = await Hive.openBox(_profileSyncBoxName);
      
      final lastSyncStr = _syncBox?.get('lastProfileSync') as String?;
      if (lastSyncStr != null) {
        _lastProfileSync = DateTime.tryParse(lastSyncStr);
      }
      
      final modifiedStr = _syncBox?.get('localSettingsModifiedAt') as String?;
      if (modifiedStr != null) {
        _localSettingsModifiedAt = DateTime.tryParse(modifiedStr);
      }
      
      debugPrint('ProfileSyncService: Initialized (lastSync: $_lastProfileSync)');
    } catch (e) {
      debugPrint('ProfileSyncService: Failed to initialize: $e');
    }
  }
  
  /// Mark local settings as modified (triggers upload on next sync).
  Future<void> markLocalSettingsModified() async {
    _localSettingsModifiedAt = DateTime.now().toUtc();
    await _syncBox?.put('localSettingsModifiedAt', _localSettingsModifiedAt!.toIso8601String());
    debugPrint('ProfileSyncService: Local settings marked as modified');
  }
  
  /// Clear the local modified flag after successful upload.
  Future<void> _clearLocalModifiedFlag() async {
    _localSettingsModifiedAt = null;
    await _syncBox?.delete('localSettingsModifiedAt');
  }
  
  /// Perform a full profile sync (download then merge, upload if needed).
  Future<void> syncProfile() async {
    if (!canSync) {
      debugPrint('ProfileSyncService: Cannot sync - user not authenticated');
      return;
    }
    
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;
      
      // Step 1: Download remote profile
      final remoteProfile = await _downloadProfile(userId);
      
      // Step 2: If no profile exists, create one with current settings
      if (remoteProfile == null) {
        debugPrint('ProfileSyncService: No remote profile - creating initial profile');
        await _uploadProfile(userId);
        _lastProfileSync = DateTime.now().toUtc();
        await _syncBox?.put('lastProfileSync', _lastProfileSync!.toIso8601String());
        debugPrint('ProfileSyncService: Initial profile created');
        return;
      }
      
      // Step 3: Merge with local settings
      await _mergeWithLocal(remoteProfile);
      
      // Step 4: Upload local settings if modified after last sync
      if (_shouldUploadLocal(remoteProfile)) {
        await _uploadProfile(userId);
      }
      
      _lastProfileSync = DateTime.now().toUtc();
      await _syncBox?.put('lastProfileSync', _lastProfileSync!.toIso8601String());
      
      debugPrint('ProfileSyncService: Profile sync completed');
    } catch (e) {
      debugPrint('ProfileSyncService: Profile sync failed: $e');
      // Don't rethrow - profile sync failure shouldn't block app
    }
  }
  
  /// Check if we should upload local settings.
  bool _shouldUploadLocal(Map<String, dynamic>? remoteProfile) {
    if (_localSettingsModifiedAt == null) return false;
    
    if (remoteProfile == null) {
      // No remote profile exists - should upload
      return true;
    }
    
    final remoteUpdatedAt = DateTime.tryParse(remoteProfile['updated_at'] as String? ?? '');
    if (remoteUpdatedAt == null) return true;
    
    // Upload if local was modified after remote
    return _localSettingsModifiedAt!.isAfter(remoteUpdatedAt);
  }
  
  /// Download the user's profile from Supabase.
  Future<Map<String, dynamic>?> _downloadProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      debugPrint('ProfileSyncService: Downloaded profile: ${response != null ? "found" : "not found"}');
      return response;
    } catch (e) {
      debugPrint('ProfileSyncService: Failed to download profile: $e');
      return null;
    }
  }
  
  /// Merge remote profile with local settings (remote wins on conflict).
  Future<void> _mergeWithLocal(Map<String, dynamic>? remoteProfile) async {
    if (remoteProfile == null) {
      debugPrint('ProfileSyncService: No remote profile to merge');
      return;
    }
    
    final remoteUpdatedAt = DateTime.tryParse(remoteProfile['updated_at'] as String? ?? '');
    
    // If local was modified after remote, don't overwrite
    if (_localSettingsModifiedAt != null && 
        remoteUpdatedAt != null && 
        _localSettingsModifiedAt!.isAfter(remoteUpdatedAt)) {
      debugPrint('ProfileSyncService: Local settings are newer, skipping merge');
      return;
    }
    
    // Apply remote settings to local
    final currentSettings = _settingsRepo.getSettings();
    
    final accuracy = _parseAccuracy(remoteProfile['accuracy'] as String?);
    final trackingInterval = remoteProfile['tracking_interval_minutes'] as int?;
    final notificationsEnabled = remoteProfile['notifications_enabled'] as bool?;
    final countryChangeNotifications = remoteProfile['country_change_notifications'] as bool?;
    final weeklyDigestNotifications = remoteProfile['weekly_digest_notifications'] as bool?;
    final travelRemindersEnabled = remoteProfile['travel_reminders_enabled'] as bool?;
    final travelReminderHour = remoteProfile['travel_reminder_hour'] as int?;
    final travelReminderMinute = remoteProfile['travel_reminder_minute'] as int?;
    
    final mergedSettings = currentSettings.copyWith(
      accuracy: accuracy ?? currentSettings.accuracy,
      trackingIntervalMinutes: trackingInterval ?? currentSettings.trackingIntervalMinutes,
      notificationsEnabled: notificationsEnabled ?? currentSettings.notificationsEnabled,
      countryChangeNotifications: countryChangeNotifications ?? currentSettings.countryChangeNotifications,
      weeklyDigestNotifications: weeklyDigestNotifications ?? currentSettings.weeklyDigestNotifications,
      travelRemindersEnabled: travelRemindersEnabled ?? currentSettings.travelRemindersEnabled,
      travelReminderHour: travelReminderHour ?? currentSettings.travelReminderHour,
      travelReminderMinute: travelReminderMinute ?? currentSettings.travelReminderMinute,
    );
    
    await _settingsRepo.saveSettings(mergedSettings);
    debugPrint('ProfileSyncService: Merged remote settings into local');
  }
  
  /// Upload local settings to Supabase.
  Future<void> _uploadProfile(String userId) async {
    try {
      final settings = _settingsRepo.getSettings();
      
      await _client.from('profiles').upsert({
        'id': userId,
        'accuracy': _accuracyToString(settings.accuracy),
        'tracking_interval_minutes': settings.trackingIntervalMinutes,
        'notifications_enabled': settings.notificationsEnabled,
        'country_change_notifications': settings.countryChangeNotifications,
        'weekly_digest_notifications': settings.weeklyDigestNotifications,
        'travel_reminders_enabled': settings.travelRemindersEnabled,
        'travel_reminder_hour': settings.travelReminderHour,
        'travel_reminder_minute': settings.travelReminderMinute,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'id');
      
      await _clearLocalModifiedFlag();
      debugPrint('ProfileSyncService: Uploaded local settings to profile');
    } catch (e) {
      debugPrint('ProfileSyncService: Failed to upload profile: $e');
      rethrow;
    }
  }
  
  /// Upload current settings immediately (e.g., after user makes a change).
  Future<void> uploadSettingsNow() async {
    if (!canSync) return;
    
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    
    try {
      await _uploadProfile(userId);
    } catch (e) {
      // Mark as modified for later sync
      await markLocalSettingsModified();
    }
  }
  
  /// Download and apply remote settings (e.g., on login).
  Future<void> downloadSettingsNow() async {
    if (!canSync) return;
    
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    
    try {
      final remoteProfile = await _downloadProfile(userId);
      if (remoteProfile != null) {
        // Force apply remote settings (ignore local modified flag)
        final tempModified = _localSettingsModifiedAt;
        _localSettingsModifiedAt = null;
        await _mergeWithLocal(remoteProfile);
        _localSettingsModifiedAt = tempModified;
      }
    } catch (e) {
      debugPrint('ProfileSyncService: Failed to download settings: $e');
    }
  }
  
  /// Parse accuracy string to enum.
  LocationAccuracy? _parseAccuracy(String? value) {
    switch (value) {
      case 'low':
        return LocationAccuracy.low;
      case 'medium':
        return LocationAccuracy.medium;
      case 'high':
        return LocationAccuracy.high;
      default:
        return null;
    }
  }
  
  /// Convert accuracy enum to string.
  String _accuracyToString(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.low:
        return 'low';
      case LocationAccuracy.medium:
        return 'medium';
      case LocationAccuracy.high:
        return 'high';
    }
  }
}
