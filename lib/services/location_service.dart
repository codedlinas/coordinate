import 'dart:convert';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../core/logging/app_logger.dart';
import '../data/models/models.dart' as models;

class LocationService {
  static geo.LocationAccuracy _mapAccuracy(models.LocationAccuracy accuracy) {
    switch (accuracy) {
      case models.LocationAccuracy.low:
        return geo.LocationAccuracy.low;
      case models.LocationAccuracy.medium:
        return geo.LocationAccuracy.medium;
      case models.LocationAccuracy.high:
        return geo.LocationAccuracy.high;
    }
  }

  Future<bool> checkPermission() async {
    // On web, always check permission status
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.location('Location service is not enabled');
      return false;
    }

    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    AppLogger.location('Current permission status: $permission');
    
    if (permission == geo.LocationPermission.denied) {
      AppLogger.location('Permission denied, requesting...');
      permission = await geo.Geolocator.requestPermission();
      AppLogger.location('Permission after request: $permission');
      if (permission == geo.LocationPermission.denied) {
        return false;
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      AppLogger.location('Permission denied forever');
      return false;
    }

    AppLogger.location('Permission granted');
    return true;
  }

  Future<geo.Position?> getCurrentPosition({
    models.LocationAccuracy accuracy = models.LocationAccuracy.medium,
    bool forceRefresh = false,
  }) async {
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      AppLogger.location('Permission not granted');
      return null;
    }

    try {
      // For web/browser, we need to request position with a timeout
      return await geo.Geolocator.getCurrentPosition(
        locationSettings: geo.LocationSettings(
          accuracy: _mapAccuracy(accuracy),
          distanceFilter: 100,
          timeLimit: const Duration(seconds: 15),
        ),
      );
    } catch (e) {
      AppLogger.error('Location', 'Error getting position', e);
      return null;
    }
  }

  Future<LocationInfo?> getLocationInfo(double lat, double lng) async {
    try {
      AppLogger.location('Geocoding coordinates - lat: $lat, lng: $lng');
      final placemarks = await placemarkFromCoordinates(lat, lng);
      AppLogger.location('Got ${placemarks.length} placemarks');
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        AppLogger.location('Place - country: ${place.country}, isoCountryCode: ${place.isoCountryCode}');
        
        String countryName = place.country ?? '';
        String countryCode = place.isoCountryCode ?? '';
        
        // If we have valid country info, return it
        if (countryCode.isNotEmpty) {
          return LocationInfo(
            countryCode: countryCode,
            countryName: countryName.isEmpty ? 'Unknown' : countryName,
            city: place.locality ?? place.subAdministrativeArea,
            region: place.administrativeArea,
          );
        }
        
        // Country info missing - fall through to fallback
        AppLogger.location('Country info missing, trying fallback...');
      }
    } catch (e) {
      AppLogger.error('Location', 'Geocoding error', e);
      // Fall through to fallback
    }
    
    // Use HTTP fallback if primary geocoding failed or returned no country info
    return await _getLocationInfoFallback(lat, lng);
  }
  
  Future<LocationInfo?> _getLocationInfoFallback(double lat, double lng) async {
    try {
      AppLogger.location('Trying fallback geocoding with Nominatim...');
      // Use OpenStreetMap Nominatim API (free, no API key required)
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'Coordinate App'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final country = address['country'] as String? ?? '';
          final countryCode = (address['country_code'] as String? ?? '').toUpperCase();
          AppLogger.location('Fallback got - country: $country, code: $countryCode');
          return LocationInfo(
            countryCode: countryCode,
            countryName: country,
            city: address['city'] as String? ?? address['town'] as String? ?? address['village'] as String?,
            region: address['state'] as String? ?? address['region'] as String?,
            latitude: lat,
            longitude: lng,
          );
        }
      }
    } catch (e) {
      AppLogger.error('Location', 'Fallback geocoding failed', e);
    }
    return null;
  }

  Future<LocationInfo?> getCurrentLocationInfo({
    models.LocationAccuracy accuracy = models.LocationAccuracy.medium,
  }) async {
    AppLogger.location('Getting current location info...');
    final position = await getCurrentPosition(accuracy: accuracy, forceRefresh: true);
    if (position == null) {
      AppLogger.location('Position is null');
      return null;
    }

    AppLogger.location('Got position - lat: ${position.latitude}, lng: ${position.longitude}');
    final info = await getLocationInfo(position.latitude, position.longitude);
    if (info == null) {
      AppLogger.location('LocationInfo is null after geocoding');
      return null;
    }

    final result = info.copyWith(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    AppLogger.location('Returning LocationInfo - ${result.countryName} (${result.countryCode})');
    return result;
  }
  
  /// Get location info from specific coordinates.
  /// Used for iOS Significant Location Change where we receive coordinates
  /// directly from native code without needing to fetch GPS position.
  Future<LocationInfo?> getLocationInfoFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    AppLogger.location('Getting location info from coordinates - lat: $latitude, lng: $longitude');
    final info = await getLocationInfo(latitude, longitude);
    if (info == null) {
      AppLogger.location('LocationInfo is null after geocoding coordinates');
      return null;
    }

    final result = info.copyWith(
      latitude: latitude,
      longitude: longitude,
    );
    AppLogger.location('Returning LocationInfo from coordinates - ${result.countryName} (${result.countryCode})');
    return result;
  }
}

class LocationInfo {
  final String countryCode;
  final String countryName;
  final String? city;
  final String? region;
  final double? latitude;
  final double? longitude;

  LocationInfo({
    required this.countryCode,
    required this.countryName,
    this.city,
    this.region,
    this.latitude,
    this.longitude,
  });

  LocationInfo copyWith({
    String? countryCode,
    String? countryName,
    String? city,
    String? region,
    double? latitude,
    double? longitude,
  }) {
    return LocationInfo(
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      city: city ?? this.city,
      region: region ?? this.region,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
