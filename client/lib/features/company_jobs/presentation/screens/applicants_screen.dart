import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/neo_button.dart';
import '../widgets/company_applicant_widgets.dart';
import '../../../../core/widgets/company_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/company_job.dart';
import '../../../applications/domain/selection_progress.dart';
import '../providers/company_jobs_controller.dart';

class ApplicantsScreen extends ConsumerWidget {
  const ApplicantsScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicantsAsync = ref.watch(companyJobApplicantsProvider(jobId));

    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      appBar: const CompanyTopBar(
        title: 'รายชื่อผู้สมัคร',
        showBack: true,
        backLocation: '/company/jobs',
      ),
      body: applicantsAsync.when(
        skipLoadingOnReload: true,
        loading: () => Skeletonizer(
          enabled: true,
          child: ListView.separated(
            padding: const EdgeInsets.all(kPagePadding),
            itemCount: 4,
            separatorBuilder: (context, index) => const Gap(12),
            itemBuilder: (context, index) => const CompanyApplicantCard(
              child: Row(
                children: [
                  CircleAvatar(radius: 22),
                  Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ชื่อ นามสกุล นักศึกษาตัวอย่าง'),
                        Gap(4),
                        Text('มหาวิทยาลัยตัวอย่าง • สาขาวิชา'),
                        Gap(8),
                        Text('กำลังพิจารณา'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        error: (error, _) => EmptyState(
          icon: LucideIcons.users,
          title: 'โหลดรายชื่อผู้สมัครไม่ได้',
          message: userVisibleError(error),
          action: NeoButton(
            variant: NeoButtonVariant.outline,
            onPressed: () =>
                ref.invalidate(companyJobApplicantsProvider(jobId)),
            text: 'ลองอีกครั้ง',
          ),
        ),
        data: (applicants) {
          if (applicants.isEmpty) {
            return RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(companyJobApplicantsProvider(jobId).future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: const EmptyState(
                      icon: LucideIcons.users,
                      title: 'ยังไม่มีผู้สมัคร',
                      message: 'ยังไม่มีนักศึกษาสมัครในตำแหน่งงานนี้',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(companyJobApplicantsProvider(jobId).future),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(kPagePadding),
              itemCount: applicants.length,
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                final applicant = applicants[index];
                return _ApplicantCard(
                  applicant: applicant,
                  onTap: () => context.push(
                    '/company/jobs/$jobId/applicants/${applicant.applicationId}',
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({required this.applicant, required this.onTap});

  final Applicant applicant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    final progress = selectionProgressLabel(
      examUrl: applicant.examUrl,
      examDeadline: applicant.examDeadline,
      examCompletedAt: applicant.examCompletedAt,
      examPassedAt: applicant.examPassedAt,
      interviewUrl: applicant.interviewUrl,
      interviewStartsAt: applicant.interviewStartsAt,
    );

    return CompanyApplicantCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: NeoColors.skyBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeoColors.inkSolid, width: 1.5),
            ),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                LucideIcons.user,
                color: NeoColors.inkSolid,
                size: 22,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  applicant.fullName.isEmpty
                      ? 'ไม่ระบุชื่อ'
                      : applicant.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (applicant.university.isNotEmpty ||
                    applicant.major.isNotEmpty) ...[
                  const Gap(4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.graduationCap,
                        size: 14,
                        color: colors.mutedForeground,
                      ),
                      const Gap(4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final value in [
                              applicant.university,
                              applicant.major,
                            ])
                              if (value.trim().isNotEmpty)
                                Text(
                                  value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.mutedForeground,
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const Gap(10),
                CompanyApplicantStatusChip(status: applicant.status),
                if (progress != null) ...[
                  const Gap(6),
                  Text(
                    progress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Gap(8),
          Icon(
            LucideIcons.chevronRight,
            color: colors.mutedForeground.withValues(alpha: 0.6),
            size: 20,
          ),
        ],
      ),
    );
  }
}
