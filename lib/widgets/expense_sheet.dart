import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import 'ui.dart';

const categoryIcons = {
  ExpenseCategory.food: Icons.restaurant_outlined,
  ExpenseCategory.transport: Icons.train_outlined,
  ExpenseCategory.hotel: Icons.hotel_outlined,
  ExpenseCategory.shopping: Icons.shopping_bag_outlined,
  ExpenseCategory.activity: Icons.local_activity_outlined,
  ExpenseCategory.other: Icons.more_horiz,
};

const paymentIcons = {
  PaymentMethod.cash: Icons.payments_outlined,
  PaymentMethod.card: Icons.credit_card_outlined,
  PaymentMethod.transfer: Icons.account_balance_outlined,
  PaymentMethod.icCard: Icons.contactless_outlined,
};

/// Opens the add/edit expense sheet. [day] pre-selects the date for new items.
Future<void> showExpenseSheet(
  BuildContext context, {
  required Trip trip,
  Expense? expense,
  DateTime? day,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _ExpenseSheet(trip: trip, expense: expense, day: day),
  );
}

class _ExpenseSheet extends StatefulWidget {
  const _ExpenseSheet({required this.trip, this.expense, this.day});

  final Trip trip;
  final Expense? expense;
  final DateTime? day;

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.expense?.title);
  late final _amount = TextEditingController(
    text: widget.expense == null ? '' : money(widget.expense!.amount),
  );
  late ExpenseCategory _category =
      widget.expense?.category ?? ExpenseCategory.food;
  late PaymentMethod _payment = widget.expense?.payment ?? PaymentMethod.cash;
  late DateTime _date;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    final days = widget.trip.days;
    final now = DateTime.now();
    final preferred = widget.expense?.date ?? widget.day ?? dateOnly(now);
    _date = days.contains(dateOnly(preferred))
        ? dateOnly(preferred)
        : days.first;
    _minutes = widget.expense?.minutes ?? now.hour * 60 + now.minute;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  double? get _amountValue => double.tryParse(_amount.text.replaceAll(',', ''));

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t != null) setState(() => _minutes = t.hour * 60 + t.minute);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await AppScope.read(context).saveExpense(
      id: widget.expense?.id,
      tripId: widget.trip.id,
      date: _date,
      minutes: _minutes,
      title: _title.text.trim(),
      amount: _amountValue!,
      category: _category,
      payment: _payment,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final e = widget.expense!;
    if (await confirmDelete(context, e.title) && mounted) {
      await AppScope.read(context).deleteExpense(e.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cur = widget.trip.currency;
    final thb = (_amountValue ?? 0) * state.rateToThb(cur);

    Widget label(String t, {bool req = true}) => Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 12),
      child: FieldLabel(t, required: req),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.expense == null
                          ? 'เพิ่มรายการค่าใช้จ่าย'
                          : 'แก้ไขรายการค่าใช้จ่าย',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  if (widget.expense != null)
                    IconButton(
                      tooltip: 'ลบรายการ',
                      onPressed: _delete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.delete,
                      ),
                    ),
                ],
              ),
              label('รายการ'),
              TextFormField(
                controller: _title,
                decoration: pillInput('ค่าอาหารมื้อเที่ยง'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'กรุณากรอกชื่อรายการ'
                    : null,
              ),
              label('จำนวนเงิน ($cur)'),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: pillInput('3,500').copyWith(
                  suffixText: cur,
                  suffixStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                validator: (v) {
                  final n = _amountValue;
                  return (n == null || n <= 0) ? 'กรุณากรอกจำนวนเงิน' : null;
                },
              ),
              if (cur != 'THB')
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 6),
                  child: Text(
                    '≈ ${money(thb)} THB  (1 $cur = ${rate(state.rateToThb(cur))} THB)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        label('หมวดหมู่'),
                        PillDropdown<ExpenseCategory>(
                          value: _category,
                          height: 44,
                          radius: 22,
                          fontSize: 13,
                          items: [
                            for (final c in ExpenseCategory.values)
                              (c, c.label),
                          ],
                          onChanged: (v) => setState(() => _category = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        label('วิธีชำระ'),
                        PillDropdown<PaymentMethod>(
                          value: _payment,
                          height: 44,
                          radius: 22,
                          fontSize: 13,
                          items: [
                            for (final p in PaymentMethod.values) (p, p.label),
                          ],
                          onChanged: (v) => setState(() => _payment = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        label('วันที่'),
                        PillDropdown<DateTime>(
                          value: _date,
                          height: 44,
                          radius: 22,
                          fontSize: 13,
                          items: [
                            for (final (i, d) in widget.trip.days.indexed)
                              (d, 'Day ${i + 1} · ${thaiDate(d)}'),
                          ],
                          onChanged: (v) => setState(() => _date = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        label('เวลา'),
                        InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(22),
                          child: InputDecorator(
                            decoration: pillInput(''),
                            child: Text(
                              '${hhmm(_minutes)} น.',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CancelSaveRow(
                onCancel: () => Navigator.of(context).pop(),
                onSave: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
