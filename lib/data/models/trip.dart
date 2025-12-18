import 'country_visit.dart';

/// Represents a continuous stay in a single country.
///
/// Currently this is a 1:1 view over a [CountryVisit] segment. In the future,
/// multiple segments for the same country could be merged into a single trip.
class Trip {
  /// Reuses the underlying [CountryVisit.id].
  final String id;

  final String countryCode;
  final String countryName;

  /// Arrival date/time in UTC.
  final DateTime arrivalDateUtc;

  /// Departure date/time in UTC. Null for ongoing trips.
  final DateTime? departureDateUtc;

  /// Total days spent in the country, based on UTC dates.
  final int totalDays;

  /// The underlying visit this trip is derived from.
  final CountryVisit sourceVisit;

  Trip({
    required this.id,
    required this.countryCode,
    required this.countryName,
    required this.arrivalDateUtc,
    required this.departureDateUtc,
    required this.totalDays,
    required this.sourceVisit,
  });

  /// Create a [Trip] from a [CountryVisit], normalizing times to UTC.
  factory Trip.fromVisit(CountryVisit visit) {
    final arrivalUtc = visit.entryTime.toUtc();
    final departureUtc = visit.exitTime?.toUtc();

    final end = departureUtc ?? DateTime.now().toUtc();
    var days = end.difference(arrivalUtc).inDays;

    // Clamp to a sane range and ensure at least 1 day for display.
    if (days < 1) {
      days = 1;
    } else if (days > 1000000) {
      days = 1000000;
    }

    return Trip(
      id: visit.id,
      countryCode: visit.countryCode,
      countryName: visit.countryName,
      arrivalDateUtc: arrivalUtc,
      departureDateUtc: departureUtc,
      totalDays: days,
      sourceVisit: visit,
    );
  }
}







