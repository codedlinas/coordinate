import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:country_flags/country_flags.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../../state/tracking_provider.dart';
import '../../services/tracking_service.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showTrackingOverlay = false;
  String _selectedPeriod = 'ALL'; // '365D' or 'ALL'

  @override
  Widget build(BuildContext context) {
    final visits = ref.watch(visitsProvider);
    final trackingService = ref.watch(trackingServiceProvider);
    final isTracking = trackingService.isTracking;

    // Calculate days tracked
    final firstVisit = visits.isNotEmpty
        ? visits.map((v) => v.entryTime).reduce((a, b) => a.isBefore(b) ? a : b)
        : null;
    final daysTracked = firstVisit != null
        ? DateTime.now().difference(firstVisit).inDays.toDouble()
        : 0.0;

    // Filter visits for last 24 hours
    final now = DateTime.now();
    final last24Hours = visits
        .where((v) => now.difference(v.entryTime).inHours < 24)
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
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
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
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Days Tracked Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
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
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        daysTracked.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Days Tracked',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Period Selector
                Row(
                  children: [
                    Expanded(
                      child: _buildPeriodButton('365D', _selectedPeriod == '365D'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPeriodButton('ALL', _selectedPeriod == 'ALL'),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Last 24 Hours Section
                const Text(
                  'Last 24 Hours',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                // Countries List
                if (countriesLast24h.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No visits in the last 24 hours',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
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
                    final days = totalDuration.inDays;
                    final hours = totalDuration.inHours % 24;
                    final minutes = totalDuration.inMinutes % 60;
                    final seconds = totalDuration.inSeconds % 60;

                    return _buildCountryCard(
                      context,
                      countryCode: countryCode,
                      countryName: countryVisits.first.countryName,
                      days: days,
                      hours: hours,
                      minutes: minutes,
                      seconds: seconds,
                      index: countriesLast24h.keys.toList().indexOf(countryCode) + 1,
                    );
                  }),

                const SizedBox(height: 100),
              ],
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
                setState(() {
                  _showTrackingOverlay = !_showTrackingOverlay;
                });
              },
              backgroundColor: AppTheme.primary,
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

  Widget _buildPeriodButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceLight : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCountryCard(
    BuildContext context, {
    required String countryCode,
    required String countryName,
    required int days,
    required int hours,
    required int minutes,
    required int seconds,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          // Index Circle
          Container(
            width: 40,
            height: 40,
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
                  fontSize: 18,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Flag
          CountryFlag.fromCountryCode(
            countryCode,
            width: 40,
            height: 30,
          ),

          const SizedBox(width: 16),

          // Country Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  countryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                // Duration indicator bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.warning,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Duration Text
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (days > 0)
                Text(
                  '$days days',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              Text(
                '(${days > 0 ? "$days.$hours" : hours}d)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
              Text(
                '${seconds}s',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
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
                    try {
                      await trackingService.startTracking();
                      if (mounted) {
                        setState(() {}); // Update UI to show tracking is ON
                        // Wait for location check to complete
                        await Future.delayed(const Duration(milliseconds: 3000));
                        // Force refresh to get the new visit
                        if (mounted) {
                          ref.read(visitsProvider.notifier).refresh();
                          setState(() {}); // Trigger rebuild to show country
                        }
                        // Continue refreshing periodically
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

            // Stop and Pause Buttons (when tracking)
            if (isTracking) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
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
              const SizedBox(height: 8),
              Center(
                child: IconButton(
                  icon: const Icon(Icons.pause, color: Colors.orange, size: 24),
                  onPressed: () {
                    // Pause functionality - can be implemented later
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ],
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
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Listen to tracking service changes
    widget.trackingService.addListener(_onTrackingChanged);
    // Set up periodic refresh while tracking
    _startRefreshTimer();
  }

  @override
  void dispose() {
    widget.trackingService.removeListener(_onTrackingChanged);
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _onTrackingChanged() {
    if (mounted && widget.trackingService.isTracking) {
      // Refresh visits provider when tracking service notifies
      ref.read(visitsProvider.notifier).refresh();
      setState(() {});
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    if (widget.trackingService.isTracking) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted) {
          ref.read(visitsProvider.notifier).refresh();
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get visit from service directly (most up-to-date)
    final serviceVisit = widget.trackingService.currentVisit;
    // Also watch provider as fallback
    final providerVisit = ref.watch(currentVisitProvider);
    final currentVisit = serviceVisit ?? providerVisit;

    // Restart timer if tracking state changed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.trackingService.isTracking) {
        _startRefreshTimer();
      } else {
        _refreshTimer?.cancel();
      }
    });

    if (currentVisit != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.public,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              currentVisit.countryName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
