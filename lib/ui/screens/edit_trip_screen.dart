import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../theme/app_theme.dart';

class EditTripScreen extends ConsumerStatefulWidget {
  final String visitId;

  const EditTripScreen({super.key, required this.visitId});

  @override
  ConsumerState<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends ConsumerState<EditTripScreen> {
  DateTime? _arrivalUtc;
  DateTime? _departureUtc;

  @override
  void initState() {
    super.initState();
    final visits = ref.read(visitsProvider);
    final visit = visits.firstWhere(
      (v) => v.id == widget.visitId,
      orElse: () => throw StateError('Visit not found'),
    );
    _arrivalUtc = visit.entryTime.toUtc();
    _departureUtc = visit.exitTime?.toUtc();
  }

  Future<void> _pickArrivalDate(BuildContext context) async {
    if (_arrivalUtc == null) return;
    final initial = _arrivalUtc!.toLocal();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _arrivalUtc = DateTime.utc(
          picked.year,
          picked.month,
          picked.day,
        );
      });
    }
  }

  Future<void> _pickDepartureDate(BuildContext context) async {
    final base = _departureUtc ?? _arrivalUtc ?? DateTime.now().toUtc();
    final initial = base.toLocal();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _departureUtc = DateTime.utc(
          picked.year,
          picked.month,
          picked.day,
        );
      });
    }
  }

  Future<void> _save(BuildContext context) async {
    final arrival = _arrivalUtc;
    final departure = _departureUtc;

    if (arrival == null) return;

    if (departure != null && departure.isBefore(arrival)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Departure date must be on or after arrival.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final visitsNotifier = ref.read(visitsProvider.notifier);
    final visits = ref.read(visitsProvider);
    final existing = visits.firstWhere((v) => v.id == widget.visitId);

    final updated = existing.copyWith(
      entryTime: arrival.toUtc(),
      exitTime: departure?.toUtc(),
    );

    // TODO: When background tracking or external sync is added,
    //       ensure that manual trip edits are reconciled with
    //       any new segments or remote changes.
    await visitsNotifier.updateVisit(updated);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final arrival = _arrivalUtc;
    final departure = _departureUtc;

    final arrivalText = arrival != null
        ? '${arrival.year}-${arrival.month.toString().padLeft(2, '0')}-${arrival.day.toString().padLeft(2, '0')}'
        : 'Unknown';

    final departureText = departure != null
        ? '${departure.year}-${departure.month.toString().padLeft(2, '0')}-${departure.day.toString().padLeft(2, '0')}'
        : 'Ongoing';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Edit Trip'),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDateRow(
              context: context,
              label: 'Arrival',
              value: arrivalText,
              onTap: () => _pickArrivalDate(context),
            ),
            const SizedBox(height: 16),
            _buildDateRow(
              context: context,
              label: 'Departure',
              value: departureText,
              onTap: () => _pickDepartureDate(context),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: AppTheme.background,
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

  Widget _buildDateRow({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}


