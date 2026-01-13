import 'package:hive/hive.dart';

part 'sync_state.g.dart';

/// Sync state for tracking visit synchronization with Supabase.
/// 
/// Used by SyncService to determine which visits need to be uploaded,
/// updated, or deleted on the server.
@HiveType(typeId: 3)
enum SyncState {
  /// Never synced, needs initial upload
  @HiveField(0)
  pending,
  
  /// Fully synced with server
  @HiveField(1)
  synced,
  
  /// Local changes not yet uploaded
  @HiveField(2)
  modified,
  
  /// Marked for deletion on server
  @HiveField(3)
  deleted,
}
