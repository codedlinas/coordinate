import 'package:hive/hive.dart';
import 'sync_state.dart';

export 'sync_state.dart';

part 'country_visit.g.dart';

@HiveType(typeId: 0)
class CountryVisit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String countryCode;

  @HiveField(2)
  final String countryName;

  @HiveField(3)
  final DateTime entryTime;

  @HiveField(4)
  DateTime? exitTime;

  @HiveField(5)
  final double entryLatitude;

  @HiveField(6)
  final double entryLongitude;

  @HiveField(7)
  final String? city;

  @HiveField(8)
  final String? region;

  // Sync metadata fields - added for Supabase sync support
  // Note: HiveField IDs are additive and must never change for compatibility
  
  /// UUID for the visit on the sync server (null until first sync)
  @HiveField(9)
  final String? syncId;

  /// Last time this visit was modified (for conflict resolution)
  @HiveField(10)
  final DateTime updatedAt;

  /// Device ID that created/last modified this visit
  @HiveField(11)
  final String? deviceId;

  /// True if this visit was manually edited by the user (wins conflicts)
  @HiveField(12, defaultValue: false)
  final bool isManualEdit;

  /// Sync state for tracking upload/download status
  @HiveField(13, defaultValue: SyncState.pending)
  final SyncState syncState;

  CountryVisit({
    required this.id,
    required this.countryCode,
    required this.countryName,
    required this.entryTime,
    this.exitTime,
    required this.entryLatitude,
    required this.entryLongitude,
    this.city,
    this.region,
    // Sync metadata with defaults for backward compatibility
    this.syncId,
    DateTime? updatedAt,
    this.deviceId,
    this.isManualEdit = false,
    this.syncState = SyncState.pending,
  }) : updatedAt = updatedAt ?? DateTime.now().toUtc();

  Duration get duration {
    final end = exitTime ?? DateTime.now();
    return end.difference(entryTime);
  }

  bool get isOngoing => exitTime == null;

  CountryVisit copyWith({
    String? id,
    String? countryCode,
    String? countryName,
    DateTime? entryTime,
    DateTime? exitTime,
    double? entryLatitude,
    double? entryLongitude,
    String? city,
    String? region,
    String? syncId,
    DateTime? updatedAt,
    String? deviceId,
    bool? isManualEdit,
    SyncState? syncState,
    bool updateTimestamp = false, // Explicitly opt-in to timestamp update
  }) {
    return CountryVisit(
      id: id ?? this.id,
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      entryLatitude: entryLatitude ?? this.entryLatitude,
      entryLongitude: entryLongitude ?? this.entryLongitude,
      city: city ?? this.city,
      region: region ?? this.region,
      syncId: syncId ?? this.syncId,
      updatedAt: updatedAt ?? (updateTimestamp ? DateTime.now().toUtc() : this.updatedAt),
      deviceId: deviceId ?? this.deviceId,
      isManualEdit: isManualEdit ?? this.isManualEdit,
      syncState: syncState ?? this.syncState,
    );
  }
  
  /// Create a copy marked as manually edited (for user-initiated changes).
  /// Manual edits always win in sync conflicts.
  CountryVisit asManualEdit() {
    return copyWith(
      isManualEdit: true,
      syncState: SyncState.modified,
      updateTimestamp: true,
    );
  }

  /// Create a copy marked as synced with server.
  CountryVisit asSynced({String? syncId}) {
    return copyWith(
      syncId: syncId ?? this.syncId,
      syncState: SyncState.synced,
    );
  }

  /// Create a copy marked as modified (needs re-sync).
  CountryVisit asModified() {
    return copyWith(
      syncState: SyncState.modified,
      updateTimestamp: true,
    );
  }

  /// Create a copy marked for deletion on server.
  CountryVisit asDeleted() {
    return copyWith(
      syncState: SyncState.deleted,
    );
  }

  /// Whether this visit needs to be synced to server.
  bool get needsSync => syncState == SyncState.pending || syncState == SyncState.modified;

  /// Whether this visit is marked for deletion.
  bool get isMarkedForDeletion => syncState == SyncState.deleted;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'countryCode': countryCode,
      'countryName': countryName,
      'entryTime': entryTime.toIso8601String(),
      'exitTime': exitTime?.toIso8601String(),
      'entryLatitude': entryLatitude,
      'entryLongitude': entryLongitude,
      'city': city,
      'region': region,
      'syncId': syncId,
      'updatedAt': updatedAt.toIso8601String(),
      'deviceId': deviceId,
      'isManualEdit': isManualEdit,
      'syncState': syncState.name,
    };
  }

  factory CountryVisit.fromJson(Map<String, dynamic> json) {
    return CountryVisit(
      id: json['id'] as String,
      countryCode: json['countryCode'] as String,
      countryName: json['countryName'] as String,
      entryTime: DateTime.parse(json['entryTime'] as String),
      exitTime: json['exitTime'] != null
          ? DateTime.parse(json['exitTime'] as String)
          : null,
      entryLatitude: (json['entryLatitude'] as num).toDouble(),
      entryLongitude: (json['entryLongitude'] as num).toDouble(),
      city: json['city'] as String?,
      region: json['region'] as String?,
      // Sync metadata - with defaults for backward compatibility
      syncId: json['syncId'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      deviceId: json['deviceId'] as String?,
      isManualEdit: json['isManualEdit'] as bool? ?? false,
      syncState: json['syncState'] != null
          ? SyncState.values.firstWhere(
              (e) => e.name == json['syncState'],
              orElse: () => SyncState.pending,
            )
          : SyncState.pending,
    );
  }

  String toCsvRow() {
    return '$id,$countryCode,"$countryName",${entryTime.toIso8601String()},${exitTime?.toIso8601String() ?? ""},$entryLatitude,$entryLongitude,"${city ?? ""}","${region ?? ""}"';
  }

  static String csvHeader() {
    return 'id,countryCode,countryName,entryTime,exitTime,entryLatitude,entryLongitude,city,region';
  }
}






