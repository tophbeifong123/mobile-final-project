import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_hero_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../jobs/presentation/providers/jobs_controller.dart';
import '../../../student_profile/presentation/providers/student_profile_controller.dart';
import '../providers/applications_controller.dart';

class ApplyJobScreen extends ConsumerStatefulWidget {
  const ApplyJobScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends ConsumerState<ApplyJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;

    final profileAsync = ref.watch(studentProfileControllerProvider);
    final profile = profileAsync.asData?.value;
    final hasResume =
        (profile?.resumeFileName != null &&
            profile!.resumeFileName!.isNotEmpty) ||
        (profile?.resumeObjectKey != null &&
            profile!.resumeObjectKey!.isNotEmpty);

    final jobAsync = ref.watch(jobDetailProvider(widget.jobId));
    final job = jobAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('สมัครงาน')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(kPagePadding),
          children: [
            const AppHeroCard(
              title: 'ยืนยันการสมัคร',
              body:
                  'เขียน Cover Letter ให้ครบ ใบสมัครใหม่จะได้สถานะ Submitted ต้องมี Resume PDF ก่อน และสมัครได้ครั้งเดียวต่องาน',
            ),
            const Gap(16),
            if (job != null) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      job.companyName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
            ] else ...[
              Text('รหัสประกาศ ${widget.jobId}', style: textTheme.bodySmall),
              const Gap(12),
            ],
            if (!hasResume) ...[
              AppCard(
                backgroundColor: colors.destructive.withValues(alpha: 0.08),
                borderColor: colors.destructive,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.alertTriangle,
                          color: colors.destructive,
                          size: 20,
                        ),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            'ยังไม่มี Resume ในระบบ',
                            style: textTheme.titleSmall?.copyWith(
                              color: colors.destructive,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    Text(
                      'คุณต้องมี Resume เป็นไฟล์ PDF ก่อน จึงจะสามารถยื่นใบสมัครได้',
                      style: textTheme.bodySmall,
                    ),
                    const Gap(12),
                    OutlinedButton(
                      onPressed: () => context.push('/student/resume'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(kMinTouchTarget),
                        foregroundColor: colors.destructive,
                        side: BorderSide(color: colors.destructive),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('อัปโหลด Resume'),
                    ),
                  ],
                ),
              ),
              const Gap(16),
            ] else ...[
              AppCard(
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.checkCircle2,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Resume ที่จะใช้', style: textTheme.labelSmall),
                          const Gap(2),
                          Text(
                            profile.resumeFileName ?? 'resume.pdf',
                            style: textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/student/resume'),
                      child: const Text('เปลี่ยน'),
                    ),
                  ],
                ),
              ),
              const Gap(16),
            ],
            AppTextField(
              controller: _coverLetterController,
              minLines: 8,
              maxLines: 12,
              label: 'Cover Letter',
              hintText: 'บอกว่าทำไมอยากฝึกงานที่นี่',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรอก Cover Letter';
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const Gap(12),
              Text(
                _error!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.destructive,
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kPagePadding, 8, kPagePadding, 16),
          child: AppPrimaryButton(
            onPressed: (!hasResume || _submitting) ? null : _submit,
            child: Text(_submitting ? 'กำลังส่ง' : 'ยืนยันสมัคร'),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(applicationRepositoryProvider)
          .apply(
            jobId: widget.jobId,
            coverLetter: _coverLetterController.text.trim(),
          );
      ref.invalidate(applicationsControllerProvider);
      ref.invalidate(myApplicationsProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ส่งใบสมัครแล้ว')));
      context.go('/student/applications');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = userVisibleError(error));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
