import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/country_visit.dart';
import '../data/models/visit_sync_dto.dart';
import '../data/repositories/visits_repository.dart';
import 'auth_service.dart';

/// Sync status for UI feedback
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Service for syncing visits between local Hive storage and Supabase.
/// 
/// Implements an offline-first, upload-before-download strategy:
/// 1. Push local changes to server
/// 2. Pull remote changes since last sync
/// 3. Resolve conflicts using VisitSyncDto logic
class SyncService {
  final VisitsRepository _visitsRepo;
  final AuthService _authService;
  
  /// Last sync timestamp (stored in memory, could be persisted)
  DateTime? _lastSyncTime;
  
  /// Current sync status
  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;
  
  /// Stream controller for sync status updates
  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;
  
  SyncService(this._visitsRepo, this._authService);
  
  /// The Supabase client
  SupabaseClient get _client => Supabase.instance.client;
  
  /// Whether sync is available (user is authenticated)
  bool get canSync => _authService.isAuthenticated;
  
  /// Trigger a full sync (upload then download)
  Future<void> sync() async {
    if (!canSync) {
      debugPrint('SyncService: Cannot sync - user not authenticated');
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
      _setStatus(SyncStatus.success);
      
      debugPrint('SyncService: Sync completed successfully at $_lastSyncTime');
    } catch (e) {
      debugPrint('SyncService: Sync failed: $e');
      _setStatus(SyncStatus.error);
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
        final dto = VisitSyncDto.fromVisit(visit);
        
        // Upsert to Supabase (insert or update based on local_id)
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
        
        // Update local visit with sync metadata
        final updatedVisit = CountryVisit(
          id: visit.id,
          countryCode: visit.countryCode,
          countryName: visit.countryName,
          entryTime: visit.entryTime,
          exitTime: visit.exitTime,
          entryLatitude: visit.entryLatitude,
          entryLongitude: visit.entryLongitude,
          city: visit.city,
          region: visit.region,
          syncId: visit.syncId ?? visit.id, // Mark as synced
          updatedAt: visit.updatedAt,
          deviceId: deviceId,
          isManualEdit: visit.isManualEdit,
        );
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
      );
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
        );
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
      final userId = _authService.currentUser?.id;
      final deviceId = await _authService.getDeviceId();
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
      
      debugPrint('SyncService: Uploaded visit ${visit.id}');
    } catch (e) {
      debugPrint('SyncService: Failed to upload visit ${visit.id}: $e');
      // Silently fail - will be synced on next full sync
    }
  }
  
  /// Delete a visit from the server
  Future<void> deleteVisit(String visitId) async {
    if (!canSync) return;
    
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
    _statusController.close();
  }
}

