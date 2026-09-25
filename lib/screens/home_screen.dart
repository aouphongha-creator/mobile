import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/trip_form.dart';
import '../widgets/ui.dart';

/// "ทริปของฉัน" — list of all trips with status badges.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenTrip});

  final ValueChanged<String> onOpenTrip;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Trip whose card is currently expanded into the edit form.
  String? _editingId;

  Future<void> _delete(Trip trip) async {
    if (await confirmDelete(context, trip.name) && mounted) {
      await AppScope.read(context).deleteTrip(trip.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final trips = state.trips;

    return NavyPage(
      title: 'ทริปของฉัน',
      panelPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 90),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 6, bottom: 4),
                child: PanelHeading('รายการทั้งหมด'),
              ),
              if (trips.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'ยังไม่มีทริป กด + เพื่อเพิ่มทริปใหม่',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              for (final trip in trips)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: _TripCard(
                      trip: trip,
                      status: trip.statusOn(state.now),
                      spent: state.spentThb(trip),
                      editing: _editingId == trip.id,
                      onTap: () => widget.onOpenTrip(trip.id),
                      onEdit: () => setState(
                        () =>
                            _editingId = _editingId == trip.id ? null : trip.id,
                      ),
                      onEditDone: () => setState(() => _editingId = null),
                      onDelete: () => _delete(trip),
                    ),
                  ),
                ),
            ],
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: AddFab(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const TripFormScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.status,
    required this.spent,
    required this.editing,
    required this.onTap,
    required this.onEdit,
    required this.onEditDone,
    required this.onDelete,
  });

  final Trip trip;
  final TripStatus status;
  final double spent;
  final bool editing;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onEditDone;
  final VoidCallback onDelete;

  Color get _badgeColor => switch (status) {
    TripStatus.ongoing => AppColors.statusOngoing,
    TripStatus.planned => AppColors.statusPlanned,
    TripStatus.done => AppColors.statusDone,
  };

  @override
  Widget build(BuildContext context) {
    return BadgeCard(
      onTap: editing ? null : onTap,
      badge: Pill(color: _badgeColor, child: Text(status.label)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  trip.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              EditDeleteActions(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
          const SizedBox(height: 4),
          if (editing) ...[
            const Divider(height: 16, color: AppColors.cardBorder),
            TripForm(trip: trip, compact: true, onDone: onEditDone),
          ] else ...[
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'ปลายทาง:',
              value: trip.destination,
            ),
            _InfoRow(
              icon: Icons.calendar_month_outlined,
              label: 'ช่วงวันที่:',
              value: thaiRange(trip.start, trip.end),
            ),
            _InfoRow(
              icon: Icons.savings_outlined,
              label: 'งบประมาณ:',
              value: '${money(spent)} / ${money(trip.budget)} บาท',
              valueColor: spent > trip.budget ? AppColors.delete : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.text),
          const SizedBox(width: 6),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
