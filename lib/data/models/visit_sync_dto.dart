import 'country_visit.dart';

/// Data transfer object for syncing visits to Supabase.
/// 
/// Privacy by design: This DTO excludes GPS coordinates (entryLatitude, entryLongitude)
/// to ensure only country-level data is transmitted to the server.
/// 
/// Conflict resolution strategy:
/// - Compare [updatedAt] timestamps for basic conflicts
/// - [isManualEdit] = true always wins over automatic entries
/// - Use [deviceId] for device-specific deduplication
class VisitSyncDto {
  /// Local unique identifier for the visit
  final String id;
  
  /// Server-side UUID (null until first sync)
  final String? syncId;
  
  /// ISO 3166-1 alpha-2 country code (e.g., "US", "DE")
  final String countryCode;
  
  /// Human-readable country name
  final String countryName;
  
  /// Entry time in UTC
  final DateTime entryTimeUtc;
  
  /// Exit time in UTC (null if visit is ongoing)
  final DateTime? exitTimeUtc;
  
  /// City name (optional, for display purposes)
  final String? city;
  
  /// Region/state name (optional, for display purposes)
  final String? region;
  
  /// Last modification timestamp for conflict resolution
  final DateTime updatedAt;
  
  /// Device identifier that created/modified this visit
  final String? deviceId;
  
  /// True if this visit was manually edited (wins conflicts)
  final bool isManualEdit;

  VisitSyncDto({
    required this.id,
    this.syncId,
    required this.countryCode,
    required this.countryName,
    required this.entryTimeUtc,
    this.exitTimeUtc,
    this.city,
    this.region,
    required this.updatedAt,
    this.deviceId,
    this.isManualEdit = false,
  });

  /// Create from a local CountryVisit model.
  /// This is the primary way to create a DTO for syncing.
  factory VisitSyncDto.fromVisit(CountryVisit visit) {
    return VisitSyncDto(
      id: visit.id,
      syncId: visit.syncId,
      countryCode: visit.countryCode,
      countryName: visit.countryName,
      entryTimeUtc: visit.entryTime.toUtc(),
      exitTimeUtc: visit.exitTime?.toUtc(),
      city: visit.city,
      region: visit.region,
      updatedAt: visit.updatedAt.toUtc(),
      deviceId: visit.deviceId,
      isManualEdit: visit.isManualEdit,
    );
  }

  /// Convert to JSON for API requests.
  /// Does NOT include GPS coordinates - privacy by design.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sync_id': syncId,
      'country_code': countryCode,
      'country_name': countryName,
      'entry_time_utc': entryTimeUtc.toIso8601String(),
      'exit_time_utc': exitTimeUtc?.toIso8601String(),
      'city': city,
      'region': region,
      'updated_at': updatedAt.toIso8601String(),
      'device_id': deviceId,
      'is_manual_edit': isManualEdit,
    };
  }

  /// Parse from JSON response (snake_case for Supabase compatibility).
  factory VisitSyncDto.fromJson(Map<String, dynamic> json) {
    return VisitSyncDto(
      id: json['id'] as String,
      syncId: json['sync_id'] as String?,
      countryCode: json['country_code'] as String,
      countryName: json['country_name'] as String,
      entryTimeUtc: DateTime.parse(json['entry_time_utc'] as String),
      exitTimeUtc: json['exit_time_utc'] != null
          ? DateTime.parse(json['exit_time_utc'] as String)
          : null,
      city: json['city'] as String?,
      region: json['region'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deviceId: json['device_id'] as String?,
      isManualEdit: json['is_manual_edit'] as bool? ?? false,
    );
  }

  /// Merge server data back into a local CountryVisit.
  /// Preserves local GPS coordinates while updating sync metadata.
  CountryVisit toVisit({
    required double entryLatitude,
    required double entryLongitude,
  }) {
    return CountryVisit(
      id: id,
      countryCode: countryCode,
      countryName: countryName,
      entryTime: entryTimeUtc,
      exitTime: exitTimeUtc,
      entryLatitude: entryLatitude,
      entryLongitude: entryLongitude,
      city: city,
      region: region,
      syncId: syncId,
      updatedAt: updatedAt,
      deviceId: deviceId,
      isManualEdit: isManualEdit,
    );
  }

  /// Check if this DTO should win over another in a conflict.
  /// Manual edits always win. Otherwise, most recent update wins.
  bool shouldWinConflictOver(VisitSyncDto other) {
    // Manual edits always win
    if (isManualEdit && !other.isManualEdit) return true;
    if (!isManualEdit && other.isManualEdit) return false;
    
    // Otherwise, most recent update wins
    return updatedAt.isAfter(other.updatedAt);
  }

  @override
  String toString() {
    return 'VisitSyncDto(id: $id, country: $countryCode, entry: $entryTimeUtc)';
  }
}





