import 'package:flutter/material.dart';

import '../app/app_info.dart';
import '../app/theme.dart';
import '../widgets/ui.dart';

/// "JORNY OG" page: course details, team members and external APIs.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NavyPage(
        title: AppInfo.appName,
        showBack: true,
        showProfile: false,
        expandPanel: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Label('รายวิชา'),
            _InfoCard(rows: const [
              (null, AppInfo.courseName),
              ('รหัสวิชา:', AppInfo.courseCode),
              ('หมู่เรียน:', AppInfo.section),
            ]),
            const SizedBox(height: 14),
            const _Label('สมาชิก'),
            for (final (i, m) in AppInfo.members.indexed) ...[
              _InfoCard(rows: [
                ('สมาชิกคนที่ ${i + 1}:', m.name),
                ('รหัสนิสิต:', m.studentId),
                ('เลขที่:', m.number),
              ]),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 8),
            const _Label('External APIs'),
            _InfoCard(labelWidth: 140, rows: [
              for (final api in AppInfo.apis) ('${api.name}:', api.use),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 4),
        child: Text(text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows, this.labelWidth = 112});

  final List<(String?, String)> rows;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: label == null
                  ? Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: labelWidth,
                          child: Text(label,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ),
                        Expanded(
                          child: Text(value,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
