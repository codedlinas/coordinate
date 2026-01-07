import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:country_flags/country_flags.dart';
import '../../data/models/models.dart';
import '../../services/sync_service.dart';
import '../../state/providers.dart';
import '../../state/tracking_provider.dart';
import '../../services/tracking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/palette_picker.dart';
import '../widgets/themed_card.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'timeline_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showTrackingOverlay = false;
  bool _isRefreshing = false;

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();
    
    ref.read(visitsProvider.notifier).refresh();
    
    // Small delay to show refresh indicator
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  String _formatCompactDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final mins = duration.inMinutes % 60;
    
    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final visits = ref.watch(visitsProvider);
    final trackingService = ref.watch(trackingServiceProvider);
    final isTracking = trackingService.isTracking;
    final currentVisit = ref.watch(currentVisitProvider);
    final uniqueCountries = ref.watch(uniqueCountriesProvider);
    
    // Watch time ticker to trigger periodic rebuilds for time-based displays
    // (e.g., "Last 24 Hours" section updates as time passes)
    ref.watch(timeTickerProvider);

    // Calculate days tracked
    final firstVisit = visits.isNotEmpty
        ? visits.map((v) => v.entryTime).reduce((a, b) => a.isBefore(b) ? a : b)
        : null;
    final daysTracked = firstVisit != null
        ? DateTime.now().difference(firstVisit).inDays.toDouble()
        : 0.0;

    // Filter visits for last 24 hours
    // A visit should show if any part of it falls within the last 24 hours:
    // - Entry time is within 24 hours, OR
    // - Exit time is within 24 hours, OR
    // - Visit is ongoing (no exit time = still there now)
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
    final last24Hours = visits
        .where((v) {
          // Ongoing visit - always include (you're there now)
          if (v.exitTime == null) return true;
          // Entry within last 24 hours
          if (v.entryTime.isAfter(twentyFourHoursAgo)) return true;
          // Exit within last 24 hours
          if (v.exitTime!.isAfter(twentyFourHoursAgo)) return true;
          return false;
        })
        .toList()
      ..sort((a, b) => b.entryTime.compareTo(a.entryTime));

    // Group by country for last 24 hours
    final countriesLast24h = <String, List<CountryVisit>>{};
    for (final visit in last24Hours) {
      countriesLast24h.putIfAbsent(visit.countryCode, () => []).add(visit);
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Coordinate'),
        backgroundColor: AppTheme.background,
        elevation: 0,
        actions: [
          // Sync status indicator
          _SyncStatusButton(),
          // Palette toggle button
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Theme Palette',
            onPressed: () => showPalettePicker(context),
          ),
          IconButton(
            icon: const Icon(Icons.timeline),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TimelineScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content with pull-to-refresh
          RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppTheme.primary,
            backgroundColor: AppTheme.surface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Country Banner (when tracking)
                  if (isTracking && currentVisit != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          CountryFlag.fromCountryCode(
                            currentVisit.countryCode,
                            width: 24,
                            height: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Currently in ${currentVisit.countryName}',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            _formatCompactDuration(currentVisit.duration),
                            style: TextStyle(
                              color: AppTheme.success.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Stats Row: Days Tracked + Countries Visited
                  Row(
                    children: [
                      // Days Tracked Card
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.secondary.withValues(alpha: 0.8),
                                AppTheme.primary.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                daysTracked.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Days Tracked',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Countries Visited Card
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.public,
                                color: AppTheme.primary,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${uniqueCountries.length}',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                uniqueCountries.length == 1 ? 'Country' : 'Countries',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Last 24 Hours Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Last 24 Hours',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (_isRefreshing)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Countries List
                  if (countriesLast24h.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.flight_takeoff_rounded,
                            size: 48,
                            color: AppTheme.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No visits in the last 24 hours',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start tracking to record your travels',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...countriesLast24h.entries.map<Widget>((entry) {
                      final countryCode = entry.key;
                      final countryVisits = entry.value;
                      final totalDuration = countryVisits.fold<Duration>(
                        Duration.zero,
                        (sum, visit) => sum + visit.duration,
                      );
                      final isOngoing = countryVisits.any((v) => v.isOngoing);

                      return _buildCountryCard(
                        context,
                        countryCode: countryCode,
                        countryName: countryVisits.first.countryName,
                        duration: totalDuration,
                        index: countriesLast24h.keys.toList().indexOf(countryCode) + 1,
                        isOngoing: isOngoing,
                      );
                    }),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Tracking Overlay
          if (_showTrackingOverlay)
            Positioned(
              top: 80,
              left: 16,
              child: _buildTrackingOverlay(context, ref, trackingService),
            ),

          // Tracking Button (FAB)
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _showTrackingOverlay = !_showTrackingOverlay;
                });
              },
              backgroundColor: isTracking ? AppTheme.success : AppTheme.primary,
              child: Icon(
                isTracking ? Icons.location_on : Icons.location_off,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryCard(
    BuildContext context, {
    required String countryCode,
    required String countryName,
    required Duration duration,
    required int index,
    required bool isOngoing,
  }) {
    final palette = AppTheme.currentPalette;
    
    return ThemedCard(
      margin: const EdgeInsets.only(bottom: 12),
      isHighlighted: isOngoing,
      highlightColor: AppTheme.primary,
      child: Row(
        children: [
          // Index Circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * palette.fontSizeMultiplier,
                ),
              ),
            ),
          ),

          SizedBox(width: 14 * palette.spacingMultiplier),

          // Flag
          CountryFlag.fromCountryCode(
            countryCode,
            width: 36,
            height: 26,
          ),

          SizedBox(width: 14 * palette.spacingMultiplier),

          // Country Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        countryName,
                        style: TextStyle(
                          fontSize: 15 * palette.fontSizeMultiplier,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOngoing) ...[
                      const SizedBox(width: 8),
                      ThemedChip(
                        label: 'NOW',
                        color: AppTheme.primary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Duration indicator bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isOngoing ? AppTheme.primary : AppTheme.warning,
                    borderRadius: BorderRadius.circular(palette.chipRadius / 2),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 14 * palette.spacingMultiplier),

          // Compact Duration
          Text(
            _formatCompactDuration(duration),
            style: TextStyle(
              fontSize: 15 * palette.fontSizeMultiplier,
              fontWeight: FontWeight.bold,
              color: isOngoing ? AppTheme.primary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingOverlay(
    BuildContext context,
    WidgetRef ref,
    TrackingService trackingService,
  ) {
    final isTracking = trackingService.isTracking;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isTracking ? AppTheme.success : AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tracking ${isTracking ? "ON" : "OFF"}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.white),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _showTrackingOverlay = false;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Current Location - show if we have an ongoing visit
            _TrackingCountryDisplay(
              trackingService: trackingService,
            ),

            // Start Button (when not tracking)
            if (!isTracking)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    try {
                      await trackingService.startTracking();
                      if (mounted) {
                        setState(() {});
                        await Future.delayed(const Duration(milliseconds: 3000));
                        if (mounted) {
                          ref.read(visitsProvider.notifier).refresh();
                          setState(() {});
                        }
                        for (int i = 0; i < 5; i++) {
                          await Future.delayed(const Duration(milliseconds: 500));
                          if (mounted && trackingService.isTracking) {
                            ref.read(visitsProvider.notifier).refresh();
                            setState(() {});
                          } else {
                            break;
                          }
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to start tracking: $e'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

            // Stop Button (when tracking)
            if (isTracking)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await trackingService.stopTracking();
                    if (mounted) {
                      ref.read(visitsProvider.notifier).refresh();
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Stop',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widget to display current tracking country with reactive updates
class _TrackingCountryDisplay extends ConsumerStatefulWidget {
  final TrackingService trackingService;

  const _TrackingCountryDisplay({
    required this.trackingService,
  });

  @override
  ConsumerState<_TrackingCountryDisplay> createState() => _TrackingCountryDisplayState();
}

class _TrackingCountryDisplayState extends ConsumerState<_TrackingCountryDisplay> {
  @override
  void initState() {
    super.initState();
    widget.trackingService.addListener(_onTrackingChanged);
  }

  @override
  void dispose() {
    widget.trackingService.removeListener(_onTrackingChanged);
    super.dispose();
  }

  void _onTrackingChanged() {
    if (mounted) {
      // Refresh visits when tracking state changes (e.g., new visit created)
      ref.read(visitsProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the current visit from the provider - this is reactive via Riverpod
    final currentVisit = ref.watch(currentVisitProvider);

    if (currentVisit != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            CountryFlag.fromCountryCode(
              currentVisit.countryCode,
              width: 28,
              height: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                currentVisit.countryName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Sync status button for the app bar
class _SyncStatusButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SyncStatusButton> createState() => _SyncStatusButtonState();
}

class _SyncStatusButtonState extends ConsumerState<_SyncStatusButton> {
  bool _isSyncing = false;

  Future<void> _handleSync() async {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    
    if (!isAuthenticated) {
      // Not logged in - go to profile screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }
    
    // Trigger sync
    setState(() => _isSyncing = true);
    HapticFeedback.lightImpact();
    
    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.sync();
      
      if (mounted) {
        ref.read(visitsProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sync completed'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    
    // Determine icon and color based on state
    IconData icon;
    Color? color;
    
    if (_isSyncing || syncStatus == SyncStatus.syncing) {
      icon = Icons.sync;
      color = AppTheme.primary;
    } else if (!isAuthenticated) {
      icon = Icons.cloud_off_outlined;
      color = AppTheme.textMuted;
    } else if (syncStatus == SyncStatus.error) {
      icon = Icons.cloud_off;
      color = AppTheme.error;
    } else {
      icon = Icons.cloud_done_outlined;
      color = AppTheme.success;
    }
    
    return IconButton(
      icon: _isSyncing
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppTheme.primary),
              ),
            )
          : Icon(icon, color: color),
      tooltip: isAuthenticated ? 'Sync' : 'Sign in to sync',
      onPressed: _isSyncing ? null : _handleSync,
    );
  }
}
