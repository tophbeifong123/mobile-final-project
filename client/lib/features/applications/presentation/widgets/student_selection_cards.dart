import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../domain/entities/job_application.dart';
import '../../domain/selection_progress.dart';

class StudentSelectionCards extends StatelessWidget {
  const StudentSelectionCards({
    super.key,
    required this.application,
    required this.onOpenLink,
    required this.onCompleteExam,
    this.now,
    this.busy = false,
  });

  final JobApplication application;
  final void Function(String url) onOpenLink;
  final VoidCallback? onCompleteExam;
  final DateTime? now;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final examUrl = application.examUrl;
    final interviewUrl = application.interviewUrl;
    final hasExam = examUrl != null && examUrl.isNotEmpty;
    final onSite = application.interviewMode == 'on_site';
    final hasInterview =
        (interviewUrl != null && interviewUrl.isNotEmpty) ||
        application.interviewStartsAt != null;
    if (!hasExam && !hasInterview) return const SizedBox.shrink();

    final showInterview = hasInterview;

    final canOpenExam = examCanBeOpened(
      examUrl: examUrl,
      examDeadline: application.examDeadline,
      examCompletedAt: application.examCompletedAt,
      now: now,
    );
    final expired =
        hasExam &&
        application.examCompletedAt == null &&
        application.examDeadline != null &&
        (now ?? DateTime.now()).isAfter(application.examDeadline!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(20),
        const Text(
          'ขั้นตอนถัดไป',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: NeoColors.subtleInk,
          ),
        ),
        const Gap(8),
        if (showInterview)
          _StepCard(
            icon: onSite ? Icons.apartment_rounded : Icons.videocam_outlined,
            accent: NeoColors.softLilac,
            title: onSite ? 'นัดสัมภาษณ์ออนไซต์' : 'นัดสัมภาษณ์ออนไลน์',
            body: onSite
                ? 'สัมภาษณ์ที่สำนักงาน วันที่ ${application.interviewStartsAt == null ? '-' : formatSelectionWhen(application.interviewStartsAt!)}'
                : application.interviewStartsAt == null
                ? 'บริษัทส่งลิงก์นัดแล้ว'
                : 'นัดวันที่ ${formatSelectionWhen(application.interviewStartsAt!)}',
            actions: [
              if (!onSite &&
                  interviewUrl != null &&
                  interviewUrl.isNotEmpty &&
                  application.status != ApplicationStatus.rejected)
                NeoButton(
                  text: 'เปิดลิงก์นัด',
                  isFullWidth: true,
                  onPressed: busy ? null : () => onOpenLink(interviewUrl),
                ),
            ],
          )
        else
          _StepCard(
            icon: Icons.quiz_outlined,
            accent: NeoColors.skyBlue,
            title: 'ข้อสอบ',
            body: application.examPassedAt != null
                ? 'ข้อสอบผ่านแล้ว รอบริษัทนัดสัมภาษณ์'
                : application.examCompletedAt != null
                ? 'ทำข้อสอบแล้วเมื่อ ${formatSelectionWhen(application.examCompletedAt!)} รอผลตรวจจากบริษัท'
                : expired
                ? 'หมดเวลาทำข้อสอบแล้ว'
                : 'ทำให้เสร็จภายใน ${application.examDeadline == null ? '-' : formatSelectionWhen(application.examDeadline!)}',
            actions: [
              if (canOpenExam)
                NeoButton(
                  text: 'เปิดข้อสอบ',
                  isFullWidth: true,
                  variant: NeoButtonVariant.outline,
                  onPressed: busy ? null : () => onOpenLink(examUrl!),
                ),
              if (canOpenExam)
                NeoButton(
                  text: 'ทำข้อสอบแล้ว',
                  isFullWidth: true,
                  onPressed: busy ? null : onCompleteExam,
                ),
            ],
          ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
    required this.actions,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: NeoColors.pureWhite,
      borderColor: NeoColors.inkSolid,
      borderWidth: 2.5,
      borderRadius: BorderRadius.circular(16),
      shadows: NeoShadows.elevation2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                ),
                child: Icon(icon, size: 18, color: NeoColors.inkSolid),
              ),
              const Gap(10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: NeoColors.inkSolid,
                  ),
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: NeoColors.inkSolid,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const Gap(12),
            for (var index = 0; index < actions.length; index++) ...[
              if (index > 0) const Gap(8),
              Align(
                alignment: Alignment.center,
                child: SizedBox(width: double.infinity, child: actions[index]),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
