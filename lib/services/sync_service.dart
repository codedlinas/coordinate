import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/country_visit.dart';
import '../data/models/visit_sync_dto.dart';
import '../data/repositories/visits_repository.dart';
import 'auth_service.dart';
import 'sync_queue.dart';

/// Sync status for UI feedback
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  pending, // Has pending changes to sync
}

/// Box name for sync settings persistence
const String _syncSettingsBoxName = 'sync_settings';

/// Service for syncing visits between local Hive storage and Supabase.
/// 
/// Implements an offline-first, upload-before-download strategy:
/// 1. Push local changes to server
/// 2. Pull remote changes since last sync
/// 3. Resolve conflicts using VisitSyncDto logic
/// 
/// Now supports auto-sync triggers:
/// - On country change (via TrackingService/BackgroundLocationService)
/// - On app resume
/// - On network restored (via SyncQueue)
class SyncService {
  final VisitsRepository _visitsRepo;
  final AuthService _authService;
  
  SyncQueue? _syncQueue;
  Box? _settingsBox;
  
  /// Whether cloud sync is enabled by user
  bool _cloudSyncEnabled = true;
  bool get cloudSyncEnabled => _cloudSyncEnabled;
  
  /// Last sync timestamp (persisted)
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;
  
  /// Current sync status
  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;
  
  /// Stream controller for sync status updates
  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;
  
  SyncService(this._visitsRepo, this._authService);
  
  /// Initialize the sync service and queue.
  /// Call this once at app startup.
  Future<void> initialize() async {
    try {
      // Open settings box for persistence
      _settingsBox = await Hive.openBox(_syncSettingsBoxName);
      _cloudSyncEnabled = _settingsBox?.get('cloudSyncEnabled', defaultValue: true) ?? true;
      
      final lastSyncStr = _settingsBox?.get('lastSyncTime') as String?;
      if (lastSyncStr != null) {
        _lastSyncTime = DateTime.tryParse(lastSyncStr);
      }
      
      // Initialize sync queue
      _syncQueue = SyncQueue(_visitsRepo);
      await _syncQueue!.initialize();
      
      // Set up queue callbacks
      _syncQueue!.onProcessPendingVisits = _processPendingVisits;
      _syncQueue!.onProcessDeletedVisits = _processDeletedVisits;
      
      // Update status based on pending operations
      _updatePendingStatus();
      
      debugPrint('SyncService: Initialized (cloudSyncEnabled: $_cloudSyncEnabled, lastSync: $_lastSyncTime)');
    } catch (e) {
      debugPrint('SyncService: Failed to initialize: $e');
    }
  }
  
  /// Set cloud sync enabled/disabled.
  Future<void> setCloudSyncEnabled(bool enabled) async {
    _cloudSyncEnabled = enabled;
    await _settingsBox?.put('cloudSyncEnabled', enabled);
    debugPrint('SyncService: Cloud sync ${enabled ? "enabled" : "disabled"}');
    
    // If enabling, process any pending changes
    if (enabled && canSync) {
      await syncPendingVisits();
    }
  }
  
  /// The Supabase client
  SupabaseClient get _client => Supabase.instance.client;
  
  /// Access to the sync queue for status checking
  SyncQueue? get syncQueue => _syncQueue;
  
  /// Whether sync is available (user authenticated AND cloud sync enabled)
  bool get canSync => _authService.isAuthenticated && _cloudSyncEnabled;
  
  /// Whether sync is available but just offline
  bool get isOnline => _syncQueue?.isOnline ?? true;
  
