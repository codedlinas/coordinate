import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
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
      debugPrint('LocationService: Location service is not enabled');
      return false;
    }

    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    debugPrint('LocationService: Current permission status: $permission');
    
    if (permission == geo.LocationPermission.denied) {
      debugPrint('LocationService: Permission denied, requesting...');
      permission = await geo.Geolocator.requestPermission();
      debugPrint('LocationService: Permission after request: $permission');
      if (permission == geo.LocationPermission.denied) {
        return false;
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      debugPrint('LocationService: Permission denied forever');
      return false;
    }

    debugPrint('LocationService: Permission granted');
    return true;
  }

  Future<geo.Position?> getCurrentPosition({
    models.LocationAccuracy accuracy = models.LocationAccuracy.medium,
    bool forceRefresh = false,
  }) async {
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      debugPrint('LocationService: Permission not granted');
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
      debugPrint('LocationService: Error getting position: $e');
      return null;
    }
  }

  Future<LocationInfo?> getLocationInfo(double lat, double lng) async {
    try {
      debugPrint('LocationService: Geocoding coordinates - lat: $lat, lng: $lng');
      final placemarks = await placemarkFromCoordinates(lat, lng);
      debugPrint('LocationService: Got ${placemarks.length} placemarks');
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        debugPrint('LocationService: Place - country: ${place.country}, isoCountryCode: ${place.isoCountryCode}');
        // Use a fallback if country is empty but we have ISO code
        String countryName = place.country ?? '';
        String countryCode = place.isoCountryCode ?? '';
        
        // If country name is empty but we have coordinates, we can use reverse geocoding API
        if (countryName.isEmpty && countryCode.isEmpty) {
          debugPrint('LocationService: Country info missing, trying alternative lookup...');
          // For now, return null - we'll handle this below
        }
        
        return LocationInfo(
          countryCode: countryCode,
          countryName: countryName.isEmpty ? 'Unknown' : countryName,
          city: place.locality ?? place.subAdministrativeArea,
          region: place.administrativeArea,
        );
      }
    } catch (e) {
      debugPrint('LocationService: Geocoding error: $e');
      // Try fallback: use HTTP geocoding service
      return await _getLocationInfoFallback(lat, lng);
    }
    return await _getLocationInfoFallback(lat, lng);
  }
  
  Future<LocationInfo?> _getLocationInfoFallback(double lat, double lng) async {
    try {
      debugPrint('LocationService: Trying fallback geocoding with Nominatim...');
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
          debugPrint('LocationService: Fallback got - country: $country, code: $countryCode');
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
      debugPrint('LocationService: Fallback geocoding failed: $e');
    }
    return null;
  }

  Future<LocationInfo?> getCurrentLocationInfo({
    models.LocationAccuracy accuracy = models.LocationAccuracy.medium,
  }) async {
    debugPrint('LocationService: Getting current location info...');
    final position = await getCurrentPosition(accuracy: accuracy, forceRefresh: true);
    if (position == null) {
      debugPrint('LocationService: Position is null');
      return null;
    }

    debugPrint('LocationService: Got position - lat: ${position.latitude}, lng: ${position.longitude}');
    final info = await getLocationInfo(position.latitude, position.longitude);
    if (info == null) {
      debugPrint('LocationService: LocationInfo is null after geocoding');
      return null;
    }

    final result = info.copyWith(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    debugPrint('LocationService: Returning LocationInfo - ${result.countryName} (${result.countryCode})');
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
