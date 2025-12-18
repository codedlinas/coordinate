import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/background_location_service.dart';
import '../../services/foreground_location_service.dart';
import '../../state/providers.dart';
import '../theme/app_theme.dart';

/// Screen showing the health/status of background location tracking.
/// 
/// WARNING: Background location tracking is subject to OS limitations:
/// - Android: Battery optimization, Doze mode, OEM-specific restrictions
/// - iOS: Significant location change throttling, background app refresh settings
/// 
/// TODO: Add links to device-specific battery optimization settings
/// TODO: Consider adding a "test notification" feature
class TrackingHealthScreen extends ConsumerStatefulWidget {
  const TrackingHealthScreen({super.key});

  @override
  ConsumerState<TrackingHealthScreen> createState() => _TrackingHealthScreenState();
}

class _TrackingHealthScreenState extends ConsumerState<TrackingHealthScreen> {
  Map<String, dynamic>? _healthInfo;
  bool _isLoading = true;
  bool _isToggling = false;
  bool _isTogglingForeground = false;
  Map<String, dynamic>? _foregroundStatus;

  @override
  void initState() {
    super.initState();
    _loadHealthInfo();
  }

  Future<void> _loadHealthInfo() async {
    setState(() => _isLoading = true);
    try {
      final bgService = ref.read(backgroundLocationServiceProvider);
      final info = await bgService.getHealthInfo();
      
      // Load foreground service status on Android
      Map<String, dynamic>? fgStatus;
      if (ForegroundLocationService.isSupported) {
        final fgService = ref.read(foregroundLocationServiceProvider);
        fgStatus = fgService.getStatus();
      }
      
      if (mounted) {
        setState(() {
          _healthInfo = info;
          _foregroundStatus = fgStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _healthInfo = {'lastError': 'Failed to load: $e'};
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleBackgroundTracking() async {
    if (_isToggling) return;
    
    setState(() => _isToggling = true);
    
    try {
      final bgService = ref.read(backgroundLocationServiceProvider);
      final isEnabled = _healthInfo?['isEnabled'] == true;
      
      if (isEnabled) {
        await bgService.disableBackgroundTracking();
      } else {
        final success = await bgService.enableBackgroundTracking();
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(bgService.lastError ?? 'Failed to enable background tracking'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
      
      await _loadHealthInfo();
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
    }
  }

  Future<void> _toggleForegroundService() async {
    if (_isTogglingForeground || !ForegroundLocationService.isSupported) return;
    
    setState(() => _isTogglingForeground = true);
    
    try {
      final fgService = ref.read(foregroundLocationServiceProvider);
      final isEnabled = _foregroundStatus?['isEnabled'] == true;
      
      if (isEnabled) {
        await fgService.disable();
      } else {
        final success = await fgService.enable();
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to enable high-reliability mode'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
      
      await _loadHealthInfo();
    } finally {
      if (mounted) {
        setState(() => _isTogglingForeground = false);
      }
    }
  }

  Future<void> _forceLocationCheck() async {
    try {
      final bgService = ref.read(backgroundLocationServiceProvider);
      await bgService.forceLocationCheck();
      
      // Wait a moment for the check to complete
      await Future.delayed(const Duration(seconds: 2));
      await _loadHealthInfo();
      
      if (mounted) {
        // Refresh visits provider to show any new data
        ref.read(visitsProvider.notifier).refresh();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location check completed'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = _healthInfo?['isEnabled'] == true;
    final isTracking = _healthInfo?['isTracking'] == true;
    final permissionStatus = _healthInfo?['permissionStatus'] ?? 'Unknown';
    final lastUpdate = _healthInfo?['lastUpdate'];
    final lastError = _healthInfo?['lastError'];
    final currentCountry = _healthInfo?['currentCountry'];
    
    // New diagnostic fields
    final pendingCountry = _healthInfo?['pendingCountry'] as String?;
    final pendingCount = _healthInfo?['pendingCount'] as int? ?? 0;
    final pendingFirstSeen = _healthInfo?['pendingFirstSeen'] as String?;
    final lastGeocodeTime = _healthInfo?['lastGeocodeTime'] as String?;
    final lastLatitude = _healthInfo?['lastLatitude'] as double?;
    final lastLongitude = _healthInfo?['lastLongitude'] as double?;
    final lastCountrySource = _healthInfo?['lastCountrySource'] as String?;
    final isLocked = _healthInfo?['isLocked'] as bool? ?? false;
    final lockAcquiredAt = _healthInfo?['lockAcquiredAt'] as String?;
    
    // Platform info
    final trackingMode = _healthInfo?['trackingMode'] as String? ?? 'background';
    final isIOSForegroundOnly = trackingMode == 'foreground_only';
    final supportsBackground = _healthInfo?['supportsBackgroundTracking'] as bool? ?? true;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tracking Health'),
        backgroundColor: AppTheme.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHealthInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main toggle card - title varies by platform
                  _buildStatusCard(
                    title: isIOSForegroundOnly ? 'Location Tracking' : 'Background Tracking',
                    value: isEnabled ? 'ENABLED' : 'DISABLED',
                    valueColor: isEnabled ? AppTheme.success : AppTheme.textMuted,
                    icon: isEnabled ? Icons.location_on : Icons.location_off,
                    iconColor: isEnabled ? AppTheme.success : AppTheme.textMuted,
                    trailing: Switch(
                      value: isEnabled,
                      onChanged: _isToggling ? null : (_) => _toggleBackgroundTracking(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Platform-specific info banner
                  if (isIOSForegroundOnly)
                    _buildIOSInfoBanner()
                  else
                    _buildAndroidWarningBanner(),

                  // High-reliability mode (Android only)
                  if (ForegroundLocationService.isSupported && isEnabled) ...[
                    const SizedBox(height: 16),
                    _buildHighReliabilityModeCard(),
                  ],

                  const SizedBox(height: 24),

                  // Status section
                  Text(
                    'STATUS',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoRow(
                    'Permission',
                    permissionStatus,
                    _getPermissionColor(permissionStatus),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Tracking Active',
                    isTracking ? 'Yes' : 'No',
                    isTracking ? AppTheme.success : AppTheme.textMuted,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Tracking Mode',
                    isIOSForegroundOnly ? 'Foreground Only' : 'Background',
                    isIOSForegroundOnly ? Colors.blue : AppTheme.success,
                  ),
                  const SizedBox(height: 8),
                  if (currentCountry != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Current Country',
                      currentCountry,
                      AppTheme.textPrimary,
                    ),
                  ],
                  if (lastCountrySource != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Country Source',
                      lastCountrySource == 'fresh' ? 'Fresh (new)' : 'Cached (same)',
                      lastCountrySource == 'fresh' ? AppTheme.success : AppTheme.textSecondary,
                    ),
                  ],

                  // Pending country change section
                  if (pendingCountry != null) ...[
                    const SizedBox(height: 24),
                    _buildPendingCountrySection(
                      pendingCountry: pendingCountry,
                      pendingCount: pendingCount,
                      pendingFirstSeen: pendingFirstSeen,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Last update section
                  Text(
                    'LAST BACKGROUND UPDATE',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (lastUpdate != null) ...[
                          Text(
                            _formatDateTime(lastUpdate),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimeAgo(lastUpdate),
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ] else
                          Text(
                            'No background updates yet',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Error section
                  if (lastError != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'LAST ERROR',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        lastError,
                        style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Force check button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isEnabled ? _forceLocationCheck : null,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Force Location Check Now'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  // Developer diagnostics (only in debug mode)
                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    _buildDeveloperDiagnostics(
                      lastGeocodeTime: lastGeocodeTime,
                      lastLatitude: lastLatitude,
                      lastLongitude: lastLongitude,
                      isLocked: isLocked,
                      lockAcquiredAt: lockAcquiredAt,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // OS Limitations info
                  Text(
                    'OS LIMITATIONS',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLimitationItem(
                    'Android',
                    'Uses WorkManager for periodic checks (minimum 15 min interval). '
                    'Some manufacturers (Samsung, Xiaomi, Huawei) may kill background tasks. '
                    'Disable battery optimization for best results.',
                  ),
                  const SizedBox(height: 8),
                  _buildLimitationItem(
                    'iOS',
                    'Background fetch is controlled by iOS and may be infrequent. '
                    'Background App Refresh must be enabled in Settings. '
                    'For reliable tracking, keep the app open.',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconColor,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitationItem(String platform, String description) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            platform,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighReliabilityModeCard() {
    final isEnabled = _foregroundStatus?['isEnabled'] == true;
    final isRunning = _foregroundStatus?['isRunning'] == true;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? AppTheme.success.withValues(alpha: 0.5) : AppTheme.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isEnabled 
                      ? AppTheme.success.withValues(alpha: 0.15)
                      : AppTheme.textMuted.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.speed,
                  color: isEnabled ? AppTheme.success : AppTheme.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'High Reliability Mode',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEnabled 
                          ? (isRunning ? 'Active' : 'Starting...')
                          : 'Disabled',
                      style: TextStyle(
                        color: isEnabled ? AppTheme.success : AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: _isTogglingForeground 
                    ? null 
                    : (_) => _toggleForegroundService(),
                activeColor: AppTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Uses a foreground service for more frequent location checks (~5 min). '
            'Shows a persistent notification. Uses more battery.',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_iphone, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'iOS Foreground Tracking',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Location is checked when you open the app. For accurate trip tracking:',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          _buildIOSTip(Icons.open_in_new, 'Open the app when arriving in a new country'),
          const SizedBox(height: 4),
          _buildIOSTip(Icons.edit, 'Use manual edits to adjust trip times'),
          const SizedBox(height: 4),
          _buildIOSTip(Icons.notifications_active, 'Enable reminders for border crossings'),
        ],
      ),
    );
  }

  Widget _buildIOSTip(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAndroidWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Background tracking may be limited by battery optimization. '
              'For best results, disable battery optimization for Coordinate in device settings.',
              style: TextStyle(
                color: AppTheme.warning,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCountrySection({
    required String pendingCountry,
    required int pendingCount,
    String? pendingFirstSeen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PENDING COUNTRY CHANGE',
          style: TextStyle(
            color: AppTheme.warning,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.pending_outlined, color: AppTheme.warning, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Waiting to confirm: $pendingCountry',
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Checks: $pendingCount/2 required',
                style: TextStyle(
                  color: AppTheme.warning.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
              if (pendingFirstSeen != null) ...[
                const SizedBox(height: 4),
                Text(
                  'First seen: ${_formatTimeAgo(pendingFirstSeen)}',
                  style: TextStyle(
                    color: AppTheme.warning.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Border debounce prevents false trips from GPS variance near borders.',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeveloperDiagnostics({
    String? lastGeocodeTime,
    double? lastLatitude,
    double? lastLongitude,
    bool isLocked = false,
    String? lockAcquiredAt,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bug_report, color: AppTheme.textMuted, size: 16),
            const SizedBox(width: 6),
            Text(
              'DEVELOPER DIAGNOSTICS',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lastGeocodeTime != null)
                _buildDiagnosticRow('Last Geocode', _formatDateTime(lastGeocodeTime)),
              if (lastLatitude != null && lastLongitude != null) ...[
                const SizedBox(height: 8),
                _buildDiagnosticRow(
                  'Last Coordinates',
                  '${lastLatitude.toStringAsFixed(4)}, ${lastLongitude.toStringAsFixed(4)}',
                ),
              ],
              const SizedBox(height: 8),
              _buildDiagnosticRow(
                'Task Lock',
                isLocked ? 'LOCKED' : 'Free',
                valueColor: isLocked ? AppTheme.warning : AppTheme.success,
              ),
              if (isLocked && lockAcquiredAt != null) ...[
                const SizedBox(height: 4),
                _buildDiagnosticRow(
                  'Lock Acquired',
                  _formatTimeAgo(lockAcquiredAt),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.textSecondary,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Color _getPermissionColor(String status) {
    switch (status.toLowerCase()) {
      case 'always':
        return AppTheme.success;
      case 'when in use':
        return AppTheme.warning;
      case 'denied':
      case 'restricted':
        return AppTheme.error;
      default:
        return AppTheme.textMuted;
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('MMM d, yyyy • HH:mm:ss').format(dt);
    } catch (e) {
      return isoString;
    }
  }

  String _formatTimeAgo(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final diff = DateTime.now().toUtc().difference(dt);
      
      if (diff.inMinutes < 1) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} minute${diff.inMinutes != 1 ? 's' : ''} ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hour${diff.inHours != 1 ? 's' : ''} ago';
      } else {
        return '${diff.inDays} day${diff.inDays != 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return '';
    }
  }
}