  /// Trigger a full sync (upload then download)
  Future<void> sync() async {
    if (!canSync) {
      debugPrint('SyncService: Cannot sync - user not authenticated or sync disabled');
      return;
    }
    
    if (!isOnline) {
      debugPrint('SyncService: Cannot sync - offline');
      _setStatus(SyncStatus.pending);
      return;
    }
    
    if (_status == SyncStatus.syncing) {
      debugPrint('SyncService: Sync already in progress');
      return;
    }
    
    _setStatus(SyncStatus.syncing);
    
    try {
      final deviceId = await _authService.getDeviceId();
      
      // Step 1: Upload local changes
      await _uploadLocalChanges(deviceId);
      
      // Step 2: Download remote changes
      await _downloadRemoteChanges();
      
      _lastSyncTime = DateTime.now().toUtc();
      await _settingsBox?.put('lastSyncTime', _lastSyncTime!.toIso8601String());
      _setStatus(SyncStatus.success);
      
      debugPrint('SyncService: Sync completed successfully at $_lastSyncTime');
    } catch (e) {
      debugPrint('SyncService: Sync failed: $e');
      _setStatus(SyncStatus.error);
      rethrow;
    }
  }
  
  // ============================================================
  // AUTO-SYNC METHODS
  // ============================================================
  
  /// Auto-sync a single visit immediately.
  /// 
  /// Called after:
  /// - Country change detected (new visit created)
  /// - Current visit ended
  /// - Manual edit by user
  /// 
  /// If offline, the visit is marked as pending and will be synced
  /// when network is restored.
  Future<void> autoSyncVisit(CountryVisit visit) async {
    if (!canSync) {
      debugPrint('SyncService: Auto-sync skipped - sync not available');
      return;
    }
    
    if (!isOnline) {
      // Mark as pending for later sync
      debugPrint('SyncService: Offline - marking visit ${visit.id} as pending');
      _updatePendingStatus();
      return;
    }
    
    try {
      await uploadVisit(visit);
      
      // Mark as synced
      final syncedVisit = visit.asSynced();
      await _visitsRepo.updateVisit(syncedVisit);
      
      _lastSyncTime = DateTime.now().toUtc();
      await _settingsBox?.put('lastSyncTime', _lastSyncTime!.toIso8601String());
      
      debugPrint('SyncService: Auto-synced visit ${visit.id}');
    } catch (e) {
      debugPrint('SyncService: Auto-sync failed for visit ${visit.id}: $e');
      // Don't rethrow - auto-sync failures are silent
    }
  }
  
  /// Sync when app resumes from background.
  /// 
  /// Processes any pending/modified visits and downloads remote changes.
  Future<void> syncOnResume() async {
    if (!canSync) {
      debugPrint('SyncService: syncOnResume skipped - sync not available');
      return;
    }
    
    if (!isOnline) {
      debugPrint('SyncService: syncOnResume skipped - offline');
      _updatePendingStatus();
      return;
    }
    
    debugPrint('SyncService: Syncing on app resume');
    await syncPendingVisits();
  }
  
  /// Sync all pending/modified visits.
  /// 
  /// Called:
  /// - On app resume
  /// - When network is restored
  /// - Manually via Settings
  Future<void> syncPendingVisits() async {
    if (!canSync) {
      debugPrint('SyncService: syncPendingVisits skipped - sync not available');
      return;
    }
    
    if (!isOnline) {
      debugPrint('SyncService: syncPendingVisits skipped - offline');
      _updatePendingStatus();
      return;
    }
    
    final pendingVisits = _visitsRepo.getAllVisits()
        .where((v) => v.needsSync)
        .toList();
    
    if (pendingVisits.isEmpty) {
      debugPrint('SyncService: No pending visits to sync');
      return;
    }
    
    debugPrint('SyncService: Syncing ${pendingVisits.length} pending visits');
    await _processPendingVisits(pendingVisits);
    
    _updatePendingStatus();
  }
  
