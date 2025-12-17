import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      if (mounted) {
        setState(() {
          _healthInfo = info;
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
                  // Main toggle card
                  _buildStatusCard(
                    title: 'Background Tracking',
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

                  // Warning banner
                  Container(
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
                            'Background tracking may be limited by OS battery optimization. '
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
                  ),

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
                  // Motion state not available with WorkManager approach
                  // TODO: Add motion detection via sensors if needed
                  if (currentCountry != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Current Country',
                      currentCountry,
                      AppTheme.textPrimary,
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

