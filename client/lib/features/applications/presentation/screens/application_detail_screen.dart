import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/info_chip.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../jobs/presentation/job_labels.dart';
import '../../domain/entities/job_application.dart';
import '../providers/applications_controller.dart';

class ApplicationDetailScreen extends ConsumerWidget {
  const ApplicationDetailScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationAsync = ref.watch(
      applicationDetailProvider(applicationId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดใบสมัคร')),
      body: SafeArea(
        child: applicationAsync.when(
          loading: () => const LoadingView(label: 'กำลังโหลดรายละเอียดใบสมัคร'),
          error: (error, _) => EmptyState(
            icon: LucideIcons.alertCircle,
            title: 'โหลดรายละเอียดใบสมัครไม่ได้',
            message: userVisibleError(error),
            action: AppButton(
              variant: AppButtonVariant.outline,
              size: AppButtonSize.sm,
              onPressed: () =>
                  ref.invalidate(applicationDetailProvider(applicationId)),
              text: 'ลองอีกครั้ง',
            ),
          ),
          data: (app) => RefreshIndicator(
            onRefresh: () =>
                ref.refresh(applicationDetailProvider(applicationId).future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(kPagePadding),
              children: [
                _JobSummaryCard(application: app),
                const Gap(16),
                _StatusTimelineCard(application: app),
                const Gap(16),
                _CoverLetterCard(coverLetter: app.coverLetter),
                const Gap(16),
                _ResumeCard(resumeObjectKey: app.resumeObjectKey),
                const Gap(16),
                Center(
                  child: Text(
                    'รหัสใบสมัคร: ${app.id}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JobSummaryCard extends StatelessWidget {
  const _JobSummaryCard({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CompanyMark(name: application.companyName),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(application.jobTitle, style: textTheme.titleMedium),
                    const Gap(2),
                    Text(application.companyName, style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const Gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(label: application.status.labelTh),
              if (application.province != null &&
                  application.province!.isNotEmpty)
                InfoChip(
                  label: application.province!,
                  icon: LucideIcons.mapPin,
                ),
              if (application.workMode != null &&
                  application.workMode!.isNotEmpty)
                InfoChip(label: _workModeText(application.workMode!)),
              if (application.category != null &&
                  application.category!.isNotEmpty)
                InfoChip(label: application.category!),
              if (application.hasAllowance != null)
                InfoChip(label: allowanceLabel(application.hasAllowance!)),
            ],
          ),
          if (application.jobId != null) ...[
            const Gap(16),
            OutlinedButton.icon(
              onPressed: () =>
                  context.push('/student/jobs/${application.jobId}'),
              icon: const Icon(LucideIcons.arrowUpRight, size: 16),
              label: const Text('ดูประกาศงาน'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(kMinTouchTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _workModeText(String mode) {
    switch (mode) {
      case 'on_site':
        return 'On-site';
      case 'hybrid':
        return 'Hybrid';
      case 'remote':
        return 'Remote';
      default:
        return mode;
    }
  }
}

class _StatusTimelineCard extends StatelessWidget {
  const _StatusTimelineCard({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    DateTime? eventDate(ApplicationStatus status) {
      for (final event in application.timeline) {
        if (event.toStatus == status) {
          return event.createdAt;
        }
      }
      return null;
    }

    final submittedDate =
        eventDate(ApplicationStatus.submitted) ?? application.createdAt;
    final reviewingDate = eventDate(ApplicationStatus.reviewing);
    final acceptedDate = eventDate(ApplicationStatus.accepted);
    final rejectedDate = eventDate(ApplicationStatus.rejected);

    final isReviewingOrBeyond =
        application.status == ApplicationStatus.reviewing ||
        application.status == ApplicationStatus.accepted ||
        application.status == ApplicationStatus.rejected;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('สถานะการสมัคร', style: textTheme.titleMedium),
          const Gap(4),
          Text(
            'ความคืบหน้าของใบสมัครนี้',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(16),
          _TimelineStepItem(
            title: 'ยื่นใบสมัครแล้ว',
            description: 'ส่งใบสมัครและข้อมูลไปยังบริษัทแล้ว',
            date: submittedDate,
            state: isReviewingOrBeyond
                ? _StepState.completed
                : _StepState.current,
            showLine: true,
          ),
          _TimelineStepItem(
            title: 'กำลังพิจารณา',
            description: isReviewingOrBeyond
                ? 'บริษัทกำลังตรวจประวัติและ Resume'
                : 'รอการตรวจสอบจากบริษัท',
            date: reviewingDate,
            state:
                (application.status == ApplicationStatus.accepted ||
                    application.status == ApplicationStatus.rejected)
                ? _StepState.completed
                : application.status == ApplicationStatus.reviewing
                ? _StepState.current
                : _StepState.upcoming,
            showLine: true,
          ),
          if (application.status == ApplicationStatus.accepted)
            _TimelineStepItem(
              title: 'ผ่านการคัดเลือก',
              description: 'ยินดีด้วย คุณผ่านการคัดเลือกสำหรับตำแหน่งนี้',
              date: acceptedDate,
              state: _StepState.accepted,
              showLine: false,
            )
          else if (application.status == ApplicationStatus.rejected)
            _TimelineStepItem(
              title: 'ไม่ผ่านการคัดเลือก',
              description: 'ขออภัย คุณไม่ผ่านการคัดเลือกสำหรับตำแหน่งนี้',
              date: rejectedDate,
              state: _StepState.rejected,
              showLine: false,
            )
          else
            const _TimelineStepItem(
              title: 'ผลการคัดเลือก',
              description: 'รอการตัดสินใจและประกาศผลจากบริษัท',
              date: null,
              state: _StepState.upcoming,
              showLine: false,
            ),
        ],
      ),
    );
  }
}

enum _StepState { completed, current, upcoming, accepted, rejected }

class _TimelineStepItem extends StatelessWidget {
  const _TimelineStepItem({
    required this.title,
    required this.description,
    required this.date,
    required this.state,
    required this.showLine,
  });

  final String title;
  final String description;
  final DateTime? date;
  final _StepState state;
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
                _buildIndicator(context),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      color:
                          (state == _StepState.completed ||
                              state == _StepState.current ||
                              state == _StepState.accepted ||
                              state == _StepState.rejected)
                          ? AppColors.primary
                          : AppColors.line,
                    ),
                  ),
              ],
            ),
          ),
          const Gap(12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _titleColor(context),
                          ),
                        ),
                      ),
                      if (date != null)
                        Text(
                          _formatDate(date!),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const Gap(2),
                  Text(
                    description,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
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

  Widget _buildIndicator(BuildContext context) {
    switch (state) {
      case _StepState.completed:
        return Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: const Icon(LucideIcons.check, size: 12, color: Colors.white),
        );
      case _StepState.accepted:
        return Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
          ),
          child: const Icon(LucideIcons.check, size: 12, color: Colors.white),
        );
      case _StepState.rejected:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.error,
          ),
          child: const Icon(LucideIcons.x, size: 12, color: Colors.white),
        );
      case _StepState.current:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.primary, width: 4),
          ),
        );
      case _StepState.upcoming:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.line, width: 2),
          ),
        );
    }
  }

  Color? _titleColor(BuildContext context) {
    switch (state) {
      case _StepState.accepted:
        return AppColors.success;
      case _StepState.rejected:
        return Theme.of(context).colorScheme.error;
      case _StepState.upcoming:
        return AppColors.textSecondary;
      default:
        return null;
    }
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    return '$day/$month/$year';
  }
}

class _CoverLetterCard extends StatelessWidget {
  const _CoverLetterCard({required this.coverLetter});

  final String coverLetter;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.fileText,
                size: 20,
                color: AppColors.primary,
              ),
              const Gap(8),
              Text('Cover Letter', style: textTheme.titleMedium),
            ],
          ),
          const Gap(12),
          Text(
            coverLetter.trim().isNotEmpty
                ? coverLetter.trim()
                : 'ไม่ได้ระบุ Cover Letter',
            style: textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({this.resumeObjectKey});

  final String? resumeObjectKey;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.fileText,
                size: 20,
                color: AppColors.primary,
              ),
              const Gap(8),
              Text('Resume ที่ใช้สมัคร', style: textTheme.titleMedium),
            ],
          ),
          const Gap(12),
          Text(
            resumeObjectKey != null
                ? 'สำเนา Resume ในระบบ ณ วันที่ยื่นใบสมัคร'
                : 'ยังไม่มี Resume ในใบสมัครนี้',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyMark extends StatelessWidget {
  const _CompanyMark({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty
        ? '?'
        : String.fromCharCode(name.trim().runes.first).toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Text(
            letter,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
