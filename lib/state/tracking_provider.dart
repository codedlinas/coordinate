import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tracking_service.dart';
import 'providers.dart';

final trackingServiceProvider = Provider<TrackingService>((ref) {
  final service = TrackingService(
    ref.watch(locationServiceProvider),
    ref.watch(visitsRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
  );
  
  // Use ref.onDispose to properly clean up the listener
  void onServiceChanged() {
    // Refresh visits provider when tracking service notifies of changes
    Future.microtask(() {
      ref.read(visitsProvider.notifier).refresh();
    });
  }
  
  service.addListener(onServiceChanged);
  
  // Ensure listener is removed when provider is disposed
  ref.onDispose(() {
    service.removeListener(onServiceChanged);
  });
  
  return service;
});

/// StreamProvider that properly emits tracking state changes
final isTrackingProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(trackingServiceProvider);
  
  // Create a stream controller to emit tracking state changes
  final controller = StreamController<bool>();
  
  // Emit initial state
  controller.add(service.isTracking);
  
  // Listen for changes and emit new values
  void onTrackingChanged() {
    if (!controller.isClosed) {
      controller.add(service.isTracking);
    }
  }
  
  service.addListener(onTrackingChanged);
  
  // Clean up when provider is disposed
  ref.onDispose(() {
    service.removeListener(onTrackingChanged);
    controller.close();
  });
  
  return controller.stream;
});
