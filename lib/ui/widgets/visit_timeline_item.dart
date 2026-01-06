import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/models.dart';
import '../theme/app_theme.dart';

class VisitTimelineItem extends StatelessWidget {
  final CountryVisit visit;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onDelete;

  const VisitTimelineItem({
    super.key,
    required this.visit,
    this.isFirst = false,
    this.isLast = false,
    this.onDelete,
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
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Top line
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 16,
                    color: AppTheme.divider,
                  ),

                // Dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: visit.isOngoing ? AppTheme.primary : AppTheme.surfaceLight,
                    border: Border.all(
                      color: visit.isOngoing ? AppTheme.primary : AppTheme.textMuted,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),

                // Bottom line
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : AppTheme.divider,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: visit.isOngoing
                    ? AppTheme.primary.withValues(alpha: 0.1)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: visit.isOngoing ? AppTheme.primary : AppTheme.cardBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      if (visit.isOngoing)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ONGOING',
                            style: TextStyle(
                              color: AppTheme.background,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          dateFormat.format(visit.entryTime),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18),
                          onPressed: onDelete,
                          color: AppTheme.textMuted,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Entry time
                  _buildTimeRow(
                    context,
                    'Entry',
                    timeFormat.format(visit.entryTime),
                    Icons.flight_land_rounded,
                    AppTheme.success,
                  ),
                  const SizedBox(height: 8),

                  // Exit time
                  _buildTimeRow(
                    context,
                    'Exit',
                    visit.exitTime != null
                        ? timeFormat.format(visit.exitTime!)
                        : 'Still here',
                    Icons.flight_takeoff_rounded,
                    visit.exitTime != null ? AppTheme.accent : AppTheme.primary,
                  ),

                  // Duration
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDuration(visit.duration),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Location details
                  if (visit.city != null || visit.region != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [visit.city, visit.region]
                                .where((e) => e != null)
                                .join(', '),
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(
    BuildContext context,
    String label,
    String time,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          time,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
        ),
      ],
    );
  }
}










