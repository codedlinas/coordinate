import 'package:hive/hive.dart';

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
  });

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
    );
  }

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
    );
  }

  String toCsvRow() {
    return '$id,$countryCode,"$countryName",${entryTime.toIso8601String()},${exitTime?.toIso8601String() ?? ""},$entryLatitude,$entryLongitude,"${city ?? ""}","${region ?? ""}"';
  }

  static String csvHeader() {
    return 'id,countryCode,countryName,entryTime,exitTime,entryLatitude,entryLongitude,city,region';
  }
}


