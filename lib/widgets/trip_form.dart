import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../models/models.dart';
import '../services/remote.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import 'ui.dart';

/// Create/edit trip form. Used full-screen for new trips and expanded
/// in place inside a trip card for edits.
class TripForm extends StatefulWidget {
  const TripForm({super.key, this.trip, required this.onDone, this.compact = false});

  final Trip? trip;
  final VoidCallback onDone;

  /// Tighter spacing for the in-card editor.
  final bool compact;

  @override
  State<TripForm> createState() => _TripFormState();
}

class _TripFormState extends State<TripForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.trip?.name);
  late final _dest = TextEditingController(text: widget.trip?.destination);
  late final _budget = TextEditingController(
      text: widget.trip == null ? '' : money(widget.trip!.budget));
  late DateTime? _start = widget.trip?.start;
  late DateTime? _end = widget.trip?.end;
  late String _currency = widget.trip?.currency ?? 'JPY';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _dest.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _start : _end) ?? _start ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end != null && _end!.isBefore(picked)) _end = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await AppScope.read(context).saveTrip(
      id: widget.trip?.id,
      name: _name.text.trim(),
      destination: _dest.text.trim(),
      start: _start!,
      end: _end!,
      budget: double.parse(_budget.text.replaceAll(',', '')),
      currency: _currency,
    );
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final gap = widget.compact ? 8.0 : 14.0;
    final labelSize = widget.compact ? 11.0 : 13.0;
    final inputPad = widget.compact
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
        : null;

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: FieldLabel(t, fontSize: labelSize),
        );

    String? requiredText(String? v) =>
        (v == null || v.trim().isEmpty) ? 'กรุณากรอกข้อมูล' : null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          label('ชื่อทริป'),
          TextFormField(
            controller: _name,
            decoration: pillInput('ทริปพักผ่อน', padding: inputPad),
            validator: requiredText,
          ),
          SizedBox(height: gap),
          label('เมือง/ประเทศ'),
          TextFormField(
            controller: _dest,
            decoration: pillInput('โตเกียว, ญี่ปุ่น', padding: inputPad),
            validator: requiredText,
          ),
          SizedBox(height: gap),
          label('วันที่เดินทาง'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DateField(
                  value: _start,
                  hint: '01/01/2570',
                  padding: inputPad,
                  onTap: () => _pickDate(isStart: true),
                  validator: () => _start == null ? 'เลือกวันเริ่ม' : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _DateField(
                  value: _end,
                  hint: '05/01/2570',
                  padding: inputPad,
                  onTap: () => _pickDate(isStart: false),
                  validator: () {
                    if (_end == null) return 'เลือกวันสิ้นสุด';
                    if (_start != null && _end!.isBefore(_start!)) {
                      return 'ต้องไม่ก่อนวันเริ่ม';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: gap),
          label('งบประมาณรวม (บาท)'),
          TextFormField(
            controller: _budget,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
            decoration: pillInput('30,000', padding: inputPad),
            validator: (v) {
              final n = double.tryParse((v ?? '').replaceAll(',', ''));
              return (n == null || n <= 0) ? 'กรุณากรอกงบประมาณ' : null;
            },
          ),
          SizedBox(height: gap),
          label('สกุลเงิน'),
          PillDropdown<String>(
            value: _currency,
            height: widget.compact ? 38 : 44,
            radius: 22,
            fontSize: 13,
            borderColor: AppColors.inputBorder,
            items: [for (final c in ExchangeService.currencies) (c, c)],
            onChanged: (v) => setState(() => _currency = v),
          ),
          SizedBox(height: gap + 10),
          CancelSaveRow(
            onCancel: widget.onDone,
            onSave: _saving ? null : _save,
            height: widget.compact ? 34 : 40,
          ),
        ],
      ),
    );
  }
}

class _DateField extends FormField<DateTime> {
  _DateField({
    required DateTime? value,
    required String hint,
    required VoidCallback onTap,
    required String? Function() validator,
    EdgeInsets? padding,
  }) : super(
          validator: (_) => validator(),
          builder: (state) => GestureDetector(
            onTap: onTap,
            child: InputDecorator(
              decoration: pillInput(hint, padding: padding).copyWith(
                errorText: state.errorText,
                hintText: value == null ? hint : null,
              ),
              isEmpty: value == null,
              child: Text(value == null ? '' : thaiNumericDate(value),
                  style: const TextStyle(fontSize: 13)),
            ),
          ),
        );
}

/// Full-screen "เพิ่มทริปใหม่" page.
class TripFormScreen extends StatelessWidget {
  const TripFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: NavyPage(
        title: 'เพิ่มทริปใหม่',
        showBack: true,
        panelPadding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
          child: TripForm(onDone: () => Navigator.of(context).pop()),
        ),
      ),
    );
  }
}
