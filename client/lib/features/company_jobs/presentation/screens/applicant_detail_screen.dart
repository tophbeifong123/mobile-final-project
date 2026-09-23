import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gap/gap.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/company_job.dart';
import '../providers/company_jobs_controller.dart';

class ApplicantDetailScreen extends ConsumerStatefulWidget {
  const ApplicantDetailScreen({
    super.key,
    required this.jobId,
    required this.applicationId,
  });

  final String jobId;
  final String applicationId;

  @override
  ConsumerState<ApplicantDetailScreen> createState() =>
      _ApplicantDetailScreenState();
}

class _ApplicantDetailScreenState extends ConsumerState<ApplicantDetailScreen> {
  bool _isUpdating = false;

  Future<void> _updateStatusToReviewing(Applicant applicant) async {
    setState(() => _isUpdating = true);
    try {
      await ref
          .read(companyJobsControllerProvider.notifier)
          .updateApplicantStatus(
            jobId: widget.jobId,
            applicationId: widget.applicationId,
            status: 'reviewing',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เปลี่ยนสถานะเป็น Reviewing แล้ว'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userVisibleError(error)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _confirmDecision({
    required String targetStatus,
    required String applicantName,
  }) async {
    final isAccept = targetStatus == 'accepted';
    final title = isAccept
        ? 'ยืนยันการรับเข้าฝึกงาน'
        : 'ยืนยันการปฏิเสธใบสมัคร';
    final content = isAccept
        ? 'คุณต้องการตอบรับคุณ $applicantName เข้าฝึกงานใช่หรือไม่? เมื่อตัดสินแล้วจะไม่สามารถเปลี่ยนสถานะได้อีก'
        : 'คุณต้องการปฏิเสธใบสมัครของคุณ $applicantName ใช่หรือไม่? เมื่อตัดสินแล้วจะไม่สามารถเปลี่ยนสถานะได้อีก';
    final confirmText = isAccept ? 'ตอบรับ (Accept)' : 'ปฏิเสธ (Reject)';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: isAccept
                ? FilledButton.styleFrom(backgroundColor: AppColors.success)
                : FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      await ref
          .read(companyJobsControllerProvider.notifier)
          .updateApplicantStatus(
            jobId: widget.jobId,
            applicationId: widget.applicationId,
            status: targetStatus,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAccept
                ? 'ตอบรับผู้สมัคร (Accepted) สำเร็จแล้ว'
                : 'ปฏิเสธผู้สมัคร (Rejected) สำเร็จแล้ว',
          ),
          backgroundColor: isAccept ? AppColors.success : AppColors.primary,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userVisibleError(error)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicantAsync = ref.watch(
      companyApplicantDetailProvider((
        jobId: widget.jobId,
        applicationId: widget.applicationId,
      )),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดผู้สมัคร')),
      body: applicantAsync.when(
        loading: () => const LoadingView(label: 'กำลังโหลดข้อมูลผู้สมัคร'),
        error: (error, _) => EmptyState(
          icon: Icons.person_off_outlined,
          title: 'โหลดข้อมูลผู้สมัครไม่ได้',
          message: userVisibleError(error),
          action: AppPrimaryButton(
            onPressed: () => ref.invalidate(
              companyApplicantDetailProvider((
                jobId: widget.jobId,
                applicationId: widget.applicationId,
              )),
            ),
            child: const Text('ลองอีกครั้ง'),
          ),
        ),
        data: (applicant) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(
              companyApplicantDetailProvider((
                jobId: widget.jobId,
                applicationId: widget.applicationId,
              )).future,
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(kPagePadding),
              children: [
                _ProfileHeaderCard(applicant: applicant),
                const SizedBox(height: 16),
                _SkillsCard(skills: applicant.skills),
                if (applicant.portfolioUrl != null &&
                    applicant.portfolioUrl!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _PortfolioCard(url: applicant.portfolioUrl!.trim()),
                ],
                const SizedBox(height: 16),
                _ResumeCard(
                  resumeFileName: applicant.resumeFileName,
                  resumeObjectKey: applicant.resumeObjectKey,
                ),
                const SizedBox(height: 16),
                _CoverLetterCard(coverLetter: applicant.coverLetter),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: applicantAsync.maybeWhen(
        data: (applicant) {
          final status = applicant.status.trim().toLowerCase();
          if (status == 'submitted') {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(kPagePadding),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: AppPrimaryButton(
                    onPressed: _isUpdating
                        ? null
                        : () => _updateStatusToReviewing(applicant),
                    child: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rate_review_outlined, size: 20),
                                SizedBox(width: 8),
                                Text('เปลี่ยนสถานะเป็น Reviewing'),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            );
          } else if (status == 'reviewing') {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(kPagePadding),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isUpdating
                            ? null
                            : () => _confirmDecision(
                                targetStatus: 'rejected',
                                applicantName: applicant.fullName,
                              ),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('ปฏิเสธ (Reject)'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isUpdating
                            ? null
                            : () => _confirmDecision(
                                targetStatus: 'accepted',
                                applicantName: applicant.fullName,
                              ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('ตอบรับ (Accept)'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return null;
        },
        orElse: () => null,
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.applicant});

  final Applicant applicant;

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

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    return '$day/$month/$year';
  }

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
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applicant.fullName.isEmpty
                          ? 'ไม่ระบุชื่อ'
                          : applicant.fullName,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (applicant.university.isNotEmpty ||
                        applicant.major.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [
                                applicant.university,
                                applicant.major,
                              ].where((s) => s.isNotEmpty).join(' • '),
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.line, height: 1),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(label: _displayStatus(applicant.status)),
              if (applicant.createdAt != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ยื่นเมื่อ ${_formatDate(applicant.createdAt)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillsCard extends StatelessWidget {
  const _SkillsCard({required this.skills});

  final List<String> skills;

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
                Icons.psychology_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const Gap(8),
              Text('ทักษะความสามารถ', style: textTheme.titleMedium),
            ],
          ),
          const Gap(12),
          if (skills.isEmpty)
            Text(
              'ไม่ได้ระบุทักษะ',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    skill,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.url});

  final String url;

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
                Icons.link_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const Gap(8),
              Text('Portfolio / ผลงาน', style: textTheme.titleMedium),
            ],
          ),
          const Gap(10),
          SelectableText(
            url,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({this.resumeFileName, this.resumeObjectKey});

  final String? resumeFileName;
  final String? resumeObjectKey;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.picture_as_pdf_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const Gap(8),
              Text('Resume ที่ใช้สมัคร', style: textTheme.titleMedium),
            ],
          ),
          const Gap(12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 28,
                  color: AppColors.primary,
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resumeFileName ?? 'Resume (PDF)',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(2),
                      Text(
                        resumeObjectKey != null
                            ? 'สำเนา Resume ในระบบ ณ วันที่ยื่นใบสมัคร'
                            : 'ไม่มีไฟล์ Resume',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                Icons.article_outlined,
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
