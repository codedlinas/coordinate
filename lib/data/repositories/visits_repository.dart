import '../../core/storage/storage_service.dart';
import '../models/models.dart';

class VisitsRepository {
  // Cached computed values - invalidated on data changes
  List<CountryVisit>? _cachedSortedVisits;
  Map<String, List<CountryVisit>>? _cachedVisitsByCountry;
  _AggregatedStats? _cachedStats;

  /// Invalidate all caches - call this after any data modification
  void _invalidateCache() {
    _cachedSortedVisits = null;
    _cachedVisitsByCountry = null;
    _cachedStats = null;
  }

  List<CountryVisit> getAllVisits() {
    if (_cachedSortedVisits != null) {
      return _cachedSortedVisits!;
    }
    _cachedSortedVisits = StorageService.visitsBox.values.toList()
      ..sort((a, b) => b.entryTime.compareTo(a.entryTime));
    return _cachedSortedVisits!;
  }

  List<CountryVisit> getVisitsForCountry(String countryCode) {
    return _getVisitsByCountry()[countryCode] ?? [];
  }

  Map<String, List<CountryVisit>> _getVisitsByCountry() {
    if (_cachedVisitsByCountry != null) {
      return _cachedVisitsByCountry!;
    }
    
    final visits = getAllVisits();
    final Map<String, List<CountryVisit>> grouped = {};
    for (final visit in visits) {
      grouped.putIfAbsent(visit.countryCode, () => []).add(visit);
    }
    _cachedVisitsByCountry = grouped;
    return _cachedVisitsByCountry!;
  }

  CountryVisit? getCurrentVisit() {
    final visits = StorageService.visitsBox.values.where((v) => v.isOngoing);
    return visits.isNotEmpty ? visits.first : null;
  }

  Future<void> addVisit(CountryVisit visit) async {
    await StorageService.visitsBox.put(visit.id, visit);
    _invalidateCache();
  }

  Future<void> updateVisit(CountryVisit visit) async {
    await StorageService.visitsBox.put(visit.id, visit);
    _invalidateCache();
  }

  Future<void> deleteVisit(String id) async {
    await StorageService.visitsBox.delete(id);
    _invalidateCache();
  }

  Future<void> endCurrentVisit(DateTime exitTime) async {
    final current = getCurrentVisit();
    if (current != null) {
      final updated = current.copyWith(exitTime: exitTime);
      await updateVisit(updated);
    }
  }

  Map<String, List<CountryVisit>> getVisitsByCountry() {
    return Map.unmodifiable(_getVisitsByCountry());
  }

  Set<String> getUniqueCountries() {
    return _getAggregatedStats().uniqueCountries;
  }

  int getTotalCountries() {
    return _getAggregatedStats().uniqueCountries.length;
  }

  Duration getTotalDuration() {
    return _getAggregatedStats().totalDuration;
  }

  Duration getDurationForCountry(String countryCode) {
    final visits = getVisitsForCountry(countryCode);
    return visits.fold(Duration.zero, (sum, visit) => sum + visit.duration);
  }

  int getVisitCountForCountry(String countryCode) {
    return getVisitsForCountry(countryCode).length;
  }

  DateTime? getFirstVisitDate() {
    return _getAggregatedStats().firstVisitDate;
  }

  DateTime? getLastVisitDate() {
    return _getAggregatedStats().lastVisitDate;
  }

  /// Compute all aggregated stats in a single pass
  _AggregatedStats _getAggregatedStats() {
    if (_cachedStats != null) {
      return _cachedStats!;
    }

    final visits = getAllVisits();
    if (visits.isEmpty) {
      _cachedStats = _AggregatedStats(
        uniqueCountries: {},
        totalDuration: Duration.zero,
        firstVisitDate: null,
        lastVisitDate: null,
      );
      return _cachedStats!;
    }

    final Set<String> countries = {};
    Duration totalDuration = Duration.zero;
    DateTime? firstDate;
    DateTime? lastDate;

    for (final visit in visits) {
      countries.add(visit.countryCode);
      totalDuration += visit.duration;
      
      if (firstDate == null || visit.entryTime.isBefore(firstDate)) {
        firstDate = visit.entryTime;
      }
      if (lastDate == null || visit.entryTime.isAfter(lastDate)) {
        lastDate = visit.entryTime;
      }
    }

    _cachedStats = _AggregatedStats(
      uniqueCountries: countries,
      totalDuration: totalDuration,
      firstVisitDate: firstDate,
      lastVisitDate: lastDate,
    );
    return _cachedStats!;
  }

  Future<void> clearAllVisits() async {
    await StorageService.visitsBox.clear();
    _invalidateCache();
  }

  // Export all visits as JSON
  List<Map<String, dynamic>> exportToJson() {
    return getAllVisits().map((v) => v.toJson()).toList();
  }

  // Export all visits as CSV string
  String exportToCsv() {
    final buffer = StringBuffer();
    buffer.writeln(CountryVisit.csvHeader());
    for (final visit in getAllVisits()) {
      buffer.writeln(visit.toCsvRow());
    }
    return buffer.toString();
  }

  // Import visits from JSON
  Future<int> importFromJson(List<dynamic> jsonData) async {
    int imported = 0;
    for (final item in jsonData) {
      try {
        final visit = CountryVisit.fromJson(item as Map<String, dynamic>);
        await addVisit(visit);
        imported++;
      } catch (e) {
        // Skip invalid entries
      }
    }
    return imported;
  }
}

/// Internal class to hold aggregated statistics computed in a single pass
class _AggregatedStats {
  final Set<String> uniqueCountries;
  final Duration totalDuration;
  final DateTime? firstVisitDate;
  final DateTime? lastVisitDate;

  _AggregatedStats({
    required this.uniqueCountries,
    required this.totalDuration,
    required this.firstVisitDate,
    required this.lastVisitDate,
  });
}
