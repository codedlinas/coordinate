import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:country_flags/country_flags.dart';
import 'package:intl/intl.dart';
import '../../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class CountryDetailScreen extends ConsumerWidget {
  final String countryCode;

  const CountryDetailScreen({
    super.key,
    required this.countryCode,
  });

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      return '$days day${days != 1 ? 's' : ''}, $hours hr${hours != 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      final hours = duration.inHours;
      final mins = duration.inMinutes % 60;
      return '$hours hr${hours != 1 ? 's' : ''}, $mins min';
    } else {
      final mins = duration.inMinutes;
      return '$mins minute${mins != 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(countryStatsProvider(countryCode));
    final currentVisit = ref.watch(currentVisitProvider);
    final isCurrentLocation = currentVisit?.countryCode == countryCode;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: PhoneWrapper(
        child: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppTheme.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.3),
                          AppTheme.background,
                        ],
                      ),
                    ),
                  ),
                  // Country info
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Flag
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CountryFlag.fromCountryCode(
                            countryCode,
                            width: 100,
                            height: 70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Country name
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              stats.countryName,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            if (isCurrentLocation) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: AppTheme.background,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'NOW',
                                      style: TextStyle(
                                        color: AppTheme.background,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          countryCode,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          context,
                          Icons.flight_land_rounded,
                          '${stats.totalVisits}',
                          'Total Visits',
                          AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          context,
                          Icons.schedule_rounded,
                          _formatDuration(stats.totalDuration),
                          'Time Spent',
                          AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          context,
                          Icons.calendar_today_rounded,
                          stats.firstVisit != null
                              ? dateFormat.format(stats.firstVisit!)
                              : 'N/A',
                          'First Visit',
                          AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          context,
                          Icons.update_rounded,
                          stats.lastVisit != null
                              ? dateFormat.format(stats.lastVisit!)
                              : 'N/A',
                          'Last Visit',
                          AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Timeline Header
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Visit Timeline',
              subtitle: '${stats.totalVisits} visits recorded',
            ),
          ),

          // Timeline List
          if (stats.visits.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No visits recorded',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final visit = stats.visits[index];
                    return VisitTimelineItem(
                      visit: visit,
                      isFirst: index == 0,
                      isLast: index == stats.visits.length - 1,
                      onDelete: () => _showDeleteVisitDialog(
                        context,
                        ref,
                        visit.id,
                        visit.entryTime,
                      ),
                    );
                  },
                  childCount: stats.visits.length,
                ),
              ),
            ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
        ),
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showDeleteVisitDialog(
    BuildContext context,
    WidgetRef ref,
    String visitId,
    DateTime entryTime,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Visit?'),
        content: Text(
          'Delete the visit from ${dateFormat.format(entryTime)}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(visitsProvider.notifier).deleteVisit(visitId);
              Navigator.pop(context);

              // If no more visits for this country, go back
              final remaining = ref
                  .read(visitsRepositoryProvider)
                  .getVisitsForCountry(countryCode);
              if (remaining.isEmpty && context.mounted) {
                Navigator.pop(context);
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Visit deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
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
}