  /// Process pending visits from queue.
  Future<void> _processPendingVisits(List<CountryVisit> visits) async {
    if (!canSync || !isOnline) return;
    
    final deviceId = await _authService.getDeviceId();
    
    for (final visit in visits) {
      try {
        await _uploadSingleVisit(visit, deviceId);
        
        // Mark as synced
        final syncedVisit = visit.asSynced();
        await _visitsRepo.updateVisit(syncedVisit);
        
        debugPrint('SyncService: Synced pending visit ${visit.id}');
      } catch (e) {
        debugPrint('SyncService: Failed to sync visit ${visit.id}: $e');
        // Continue with other visits
      }
    }
    
    _lastSyncTime = DateTime.now().toUtc();
    await _settingsBox?.put('lastSyncTime', _lastSyncTime!.toIso8601String());
  }
  
  /// Process deleted visits from queue.
  Future<void> _processDeletedVisits(List<String> visitIds) async {
    if (!canSync || !isOnline) return;
    
    for (final visitId in visitIds) {
      try {
        await deleteVisit(visitId);
        await _syncQueue?.removeFromDeletionQueue(visitId);
        debugPrint('SyncService: Deleted visit $visitId from server');
      } catch (e) {
        debugPrint('SyncService: Failed to delete visit $visitId: $e');
        // Keep in queue for retry
      }
    }
  }
  
  /// Update status based on pending operations.
  void _updatePendingStatus() {
    if (_status == SyncStatus.syncing) return;
    
    final hasPending = _visitsRepo.getAllVisits().any((v) => v.needsSync);
    final hasDeleteQueue = _syncQueue?.hasPendingOperations ?? false;
    
    if (hasPending || hasDeleteQueue) {
      _setStatus(SyncStatus.pending);
    } else if (_status == SyncStatus.pending) {
      _setStatus(SyncStatus.idle);
    }
  }
  
  /// Upload a single visit to server.
  Future<void> _uploadSingleVisit(CountryVisit visit, String deviceId) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    
    final dto = VisitSyncDto.fromVisit(visit);
    
