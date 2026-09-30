import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';

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

/// Opens "บันทึกรายการค่าใช้จ่าย". [day] pre-selects the date for new items.
Future<void> openExpenseForm(
  BuildContext context, {
  required Trip trip,
  Expense? expense,
  DateTime? day,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ExpenseFormScreen(trip: trip, expense: expense, day: day),
    ),
  );
}

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({
    super.key,
    required this.trip,
    this.expense,
    this.day,
  });

  final Trip trip;
  final Expense? expense;
  final DateTime? day;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  static const _maxDetail = 100;

  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.expense == null ? '' : money1(widget.expense!.amount),
  );
  late final _detail = TextEditingController(text: widget.expense?.title);
  late String _currency = widget.trip.currency;
  late ExpenseCategory _category =
      widget.expense?.category ?? ExpenseCategory.food;
  late PaymentMethod _payment = widget.expense?.payment ?? PaymentMethod.cash;
  late DateTime _date;
  late final int _minutes;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.read(context).refreshRate(widget.trip.currency);
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _detail.dispose();
    super.dispose();
  }

  double? get _amountValue => double.tryParse(_amount.text.replaceAll(',', ''));

  /// The entered amount expressed in the trip's currency, which is how
  /// expenses are stored.
  double _inTripCurrency(AppState state, double value) =>
      value *
      state.rateToThb(_currency) /
      state.rateToThb(widget.trip.currency);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = AppScope.read(context);
    final detail = _detail.text.trim();
    await state.saveExpense(
      id: widget.expense?.id,
      tripId: widget.trip.id,
      date: _date,
      minutes: _minutes,
      title: detail.isEmpty ? _category.label : detail,
      amount: _inTripCurrency(state, _amountValue!),
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
    final tripCur = widget.trip.currency;
    final currencies = {tripCur, 'THB'}.toList();
    final value = _amountValue ?? 0;

    // Show the other side of the conversion: THB for foreign input, the
    // trip's currency when the amount was typed in THB.
    final String? converted = tripCur == 'THB'
        ? null
        : _currency == 'THB'
        ? '${money1(_inTripCurrency(state, value))} $tripCur'
        : '${money1(value * state.rateToThb(_currency))} THB';

    Widget label(String t, {bool req = true}) => Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6, top: 14),
      child: FieldLabel(t, required: req, fontSize: 12),
    );

    Widget dropdown<T>(
      T value,
      List<(T, String)> items,
      ValueChanged<T> onChanged,
    ) => PillDropdown<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      height: 42,
      radius: 12,
      fontSize: 13,
      borderColor: AppColors.blue,
    );

    // Cash and card per the design; keep any other method already saved.
    final payments = {
      PaymentMethod.cash,
      PaymentMethod.card,
      _payment,
    }.toList();

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SingleChildScrollView(
        child: NavyPage(
          title: 'บันทึกรายการค่าใช้จ่าย',
          showBack: true,
          expandPanel: false,
          panelPadding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          label('จำนวนเงิน'),
                          TextFormField(
                            controller: _amount,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d,.]'),
                              ),
                            ],
                            onChanged: (_) => setState(() {}),
                            decoration: pillInput('', radius: 12),
                            validator: (_) {
                              final n = _amountValue;
                              return (n == null || n <= 0)
                                  ? 'กรุณากรอกจำนวนเงิน'
                                  : null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          label('สกุลเงิน'),
                          dropdown<String>(_currency, [
                            for (final c in currencies) (c, c),
                          ], (v) => setState(() => _currency = v)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (converted != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.addPlaceBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ระบบคำนวณให้อัตโนมัติ (≈ $converted)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          label('หมวดหมู่'),
                          dropdown<ExpenseCategory>(_category, [
                            for (final c in ExpenseCategory.values)
                              (c, c.label),
                          ], (v) => setState(() => _category = v)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          label('วิธีชำระเงิน'),
                          RadioGroup<PaymentMethod>(
                            groupValue: _payment,
                            onChanged: (v) {
                              if (v != null) setState(() => _payment = v);
                            },
                            child: Wrap(
                              spacing: 8,
                              children: [
                                for (final p in payments)
                                  _RadioOption(value: p, label: p.label),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                label('ผูกวันในทริป'),
                dropdown<DateTime>(_date, [
                  for (final (i, d) in widget.trip.days.indexed)
                    (d, 'Day ${i + 1} (${thaiDate(d)})'),
                ], (v) => setState(() => _date = v)),
                label('รายละเอียด', req: false),
                Stack(
                  children: [
                    TextFormField(
                      controller: _detail,
                      minLines: 4,
                      maxLines: 4,
                      maxLength: _maxDetail,
                      onChanged: (_) => setState(() {}),
                      decoration: pillInput(
                        '',
                        radius: 12,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 26),
                      ).copyWith(counterText: ''),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 8,
                      child: Text(
                        '${_detail.text.characters.length}/$_maxDetail',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CancelSaveRow(
                  onCancel: () => Navigator.of(context).pop(),
                  onDelete: widget.expense == null ? null : _delete,
                  onSave: _save,
                  height: 36,
                  radius: 18,
                  gap: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({required this.value, required this.label});

  final PaymentMethod value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final group = RadioGroup.maybeOf<PaymentMethod>(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => group?.onChanged(value),
      child: SizedBox(
        height: 42,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<PaymentMethod>(
              value: value,
              fillColor: const WidgetStatePropertyAll(AppColors.text),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
