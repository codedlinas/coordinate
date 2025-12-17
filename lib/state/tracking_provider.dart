import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_service.dart';
import '../services/tracking_service.dart';
import 'providers.dart';

final locationServiceProvider = Provider((ref) => LocationService());

final trackingServiceProvider = Provider((ref) {
  final service = TrackingService(
    ref.watch(locationServiceProvider),
    ref.watch(visitsRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
  );
  
  // Listen to tracking service changes and refresh visits when visits are created
  service.addListener(() {
    // Refresh visits provider when tracking service notifies of changes
    // This ensures UI updates when visits are created/updated
    Future.microtask(() {
      ref.read(visitsProvider.notifier).refresh();
    });
  });
  
  return service;
});

final isTrackingProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(trackingServiceProvider);
  yield service.isTracking;

  // Listen to changes
  service.addListener(() {
    // Trigger rebuild
  });
});

