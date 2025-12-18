import '../../core/storage/storage_service.dart';
import '../models/models.dart';

class VisitsRepository {
  List<CountryVisit> getAllVisits() {
    return StorageService.visitsBox.values.toList()
      ..sort((a, b) => b.entryTime.compareTo(a.entryTime));
  }

  List<CountryVisit> getVisitsForCountry(String countryCode) {
    return StorageService.visitsBox.values
        .where((v) => v.countryCode == countryCode)
        .toList()
      ..sort((a, b) => b.entryTime.compareTo(a.entryTime));
  }

  CountryVisit? getCurrentVisit() {
    final visits = StorageService.visitsBox.values.where((v) => v.isOngoing);
    return visits.isNotEmpty ? visits.first : null;
  }

  Future<void> addVisit(CountryVisit visit) async {
    await StorageService.visitsBox.put(visit.id, visit);
  }

  Future<void> updateVisit(CountryVisit visit) async {
    await StorageService.visitsBox.put(visit.id, visit);
  }

  Future<void> deleteVisit(String id) async {
    await StorageService.visitsBox.delete(id);
  }

  Future<void> endCurrentVisit(DateTime exitTime) async {
    final current = getCurrentVisit();
    if (current != null) {
      final updated = current.copyWith(exitTime: exitTime);
      await updateVisit(updated);
    }
  }

  Map<String, List<CountryVisit>> getVisitsByCountry() {
    final visits = getAllVisits();
    final Map<String, List<CountryVisit>> grouped = {};
    for (final visit in visits) {
      grouped.putIfAbsent(visit.countryCode, () => []).add(visit);
    }
    return grouped;
  }

  Set<String> getUniqueCountries() {
    return StorageService.visitsBox.values.map((v) => v.countryCode).toSet();
  }

  int getTotalCountries() {
    return getUniqueCountries().length;
  }

  Duration getTotalDuration() {
    return StorageService.visitsBox.values
        .fold(Duration.zero, (sum, visit) => sum + visit.duration);
  }

  Duration getDurationForCountry(String countryCode) {
    return StorageService.visitsBox.values
        .where((v) => v.countryCode == countryCode)
        .fold(Duration.zero, (sum, visit) => sum + visit.duration);
  }

  int getVisitCountForCountry(String countryCode) {
    return StorageService.visitsBox.values
        .where((v) => v.countryCode == countryCode)
        .length;
  }

  DateTime? getFirstVisitDate() {
    final visits = getAllVisits();
    if (visits.isEmpty) return null;
    return visits.map((v) => v.entryTime).reduce(
        (a, b) => a.isBefore(b) ? a : b);
  }

  DateTime? getLastVisitDate() {
    final visits = getAllVisits();
    if (visits.isEmpty) return null;
    return visits.first.entryTime;
  }

  Future<void> clearAllVisits() async {
    await StorageService.visitsBox.clear();
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







