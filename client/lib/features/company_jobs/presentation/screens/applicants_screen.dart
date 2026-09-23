import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/company_job.dart';
import '../providers/company_jobs_controller.dart';

class ApplicantsScreen extends ConsumerWidget {
  const ApplicantsScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicantsAsync = ref.watch(companyJobApplicantsProvider(jobId));

    return Scaffold(
      appBar: AppBar(title: const Text('รายชื่อผู้สมัคร')),
      body: applicantsAsync.when(
        skipLoadingOnReload: true,
        loading: () => Skeletonizer(
          enabled: true,
          child: ListView.separated(
            padding: const EdgeInsets.all(kPagePadding),
            itemCount: 4,
            separatorBuilder: (context, index) => const Gap(12),
            itemBuilder: (context, index) => const AppCard(
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
          action: AppButton(
            variant: AppButtonVariant.outline,
            size: AppButtonSize.sm,
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
  const _ApplicantCard({
    required this.applicant,
    required this.onTap,
  });

  final Applicant applicant;
  final VoidCallback onTap;

  String _displayStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'submitted':
        return 'ยื่นใบสมัครแล้ว';
      case 'reviewing':
        return 'กำลังพิจารณา';
      case 'accepted':
        return 'ผ่านการคัดเลือก';
      case 'rejected':
        return 'ไม่ผ่านการคัดเลือก';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                LucideIcons.user,
                color: AppColors.primary,
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
                        child: Text(
                          [applicant.university, applicant.major]
                              .where((s) => s.isNotEmpty)
                              .join(' • '),
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.mutedForeground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const Gap(10),
                StatusChip(label: _displayStatus(applicant.status)),
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
