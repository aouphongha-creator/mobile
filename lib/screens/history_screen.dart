import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/expense_sheet.dart';
import '../widgets/ui.dart';

/// "ประวัติค่าใช้จ่าย" — expenses of the selected trip grouped by day.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  ExpenseCategory? _category;
  DateTime? _day;
  String? _tripId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final trip = state.selectedTrip;

    if (trip == null) {
      return const NavyPage(
        title: 'ประวัติค่าใช้จ่าย',
        child: Center(
          child: Text(
            'ยังไม่มีทริป',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    // Reset filters when switching trips.
    if (_tripId != trip.id) {
      _tripId = trip.id;
      _category = null;
      _day = null;
    }

    final expenses = state
        .expensesOf(trip.id)
        .where((e) => _category == null || e.category == _category)
        .toList();
    final days = _day != null ? [_day!] : trip.days;
    final rateThb = state.rateToThb(trip.currency);

    // With a category filter only show days that have matches.
    final groups = [
      for (final d in days)
        (day: d, items: expenses.where((e) => dateOnly(e.date) == d).toList()),
    ].where((g) => _category == null || g.items.isNotEmpty).toList();

    return NavyPage(
      title: 'ประวัติค่าใช้จ่าย',
      panelPadding: EdgeInsets.zero,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 16),
        children: [
          Row(
            children: [
              const PanelHeading('ทริปปัจจุบัน'),
              const SizedBox(width: 12),
              Expanded(
                child: PillDropdown<String>(
                  value: trip.id,
                  items: [for (final t in state.trips) (t.id, t.name)],
                  onChanged: (id) => state.selectTrip(id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.saveBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.budgetBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined, size: 18),
                const SizedBox(width: 6),
                const Text('ยอดใช้จ่ายรวม:', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${money(state.spentThb(trip))} / ${money(trip.budget)} บาท',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.filter_list_rounded, size: 16),
              SizedBox(width: 6),
              Text('กรองตามหมวด', style: TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 7,
                child: PillDropdown<ExpenseCategory?>(
                  value: _category,
                  radius: 10,
                  height: 28,
                  fontSize: 11,
                  items: [
                    (null, 'หมวดหมู่ทั้งหมด'),
                    for (final c in ExpenseCategory.values) (c, c.label),
                  ],
                  onChanged: (v) => setState(() => _category = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: PillDropdown<DateTime?>(
                  value: _day,
                  radius: 10,
                  height: 28,
                  fontSize: 11,
                  items: [
                    (null, 'ทุกวัน'),
                    for (final (i, d) in trip.days.indexed) (d, 'Day ${i + 1}'),
                  ],
                  onChanged: (v) => setState(() => _day = v),
                ),
              ),
            ],
          ),
          if (groups.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'ไม่พบรายการค่าใช้จ่าย',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          for (final (i, g) in groups.indexed) ...[
            if (i > 0)
              const Divider(
                height: 20,
                thickness: 1.5,
                color: AppColors.cardBorder,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Pill(
                  color: AppColors.dateBadge,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 12,
                        color: AppColors.text,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'วันที่ ${thaiDate(g.day)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AddDot(
                  onTap: () =>
                      showExpenseSheet(context, trip: trip, day: g.day),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (g.items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  'ยังไม่มีรายการ',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            for (final e in g.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ExpenseCard(
                  expense: e,
                  currency: trip.currency,
                  thb: e.amount * rateThb,
                  onEdit: () =>
                      showExpenseSheet(context, trip: trip, expense: e),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.currency,
    required this.thb,
    required this.onEdit,
  });

  final Expense expense;
  final String currency;
  final double thb;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final e = expense;
    const meta = TextStyle(fontSize: 10, color: AppColors.textMuted);

    Widget chip(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.text),
          const SizedBox(width: 3),
          Text(text, style: meta),
        ],
      ),
    );

    return BadgeCard(
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  e.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              EditDeleteActions(onEdit: onEdit, size: 15),
            ],
          ),
          const SizedBox(height: 2),
          Wrap(
            children: [
              chip(categoryIcons[e.category]!, e.category.label),
              chip(paymentIcons[e.payment]!, e.payment.label),
              chip(Icons.access_time, '${hhmm(e.minutes)} น.'),
            ],
          ),
          const SizedBox(height: 3),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${money(e.amount)} $currency',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (currency != 'THB')
                  TextSpan(
                    text: '   (≈ ${money(thb)} THB)',
                    style: const TextStyle(fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
