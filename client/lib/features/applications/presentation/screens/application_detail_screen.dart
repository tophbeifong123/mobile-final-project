import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

class ApplicationDetailScreen extends StatelessWidget {
  const ApplicationDetailScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดใบสมัคร')),
      body: ListView(
        padding: const EdgeInsets.all(kPagePadding),
        children: [
          Text(
            'สถานะจะแสดงเมื่อมีใบสมัครนี้',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: _StatusTimeline(),
            ),
          ),
          const SizedBox(height: 12),
          const _InfoCard(title: 'ข้อมูลงาน', body: 'ยังไม่มีข้อมูลงาน'),
          const SizedBox(height: 12),
          const _InfoCard(title: 'Cover Letter', body: 'ยังไม่มี Cover Letter'),
          const SizedBox(height: 12),
          const _InfoCard(title: 'Resume', body: 'ยังไม่มี Resume ที่ใช้สมัคร'),
          const SizedBox(height: 12),
          Text(
            'รหัสใบสมัคร $applicationId',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline();

  static const _steps = [
    ('Submitted', 'ส่งใบสมัครแล้ว'),
    ('Reviewing', 'กำลังพิจารณา'),
    ('Accepted', 'ผ่านการคัดเลือก'),
    ('Rejected', 'ไม่ผ่าน'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Timeline', style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Submitted แล้ว Reviewing จากนั้นเป็น Accepted หรือ Rejected',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < _steps.length; index++)
          _TimelineStep(
            title: _steps[index].$2,
            label: _steps[index].$1,
            showLine: index < _steps.length - 1,
          ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.label,
    required this.showLine,
  });

  final String title;
  final String label;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
                if (showLine)
                  Expanded(child: Container(width: 2, color: AppColors.line)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleMedium),
                  Text(label, style: textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