    await _client.from('visits').upsert({
      'user_id': userId,
      'local_id': dto.id,
      'country_code': dto.countryCode,
      'country_name': dto.countryName,
      'entry_time_utc': dto.entryTimeUtc.toIso8601String(),
      'exit_time_utc': dto.exitTimeUtc?.toIso8601String(),
      'city': dto.city,
      'region': dto.region,
      'updated_at': dto.updatedAt.toIso8601String(),
      'device_id': deviceId,
      'is_manual_edit': dto.isManualEdit,
    }, onConflict: 'user_id,local_id');
  }
  
  /// Delete all user data from server.
  /// Used when user wants to remove their cloud data.
  Future<void> deleteAllCloudData() async {
    if (!_authService.isAuthenticated) return;
    
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;
      
      await _client.from('visits').delete().eq('user_id', userId);
      
      debugPrint('SyncService: Deleted all cloud data for user');
    } catch (e) {
      debugPrint('SyncService: Failed to delete cloud data: $e');
      rethrow;
    }
  }
  
  /// Upload all local visits to the server
  Future<void> _uploadLocalChanges(String deviceId) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    
    final localVisits = _visitsRepo.getAllVisits();
    debugPrint('SyncService: Uploading ${localVisits.length} local visits');
    
    for (final visit in localVisits) {
      try {
        await _uploadSingleVisit(visit, deviceId);
        
        // Mark as synced with SyncState
        final updatedVisit = visit.asSynced(syncId: visit.syncId ?? visit.id);
        await _visitsRepo.updateVisit(updatedVisit);
        
      } catch (e) {
        debugPrint('SyncService: Failed to upload visit ${visit.id}: $e');
        // Continue with other visits - we'll retry failed ones next sync
      }
    }
  }
  
  /// Download remote changes since last sync
  Future<void> _downloadRemoteChanges() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;
    
    try {
      // Fetch all remote visits (or only since last sync if available)
      var query = _client
          .from('visits')
          .select()
          .eq('user_id', userId);
      
      if (_lastSyncTime != null) {
        query = query.gt('updated_at', _lastSyncTime!.toIso8601String());
      }
      
      final response = await query.order('updated_at', ascending: false);
      
      debugPrint('SyncService: Downloaded ${response.length} remote visits');
      
      for (final row in response) {
        await _mergeRemoteVisit(row);
      }
    } catch (e) {
      debugPrint('SyncService: Failed to download remote changes: $e');
      rethrow;
    }
  }
  
  /// Merge a remote visit into local storage with conflict resolution
  Future<void> _mergeRemoteVisit(Map<String, dynamic> row) async {
    final remoteDto = VisitSyncDto(
      id: row['local_id'] as String,
      syncId: row['id'] as String?,
      countryCode: row['country_code'] as String,
      countryName: row['country_name'] as String,
      entryTimeUtc: DateTime.parse(row['entry_time_utc'] as String),
      exitTimeUtc: row['exit_time_utc'] != null 
          ? DateTime.parse(row['exit_time_utc'] as String)
          : null,
      city: row['city'] as String?,
      region: row['region'] as String?,
      updatedAt: DateTime.parse(row['updated_at'] as String),
      deviceId: row['device_id'] as String?,
      isManualEdit: row['is_manual_edit'] as bool? ?? false,
    );
    
    // Check if this visit exists locally
    final localVisit = _visitsRepo.getVisitById(remoteDto.id);
    
    if (localVisit == null) {
      // New visit from another device - add it locally
      // Note: We don't have GPS coordinates from remote, so we use 0,0
      // This is fine since we only store country-level data in the cloud
      final newVisit = remoteDto.toVisit(
        entryLatitude: 0.0,
        entryLongitude: 0.0,
      ).asSynced(syncId: remoteDto.syncId);
      await _visitsRepo.addVisit(newVisit);
      debugPrint('SyncService: Added new remote visit ${remoteDto.id}');
    } else {
      // Visit exists - check for conflicts
      final localDto = VisitSyncDto.fromVisit(localVisit);
      
      if (remoteDto.shouldWinConflictOver(localDto)) {
        // Remote wins - update local
        final updatedVisit = remoteDto.toVisit(
          entryLatitude: localVisit.entryLatitude,
          entryLongitude: localVisit.entryLongitude,
        ).asSynced(syncId: remoteDto.syncId);
        await _visitsRepo.updateVisit(updatedVisit);
        debugPrint('SyncService: Updated local visit ${remoteDto.id} with remote data');
      } else {
        debugPrint('SyncService: Local visit ${remoteDto.id} wins conflict');
      }
    }
  }
  
  /// Upload a single visit immediately (after local change)
  Future<void> uploadVisit(CountryVisit visit) async {
    if (!canSync) return;
    
    try {
      final deviceId = await _authService.getDeviceId();
      await _uploadSingleVisit(visit, deviceId);
      debugPrint('SyncService: Uploaded visit ${visit.id}');
    } catch (e) {
      debugPrint('SyncService: Failed to upload visit ${visit.id}: $e');
      // Silently fail - will be synced on next full sync
    }
  }
  
  /// Delete a visit from the server.
  /// 
  /// If offline, queues for deletion when network is restored.
  Future<void> deleteVisitFromServer(String visitId) async {
    if (!canSync) return;
    
    if (!isOnline) {
      // Queue for deletion when online
      await _syncQueue?.markForDeletion(visitId);
      debugPrint('SyncService: Queued visit $visitId for deletion');
      return;
    }
    
    await deleteVisit(visitId);
  }
  
  /// Delete a visit from the server (internal - always attempts).
  Future<void> deleteVisit(String visitId) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;
      
      await _client
          .from('visits')
          .delete()
          .eq('user_id', userId)
          .eq('local_id', visitId);
      
      debugPrint('SyncService: Deleted visit $visitId from server');
    } catch (e) {
      debugPrint('SyncService: Failed to delete visit $visitId: $e');
      // Silently fail - orphaned server records will be cleaned up eventually
    }
  }
  
  void _setStatus(SyncStatus status) {
    _status = status;
    _statusController.add(status);
  }
  
  void dispose() {
    _syncQueue?.dispose();
    _statusController.close();
  }
}


