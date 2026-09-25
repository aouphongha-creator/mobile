import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../screens/info_screen.dart';

/// Navy page with centred title, optional back arrow, profile icon and a
/// light-blue rounded panel beneath — the frame shared by every screen.
class NavyPage extends StatelessWidget {
  const NavyPage({
    super.key,
    required this.title,
    required this.child,
    this.showBack = false,
    this.onBack,
    this.showProfile = true,
    this.expandPanel = true,
    this.panelPadding = const EdgeInsets.fromLTRB(12, 14, 12, 12),
  });

  final String title;
  final Widget child;
  final bool showBack;

  /// Custom back action (e.g. switch tab); defaults to popping the route.
  final VoidCallback? onBack;
  final bool showProfile;
  final bool expandPanel;
  final EdgeInsets panelPadding;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      width: double.infinity,
      padding: panelPadding,
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    return Material(
      color: AppColors.navy,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                  if (showBack || onBack != null)
                    Positioned(
                      left: 4,
                      child: IconButton(
                        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                      ),
                    ),
                  if (showProfile)
                    Positioned(
                      right: 8,
                      child: IconButton(
                        tooltip: 'ข้อมูลผู้จัดทำ',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const InfoScreen()),
                        ),
                        icon: const Icon(Icons.account_circle_outlined,
                            color: Colors.white, size: 32),
                      ),
                    ),
                ],
              ),
            ),
            if (expandPanel)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: panel,
                ),
              )
            else
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: panel),
          ],
        ),
      ),
    );
  }
}

/// "☰ รายการทั้งหมด" style heading inside a panel.
class PanelHeading extends StatelessWidget {
  const PanelHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.format_list_bulleted_rounded, color: AppColors.navy, size: 22),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                color: AppColors.navy, fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// White card with blue outline and an optional pill badge that overlaps
/// its top-left corner (trip status, activity time).
class BadgeCard extends StatelessWidget {
  const BadgeCard({
    super.key,
    required this.child,
    this.badge,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 10, 10),
    this.borderColor = AppColors.cardBorder,
  });

  final Widget child;
  final Widget? badge;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color borderColor;

  static const badgeOverlap = 10.0;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: badge == null ? padding : padding.copyWith(top: padding.top + 10),
          child: child,
        ),
      ),
    );
    if (badge == null) return card;
    return Padding(
      padding: const EdgeInsets.only(top: badgeOverlap),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(top: -badgeOverlap, left: 0, child: badge!),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
  });

  final Color color;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
        child: child,
      ),
    );
  }
}

/// Green pencil + red bin shown at the top-right of cards.
class EditDeleteActions extends StatelessWidget {
  const EditDeleteActions({super.key, this.onEdit, this.onDelete, this.size = 18});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          _SmallIcon(icon: Icons.edit, color: AppColors.edit, size: size, onTap: onEdit!),
        if (onEdit != null && onDelete != null) SizedBox(width: size * 0.4),
        if (onDelete != null)
          _SmallIcon(
              icon: Icons.delete_outline_rounded,
              color: AppColors.delete,
              size: size,
              onTap: onDelete!),
      ],
    );
  }
}

class _SmallIcon extends StatelessWidget {
  const _SmallIcon(
      {required this.icon, required this.color, required this.size, required this.onTap});

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: size,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}

/// Round blue "+" button with the double ring from the design.
class AddFab extends StatelessWidget {
  const AddFab({super.key, required this.onTap, this.size = 48});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.blue, width: 1.5),
      ),
      child: Material(
        color: AppColors.blue,
        shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(Icons.add, color: Colors.white, size: size * 0.6),
          ),
        ),
      ),
    );
  }
}

/// Small blue "+" dot used beside date groups.
class AddDot extends StatelessWidget {
  const AddDot({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 16,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFB0CEF4), width: 2),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 14),
      ),
    );
  }
}

/// Cancel (pink) / Save (green) button pair.
class CancelSaveRow extends StatelessWidget {
  const CancelSaveRow({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.height = 40,
    this.radius = 20,
    this.fontSize = 13,
    this.gap = 16,
  });

  final VoidCallback onCancel;
  final VoidCallback? onSave;
  final double height;
  final double radius;
  final double fontSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToneButton(
            label: 'ยกเลิก',
            bg: AppColors.cancelBg,
            border: AppColors.cancelBorder,
            onTap: onCancel,
            height: height,
            radius: radius,
            fontSize: fontSize,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _ToneButton(
            label: 'บันทึก',
            bg: AppColors.saveBg,
            border: AppColors.saveBorder,
            onTap: onSave,
            height: height,
            radius: radius,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}

class _ToneButton extends StatelessWidget {
  const _ToneButton({
    required this.label,
    required this.bg,
    required this.border,
    required this.onTap,
    required this.height,
    required this.radius,
    required this.fontSize,
  });

  final String label;
  final Color bg;
  final Color border;
  final VoidCallback? onTap;
  final double height;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: fontSize, fontWeight: FontWeight.w500, color: AppColors.text)),
          ),
        ),
      ),
    );
  }
}

/// Label with a red asterisk, e.g. "ชื่อทริป *".
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = true, this.fontSize = 13});

  final String text;
  final bool required;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: text),
        if (required)
          const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFE53935))),
      ]),
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: AppColors.text),
    );
  }
}

InputDecoration pillInput(String hint, {double radius = 22, EdgeInsets? padding}) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: c, width: 1.2),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.hint, fontSize: 13),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: border(AppColors.inputBorder),
    enabledBorder: border(AppColors.inputBorder),
    focusedBorder: border(AppColors.blue),
    errorBorder: border(const Color(0xFFE53935)),
    focusedErrorBorder: border(const Color(0xFFE53935)),
    errorStyle: const TextStyle(fontSize: 11),
  );
}

/// Compact white dropdown with rounded outline.
class PillDropdown<T> extends StatelessWidget {
  const PillDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.radius = 20,
    this.fontSize = 12,
    this.height = 34,
    this.borderColor = const Color(0xFF9E9E9E),
  });

  final Color borderColor;

  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;
  final double radius;
  final double fontSize;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.text),
          style: TextStyle(
              fontSize: fontSize,
              color: AppColors.text,
              fontFamily: AppTheme.fontFamily,
              fontFamilyFallback: AppTheme.fontFallback),
          borderRadius: BorderRadius.circular(12),
          items: [
            for (final (v, label) in items)
              DropdownMenuItem(
                value: v,
                child: Text(label, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

Future<bool> confirmDelete(BuildContext context, String what) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('ยืนยันการลบ'),
      content: Text('ต้องการลบ "$what" ใช่หรือไม่?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('ลบ', style: TextStyle(color: AppColors.delete)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
