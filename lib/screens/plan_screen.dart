import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/local_image.dart';
import '../widgets/plan_side_cards.dart';
import '../widgets/ui.dart';

/// "แผนการเดินทาง" — day tabs, activity timeline and the side dashboard
/// (weather, budget, exchange rate) for the selected trip.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  String? _tripId;
  int _dayIndex = 0;

  /// Activity being edited in place, or [_newKey] while adding.
  String? _formFor;
  static const _newKey = '__new__';

  void _syncTrip(Trip trip, DateTime now) {
    if (_tripId == trip.id) return;
    _tripId = trip.id;
    _formFor = null;
    // Open on today's tab when the trip is under way.
    final today = trip.days.indexOf(dateOnly(now));
    _dayIndex = today < 0 ? 0 : today;
  }

  Future<void> _pickImage(Activity a) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (file != null && mounted) {
      await AppScope.read(context).setActivityImage(a.id, file.path);
    }
  }

  Future<void> _delete(Activity a) async {
    if (await confirmDelete(context, a.name) && mounted) {
      await AppScope.read(context).deleteActivity(a.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final trip = state.selectedTrip;

    if (trip == null) {
      return NavyPage(
        title: 'แผนการเดินทาง',
        onBack: widget.onBack,
        child: const Center(
          child: Text(
            'ยังไม่มีทริป เพิ่มทริปได้ที่หน้า Home',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    _syncTrip(trip, state.now);
    final days = trip.days;
    _dayIndex = _dayIndex.clamp(0, days.length - 1);
    final day = days[_dayIndex];
    final activities = state.activitiesOn(trip.id, day);
    final dayTitle = 'Day ${_dayIndex + 1} (${enShortDate(day)})';

    return NavyPage(
      title: 'แผนการเดินทาง',
      onBack: widget.onBack,
      panelPadding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.destination,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 14,
                      color: AppColors.navy,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        thaiRange(trip.start, trip.end),
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _DayTabs(
            days: days,
            selected: _dayIndex,
            onSelect: (i) => setState(() {
              _dayIndex = i;
              _formFor = null;
            }),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 62,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (activities.isEmpty && _formFor != _newKey)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'ยังไม่มีสถานที่ในวันนี้',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        for (final (i, a) in activities.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _formFor == a.id
                                ? ActivityForm(
                                    title: 'แก้ไขข้อมูล $dayTitle',
                                    activity: a,
                                    tripId: trip.id,
                                    day: day,
                                    onDone: () =>
                                        setState(() => _formFor = null),
                                  )
                                : _ActivityCard(
                                    activity: a,
                                    color:
                                        AppColors.timeBadges[i %
                                            AppColors.timeBadges.length],
                                    onEdit: () =>
                                        setState(() => _formFor = a.id),
                                    onDelete: () => _delete(a),
                                    onPickImage: () => _pickImage(a),
                                  ),
                          ),
                        if (_formFor == _newKey)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ActivityForm(
                              title: 'เพิ่มสถานที่ $dayTitle',
                              tripId: trip.id,
                              day: day,
                              onDone: () => setState(() => _formFor = null),
                            ),
                          )
                        else
                          _AddPlaceButton(
                            onTap: () => setState(() => _formFor = _newKey),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 38,
                    child: Column(
                      children: [
                        WeatherCard(city: trip.city),
                        const SizedBox(height: 10),
                        BudgetCard(
                          spent: state.spentThb(trip),
                          budget: trip.budget,
                        ),
                        const SizedBox(height: 10),
                        RateCard(currency: trip.currency),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayTabs extends StatelessWidget {
  const _DayTabs({
    required this.days,
    required this.selected,
    required this.onSelect,
  });

  final List<DateTime> days;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      height: 66,
      child: LayoutBuilder(
        builder: (context, c) {
          final tabWidth = c.maxWidth / 3;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            itemBuilder: (_, i) {
              final active = i == selected;
              return InkWell(
                onTap: () => onSelect(i),
                child: SizedBox(
                  width: tabWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Day ${i + 1}',
                        style: TextStyle(
                          color: active ? Colors.white : Colors.white70,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        enShortDate(days[i]),
                        style: TextStyle(
                          color: active ? Colors.white70 : Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 3,
                        width: tabWidth * 0.62,
                        color: active ? AppColors.blue : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.color,
    required this.onEdit,
    required this.onDelete,
    required this.onPickImage,
  });

  final Activity activity;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final a = activity;
    return BadgeCard(
      padding: const EdgeInsets.fromLTRB(8, 6, 6, 8),
      badge: Pill(
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time, size: 11, color: Colors.white),
            const SizedBox(width: 3),
            Text(hhmm(a.minutes), style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -8,
            right: 0,
            child: EditDeleteActions(
              onEdit: onEdit,
              onDelete: onDelete,
              size: 15,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onPickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 64,
                    height: 44,
                    child: a.imagePath == null
                        ? const ColoredBox(
                            color: AppColors.placeholder,
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          )
                        : LocalImage(a.imagePath!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    Text(
                      a.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (a.note.isNotEmpty)
                      Text(
                        '•  ${a.note}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddPlaceButton extends StatelessWidget {
  const _AddPlaceButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.addPlaceBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.addPlaceBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: const SizedBox(
          height: 34,
          child: Center(
            child: Text(
              '+ เพิ่มสถานที่ในวันนี้',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline add/edit form for a place (ชื่อสถานที่, เวลา, บันทึกเพิ่มเติม).
class ActivityForm extends StatefulWidget {
  const ActivityForm({
    super.key,
    required this.title,
    required this.tripId,
    required this.day,
    required this.onDone,
    this.activity,
  });

  final String title;
  final String tripId;
  final DateTime day;
  final Activity? activity;
  final VoidCallback onDone;

  @override
  State<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.activity?.name);
  late final _note = TextEditingController(text: widget.activity?.note);
  late final _time = TextEditingController(
    text: widget.activity == null ? '' : hhmm(widget.activity!.minutes),
  );

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _time.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final current = parseTime(_time.text) ?? 9 * 60;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t != null) _time.text = hhmm(t.hour * 60 + t.minute);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await AppScope.read(context).saveActivity(
      id: widget.activity?.id,
      tripId: widget.tripId,
      date: widget.day,
      minutes: parseTime(_time.text)!,
      name: _name.text.trim(),
      note: _note.text.trim(),
    );
    widget.onDone();
  }

  InputDecoration _box(String hint) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: c),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 10, color: AppColors.hint),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      border: b(AppColors.addPlaceBorder),
      enabledBorder: b(AppColors.addPlaceBorder),
      focusedBorder: b(AppColors.blue),
      errorStyle: const TextStyle(fontSize: 9, height: 0.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    const fieldStyle = TextStyle(fontSize: 11);
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? 'จำเป็น' : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('ชื่อสถานที่', fontSize: 11),
                      const SizedBox(height: 3),
                      TextFormField(
                        controller: _name,
                        style: fieldStyle,
                        decoration: _box('วัดเซ็นโซจิ'),
                        validator: required,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('เวลา', fontSize: 11),
                      const SizedBox(height: 3),
                      TextFormField(
                        controller: _time,
                        style: fieldStyle,
                        readOnly: true,
                        onTap: _pickTime,
                        decoration: _box('09:00 น.'),
                        validator: (v) =>
                            parseTime(v ?? '') == null ? 'จำเป็น' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const FieldLabel('บันทึกเพิ่มเติม', required: false, fontSize: 11),
            const SizedBox(height: 3),
            TextFormField(
              controller: _note,
              style: fieldStyle,
              decoration: _box('ถ่ายรูปประตูคามินาริมง'),
            ),
            const SizedBox(height: 10),
            CancelSaveRow(
              onCancel: widget.onDone,
              onSave: _save,
              height: 26,
              radius: 6,
              fontSize: 10,
              gap: 14,
            ),
          ],
        ),
      ),
    );
  }
}
