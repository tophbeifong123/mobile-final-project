import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
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
        loading: () => const LoadingView(label: 'กำลังโหลดรายชื่อผู้สมัคร'),
        error: (error, _) => EmptyState(
          icon: Icons.people_outline,
          title: 'โหลดรายชื่อผู้สมัครไม่ได้',
          message: userVisibleError(error),
          action: AppPrimaryButton(
            onPressed: () =>
                ref.invalidate(companyJobApplicantsProvider(jobId)),
            child: const Text('ลองอีกครั้ง'),
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
                      icon: Icons.people_outline,
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
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 12),
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

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
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
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [applicant.university, applicant.major]
                                  .where((s) => s.isNotEmpty)
                                  .join(' • '),
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    StatusChip(label: _displayStatus(applicant.status)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
