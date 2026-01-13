import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../data/models/models.dart';
import '../data/repositories/visits_repository.dart';

/// Box name for persisting sync queue state
const String _syncQueueBoxName = 'sync_queue';

/// Manages offline sync queue for visit data.
/// 
/// When the device is offline, sync operations are queued and processed
/// when connectivity is restored. The queue is persisted to Hive for
/// crash resilience.
class SyncQueue {
  final VisitsRepository _visitsRepo;
  
  Box? _queueBox;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  /// Callback to process pending visits when online
  Future<void> Function(List<CountryVisit> visits)? onProcessPendingVisits;
  
  /// Callback to process deleted visits when online
  Future<void> Function(List<String> visitIds)? onProcessDeletedVisits;
  
  /// Stream controller for sync queue status
  final _statusController = StreamController<SyncQueueStatus>.broadcast();
  Stream<SyncQueueStatus> get statusStream => _statusController.stream;
  
  SyncQueueStatus _status = SyncQueueStatus.idle;
  SyncQueueStatus get status => _status;
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  
  bool _isProcessing = false;
  
  SyncQueue(this._visitsRepo);
  
  /// Initialize the sync queue and start monitoring connectivity.
  Future<void> initialize() async {
    try {
      _queueBox = await Hive.openBox(_syncQueueBoxName);
      
      // Check initial connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOnline = _isConnected(connectivityResult);
      
      // Listen for connectivity changes
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        _handleConnectivityChange,
      );
      
      debugPrint('SyncQueue: Initialized (online: $_isOnline)');
    } catch (e) {
      debugPrint('SyncQueue: Failed to initialize: $e');
    }
  }
  
  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => 
      r == ConnectivityResult.wifi || 
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.ethernet
    );
  }
  
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = _isConnected(results);
    
    debugPrint('SyncQueue: Connectivity changed - online: $_isOnline');
    
    // If we just came online, process the queue
    if (!wasOnline && _isOnline) {
      debugPrint('SyncQueue: Network restored - processing queue');
      processQueue();
    }
  }
  
  /// Check if there are pending operations in the queue.
  bool get hasPendingOperations {
    final pendingCount = getPendingVisits().length;
    final deletedCount = getDeletedVisitIds().length;
    return pendingCount > 0 || deletedCount > 0;
  }
  
  /// Get count of pending operations.
  int get pendingOperationsCount {
    return getPendingVisits().length + getDeletedVisitIds().length;
  }
  
  /// Get all visits that need to be synced (pending or modified).
  List<CountryVisit> getPendingVisits() {
    return _visitsRepo.getAllVisits()
        .where((v) => v.needsSync)
        .toList();
  }
  
  /// Get IDs of visits marked for deletion on server.
  List<String> getDeletedVisitIds() {
    final deletedIds = _queueBox?.get('deletedVisitIds') as List<dynamic>?;
    return deletedIds?.cast<String>() ?? [];
  }
  
  /// Mark a visit ID for deletion on server.
  Future<void> markForDeletion(String visitId) async {
    final deletedIds = getDeletedVisitIds();
    if (!deletedIds.contains(visitId)) {
      deletedIds.add(visitId);
      await _queueBox?.put('deletedVisitIds', deletedIds);
      debugPrint('SyncQueue: Marked $visitId for deletion');
    }
  }
  
  /// Remove a visit ID from deletion queue (after successful server deletion).
  Future<void> removeFromDeletionQueue(String visitId) async {
    final deletedIds = getDeletedVisitIds();
    deletedIds.remove(visitId);
    await _queueBox?.put('deletedVisitIds', deletedIds);
  }
  
  /// Clear the deletion queue.
  Future<void> clearDeletionQueue() async {
    await _queueBox?.delete('deletedVisitIds');
  }
  
  /// Process all pending operations in the queue.
  /// 
  /// This is called automatically when network is restored,
  /// or can be called manually (e.g., on app resume).
  Future<void> processQueue() async {
    if (!_isOnline) {
      debugPrint('SyncQueue: Cannot process - offline');
      return;
    }
    
    if (_isProcessing) {
      debugPrint('SyncQueue: Already processing');
      return;
    }
    
    _isProcessing = true;
    _setStatus(SyncQueueStatus.processing);
    
    try {
      // Process pending visits
      final pendingVisits = getPendingVisits();
      if (pendingVisits.isNotEmpty && onProcessPendingVisits != null) {
        debugPrint('SyncQueue: Processing ${pendingVisits.length} pending visits');
        await onProcessPendingVisits!(pendingVisits);
      }
      
      // Process deleted visits
      final deletedIds = getDeletedVisitIds();
      if (deletedIds.isNotEmpty && onProcessDeletedVisits != null) {
        debugPrint('SyncQueue: Processing ${deletedIds.length} deleted visits');
        await onProcessDeletedVisits!(deletedIds);
      }
      
      _setStatus(SyncQueueStatus.idle);
      debugPrint('SyncQueue: Queue processed successfully');
    } catch (e) {
      debugPrint('SyncQueue: Error processing queue: $e');
      _setStatus(SyncQueueStatus.error);
    } finally {
      _isProcessing = false;
    }
  }
  
  void _setStatus(SyncQueueStatus status) {
    _status = status;
    _statusController.add(status);
  }
  
  /// Dispose resources.
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}

/// Status of the sync queue.
enum SyncQueueStatus {
  idle,
  processing,
  error,
}
