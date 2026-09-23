import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_hero_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

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
            const SizedBox(height: 16),
            if (job != null) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.companyName,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Text(
                'รหัสประกาศ ${widget.jobId}',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
            ],
            if (!hasResume) ...[
              Card(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.error),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ยังไม่มี Resume ในระบบ',
                              style: textTheme.titleSmall?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'คุณต้องมี Resume เป็นไฟล์ PDF ก่อน จึงจะสามารถยื่นใบสมัครได้',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.push('/student/resume'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(kMinTouchTarget),
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('อัปโหลด Resume'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Resume ที่จะใช้', style: textTheme.labelSmall),
                            const SizedBox(height: 2),
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
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _coverLetterController,
              minLines: 8,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Cover Letter',
                alignLabelWithHint: true,
                hintText: 'บอกว่าทำไมอยากฝึกงานที่นี่',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรอก Cover Letter';
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
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
      await ref.read(applicationRepositoryProvider).apply(
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
