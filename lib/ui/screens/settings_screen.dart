import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../services/export_service.dart';
import '../../services/sync_service.dart';
import '../../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'profile_screen.dart';
import 'tracking_health_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.background,
      ),
      body: PhoneWrapper(
        child: ListView(
          children: [
            // Location Accuracy Section
            const SectionHeader(
              title: 'Location Accuracy',
              subtitle: 'Balance between precision and battery life',
            ),
            _buildAccuracySelector(context, ref, settings),

            // Tracking Interval Section
            const SectionHeader(
              title: 'Tracking Interval',
              subtitle: 'How often to check your location',
            ),
            _buildIntervalSelector(context, ref, settings),

            // Notifications Section
            const SectionHeader(
              title: 'Notifications',
              subtitle: 'Manage your alerts',
            ),
            _buildNotificationSettings(context, ref, settings),

            // Background Tracking Section
            const SectionHeader(
              title: 'Background Tracking',
              subtitle: 'Track country changes when app is closed',
            ),
            _buildBackgroundTrackingSection(context),

            // Account Section
            const SectionHeader(
              title: 'Account',
              subtitle: 'Sync and cloud backup',
            ),
            _buildAccountSection(context, ref),

            // Cloud Sync Section (only shown when authenticated)
            if (ref.watch(isAuthenticatedProvider)) ...[
              const SectionHeader(
                title: 'Cloud Sync',
                subtitle: 'Keep your travel data backed up',
              ),
              _buildCloudSyncSection(context, ref),
            ],

            // Data Management Section
            const SectionHeader(
              title: 'Data Management',
              subtitle: 'Export, import, and manage your data',
            ),
            _buildDataManagement(context, ref),

            // About Section
            const SectionHeader(
              title: 'About',
              subtitle: 'App information',
            ),
            _buildAboutSection(context),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracySelector(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: LocationAccuracy.values.map((accuracy) {
          final isSelected = settings.accuracy == accuracy;
          final info = _getAccuracyInfo(accuracy);

          return InkWell(
            onTap: () {
              ref.read(settingsProvider.notifier).setAccuracy(accuracy);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: accuracy != LocationAccuracy.values.last
                    ? Border(
                        bottom: BorderSide(color: AppTheme.divider),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? info['color'] as Color
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      info['icon'] as IconData,
                      color: isSelected
                          ? AppTheme.background
                          : AppTheme.textMuted,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info['title'] as String,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          info['description'] as String,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Radio<LocationAccuracy>(
                    value: accuracy,
                    groupValue: settings.accuracy,
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).setAccuracy(value);
                      }
                    },
                    activeColor: AppTheme.primary,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Map<String, dynamic> _getAccuracyInfo(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.low:
        return {
          'title': 'Battery Saver',
          'description': '~500m accuracy, minimal battery usage',
          'icon': Icons.battery_full_rounded,
          'color': AppTheme.success,
        };
      case LocationAccuracy.medium:
        return {
          'title': 'Balanced',
          'description': '~100m accuracy, moderate battery',
          'icon': Icons.battery_5_bar_rounded,
          'color': AppTheme.warning,
        };
      case LocationAccuracy.high:
        return {
          'title': 'High Precision',
          'description': '~10m accuracy, higher battery usage',
          'icon': Icons.gps_fixed_rounded,
          'color': AppTheme.accent,
        };
    }
  }

  Widget _buildIntervalSelector(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    final intervals = [5, 15, 30, 60, 120];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.timer_rounded,
                  color: AppTheme.secondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.trackingIntervalDescription,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Check location periodically',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: intervals.map((mins) {
              final isSelected = settings.trackingIntervalMinutes == mins;
              final label = mins < 60 ? '${mins}m' : '${mins ~/ 60}h';

              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) {
                  ref
                      .read(settingsProvider.notifier)
                      .setTrackingInterval(mins);
                },
                selectedColor: AppTheme.primary,
                backgroundColor: AppTheme.surfaceLight,
                labelStyle: TextStyle(
                  color:
                      isSelected ? AppTheme.background : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Master toggle for all alerts'),
            value: settings.notificationsEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setNotificationsEnabled(value);
            },
            secondary: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            title: const Text('Country Change Alerts'),
            subtitle: const Text('Notify when entering a new country'),
            value: settings.countryChangeNotifications,
            onChanged: settings.notificationsEnabled
                ? (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setCountryChangeNotifications(value);
                  }
                : null,
            secondary: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.flight_land_rounded,
                color: AppTheme.success,
                size: 22,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            title: const Text('Weekly Digest'),
            subtitle: const Text('Summary of your travels each week'),
            value: settings.weeklyDigestNotifications,
            onChanged: settings.notificationsEnabled
                ? (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setWeeklyDigestNotifications(value);
                  }
                : null,
            secondary: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.summarize_rounded,
                color: AppTheme.secondary,
                size: 22,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            title: const Text('Travel Reminders'),
            subtitle: Text(settings.travelRemindersEnabled
                ? 'Daily at ${settings.travelReminderTimeDescription}'
                : 'Remind me to open app when traveling'),
            value: settings.travelRemindersEnabled,
            onChanged: settings.notificationsEnabled
                ? (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setTravelRemindersEnabled(value);
                  }
                : null,
            secondary: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.airplanemode_active_rounded,
                color: AppTheme.accent,
                size: 22,
              ),
            ),
          ),
          if (settings.travelRemindersEnabled && settings.notificationsEnabled)
            ListTile(
              title: const Text('Reminder Time'),
              subtitle: Text(settings.travelReminderTimeDescription),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  color: AppTheme.accent,
                  size: 22,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showTimePickerDialog(context, ref, settings),
            ),
        ],
      ),
    );
  }
  
  void _showTimePickerDialog(BuildContext context, WidgetRef ref, AppSettings settings) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.travelReminderHour,
        minute: settings.travelReminderMinute,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppTheme.surface,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (selectedTime != null) {
      ref.read(settingsProvider.notifier).setTravelReminderTime(
        selectedTime.hour,
        selectedTime.minute,
      );
    }
  }

  Widget _buildBackgroundTrackingSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.my_location_rounded,
            color: AppTheme.primary,
            size: 22,
          ),
        ),
        title: const Text('Tracking Health'),
        subtitle: const Text('View status, permissions & diagnostics'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TrackingHealthScreen()),
          );
        },
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final user = ref.watch(currentUserProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isAuthenticated
                ? AppTheme.success.withValues(alpha: 0.15)
                : AppTheme.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isAuthenticated ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: isAuthenticated ? AppTheme.success : AppTheme.secondary,
            size: 22,
          ),
        ),
        title: Text(isAuthenticated ? 'Account' : 'Sign In'),
        subtitle: Text(
          isAuthenticated
              ? user?.email ?? 'Signed in'
              : 'Enable cloud backup & sync',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
      ),
    );
  }

  Widget _buildCloudSyncSection(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);
    final syncStatus = ref.watch(syncStatusStreamProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          // Cloud Sync Toggle
          SwitchListTile(
            title: const Text('Auto-Sync'),
            subtitle: const Text('Automatically sync visits to cloud'),
            value: syncService.cloudSyncEnabled,
            onChanged: (value) async {
              await syncService.setCloudSyncEnabled(value);
              // Force rebuild
              ref.invalidate(syncServiceProvider);
            },
            secondary: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.sync_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          // Sync Status & Sync Now
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getSyncStatusColor(syncStatus.value ?? syncService.status)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _getSyncStatusIcon(syncStatus.value ?? syncService.status),
            ),
            title: Text(_getSyncStatusText(syncStatus.value ?? syncService.status)),
            subtitle: Text(_getSyncStatusSubtitle(syncService)),
            trailing: TextButton(
              onPressed: syncService.status == SyncStatus.syncing
                  ? null
                  : () async {
                      try {
                        await syncService.sync();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sync completed'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sync failed: $e'),
                              backgroundColor: AppTheme.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              child: syncService.status == SyncStatus.syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sync Now'),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          
          // Delete Cloud Data
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                color: AppTheme.error,
                size: 22,
              ),
            ),
            title: const Text('Delete Cloud Data'),
            subtitle: const Text('Remove all data from servers'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showDeleteCloudDataDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Color _getSyncStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
      case SyncStatus.success:
        return AppTheme.success;
      case SyncStatus.syncing:
        return AppTheme.primary;
      case SyncStatus.pending:
        return AppTheme.warning;
      case SyncStatus.error:
        return AppTheme.error;
    }
  }

  Widget _getSyncStatusIcon(SyncStatus status) {
    IconData icon;
    Color color = _getSyncStatusColor(status);
    
    switch (status) {
      case SyncStatus.idle:
      case SyncStatus.success:
        icon = Icons.check_circle_rounded;
        break;
      case SyncStatus.syncing:
        icon = Icons.sync_rounded;
        break;
      case SyncStatus.pending:
        icon = Icons.pending_rounded;
        break;
      case SyncStatus.error:
        icon = Icons.error_rounded;
        break;
    }
    
    return Icon(icon, color: color, size: 22);
  }

  String _getSyncStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
      case SyncStatus.success:
        return 'Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.pending:
        return 'Pending Changes';
      case SyncStatus.error:
        return 'Sync Failed';
    }
  }

  String _getSyncStatusSubtitle(SyncService syncService) {
    final lastSync = syncService.lastSyncTime;
    if (lastSync == null) {
      return 'Never synced';
    }
    
    final now = DateTime.now();
    final diff = now.difference(lastSync);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }

  void _showDeleteCloudDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: AppTheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Delete Cloud Data?'),
          ],
        ),
        content: const Text(
          'This will permanently delete all your travel data from our servers. '
          'Your local data on this device will NOT be affected.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final syncService = ref.read(syncServiceProvider);
                await syncService.deleteAllCloudData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cloud data deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete cloud data: $e'),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagement(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.file_download_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
            title: const Text('Export Data'),
            subtitle: const Text('Save your visits to JSON or CSV'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showExportDialog(context, ref),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.settings_backup_restore_rounded,
                color: AppTheme.warning,
                size: 22,
              ),
            ),
            title: const Text('Reset Settings'),
            subtitle: const Text('Restore default preferences'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showResetSettingsDialog(context, ref),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: AppTheme.error,
                size: 22,
              ),
            ),
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all visits permanently'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showClearDataDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.15),
                    AppTheme.secondary.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.public_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
            title: const Text('Coordinate'),
            subtitle: const Text('Version 1.0.0'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Flutter',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    final repository = ref.read(visitsRepositoryProvider);
    final exportService = ExportService(repository);
    final visitCount = exportService.getTotalVisitsCount();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Export Data',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$visitCount visits will be exported',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildExportOption(
                    context,
                    'JSON',
                    'Best for backup & import',
                    Icons.data_object_rounded,
                    AppTheme.primary,
                    () async {
                      Navigator.pop(context);
                      try {
                        await exportService.shareExport(ExportFormat.json);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Export failed: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExportOption(
                    context,
                    'CSV',
                    'Open in spreadsheet apps',
                    Icons.table_chart_rounded,
                    AppTheme.secondary,
                    () async {
                      Navigator.pop(context);
                      try {
                        await exportService.shareExport(ExportFormat.csv);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Export failed: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showResetSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Reset Settings?'),
        content: const Text(
          'This will restore all settings to their default values. Your travel data will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).resetSettings();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings have been reset'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: AppTheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Clear All Data?'),
          ],
        ),
        content: const Text(
          'This action cannot be undone. All your travel history will be permanently deleted. Consider exporting your data first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(visitsProvider.notifier).clearAllVisits();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data has been cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

