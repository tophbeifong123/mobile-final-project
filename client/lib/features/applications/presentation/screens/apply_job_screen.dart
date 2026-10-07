import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/neo_button.dart';
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
    final profileAsync = ref.watch(studentProfileControllerProvider);
    final profile = profileAsync.asData?.value;
    final hasResume =
        (profile?.resumeFileName?.isNotEmpty ?? false) ||
        (profile?.resumeObjectKey?.isNotEmpty ?? false);
    final jobAsync = ref.watch(jobDetailProvider(widget.jobId));
    final job = jobAsync.asData?.value;

    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      appBar: AppBar(
        title: const Text('สมัครงาน'),
        backgroundColor: NeoColors.paperCanvas,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(kPagePadding, 8, kPagePadding, 24),
          children: [
            _NeoPanel(
              color: NeoColors.butterYellow,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.send, size: 24),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ยืนยันการสมัคร',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          'เขียน Cover Letter ให้ครบก่อนส่ง ใบสมัครใหม่จะมีสถานะ Submitted และสมัครได้ครั้งเดียวต่องาน',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
            if (jobAsync.isLoading)
              const _NeoPanel(child: Center(child: CircularProgressIndicator()))
            else if (jobAsync.hasError)
              _NeoPanel(
                color: NeoColors.errorBg,
                child: Text(
                  'โหลดรายละเอียดงานไม่ได้: ${userVisibleError(jobAsync.error!)}',
                ),
              )
            else if (job != null) ...[
              _NeoPanel(
                color: NeoColors.pureWhite,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Eyebrow('ประกาศที่สมัคร'),
                    const Gap(8),
                    Text(
                      job.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                      softWrap: true,
                    ),
                    const Gap(6),
                    Text(
                      job.companyName,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: NeoColors.subtleInk,
                      ),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
              const Gap(16),
            ],
            if (profileAsync.isLoading)
              const _NeoPanel(child: Center(child: CircularProgressIndicator()))
            else if (profileAsync.hasError)
              _NeoPanel(
                color: NeoColors.errorBg,
                child: Text(
                  'โหลดโปรไฟล์นักศึกษาไม่ได้: ${userVisibleError(profileAsync.error!)}',
                ),
              )
            else if (!hasResume) ...[
              _NeoPanel(
                color: NeoColors.softRose,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.triangleAlert, size: 20),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            'ยังไม่มี CV ในระบบ',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    const Text(
                      'คุณต้องมี Resume เป็นไฟล์ PDF ก่อน จึงจะสามารถยื่นใบสมัครได้',
                    ),
                    const Gap(12),
                    NeoButton(
                      key: const Key('apply-upload-cv'),
                      onPressed: () => context.push('/student/resume'),
                      variant: NeoButtonVariant.outline,
                      text: 'อัปโหลด Resume',
                      icon: const Icon(LucideIcons.upload, size: 18),
                    ),
                  ],
                ),
              ),
              const Gap(16),
            ] else ...[
              _NeoPanel(
                color: NeoColors.freshMint,
                child: Row(
                  children: [
                    const Icon(LucideIcons.fileCheck2, size: 22),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Eyebrow('CV ที่จะใช้'),
                          const Gap(3),
                          Text(
                            profile?.resumeFileName?.isNotEmpty == true
                                ? profile!.resumeFileName!
                                : 'resume.pdf',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    NeoButton(
                      onPressed: () => context.push('/student/resume'),
                      variant: NeoButtonVariant.outline,
                      height: 44,
                      text: 'เปลี่ยน',
                    ),
                  ],
                ),
              ),
              const Gap(16),
            ],
            _NeoPanel(
              key: const Key('apply-form-card'),
              color: NeoColors.pureWhite,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cover Letter',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Gap(6),
                    const Text('เล่าให้บริษัทฟังว่าทำไมคุณสนใจตำแหน่งนี้'),
                    const Gap(12),
                    TextFormField(
                      key: const Key('apply-cover-letter'),
                      controller: _coverLetterController,
                      minLines: 8,
                      maxLines: 12,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'เขียน Cover Letter ของคุณที่นี่',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'กรอก Cover Letter'
                          : null,
                    ),
                    if (_error != null) ...[
                      const Gap(12),
                      Container(
                        key: const Key('apply-submit-error'),
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: NeoColors.errorBg,
                          border: Border.all(
                            color: NeoColors.errorBorder,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: NeoColors.errorText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Gap(24),
            NeoButton(
              key: const Key('apply-submit'),
              onPressed: (!hasResume || _submitting || job == null)
                  ? null
                  : _submit,
              isLoading: _submitting,
              isFullWidth: true,
              height: 52,
              text: _submitting ? 'กำลังส่งใบสมัคร' : 'ยืนยันสมัคร',
              trailingIcon: _submitting
                  ? null
                  : const Icon(LucideIcons.send, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ส่งใบสมัครแล้ว')));
      context.go('/student/applications');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = userVisibleError(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _NeoPanel extends StatelessWidget {
  const _NeoPanel({
    super.key,
    this.color = NeoColors.pureWhite,
    required this.child,
  });

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: NeoColors.inkSolid, width: 2.5),
      boxShadow: NeoShadows.elevation3,
    ),
    child: child,
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: 0.7,
    ),
  );
}
