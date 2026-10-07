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
import '../../../resume/presentation/providers/resume_controller.dart';
import '../../../resume/domain/entities/resume_file.dart';
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
  final _selectedDocumentIds = <String>{};

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;

    final library = ref.watch(studentDocumentsProvider);
    final documents = library.asData?.value;
    final cv = documents?.where((doc) => doc.type == 'cv').firstOrNull;
    final hasResume = cv != null;

    final jobAsync = ref.watch(jobDetailProvider(widget.jobId));
    final job = jobAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('สมัครงาน')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kPagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppHeroCard(
                title: 'ยืนยันการสมัคร',
                body:
                    'เขียน Cover Letter และเลือกเอกสารที่ต้องการแนบ CV จำเป็นต่อสมัคร ไฟล์ที่เลือกจะเก็บเป็นสำเนาของใบสมัครนี้',
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
              if (library.isLoading)
                const Center(child: CircularProgressIndicator()),
              if (library.hasError)
                AppCard(
                  child: Column(
                    children: [
                      Text(
                        'โหลดเอกสารไม่สำเร็จ: ${userVisibleError(library.error!)}',
                      ),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () => ref.invalidate(studentDocumentsProvider),
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                ),
              if (documents != null && !hasResume) ...[
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
              ] else if (cv != null) ...[
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
                            Text(
                              'CV ที่จะแนบ (จำเป็น)',
                              style: textTheme.labelSmall,
                            ),
                            const Gap(2),
                            Text(
                              cv.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () async {
                                await context.push('/student/resume');
                                if (mounted) {
                                  ref.invalidate(studentDocumentsProvider);
                                }
                              },
                        child: const Text('คลังเอกสาร'),
                      ),
                    ],
                  ),
                ),
                const Gap(16),
              ],
              if (documents != null) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เอกสารเพิ่มเติม (ไม่บังคับ)',
                        style: textTheme.titleSmall,
                      ),
                      const Text('บริษัทจะเห็นเฉพาะไฟล์ที่เลือกแนบเท่านั้น'),
                      for (final document in documents.where(
                        (doc) => doc.type != 'cv',
                      ))
                        _optionalDocument(document),
                      if (!documents.any((doc) => doc.type != 'cv'))
                        const Text('ยังไม่มีเอกสารเพิ่มเติมในคลัง'),
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
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kPagePadding, 8, kPagePadding, 16),
          child: AppPrimaryButton(
            onPressed:
                (!hasResume ||
                    library.isLoading ||
                    library.hasError ||
                    _submitting)
                ? null
                : _submit,
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
            documentIds: [
              ...ref
                  .read(studentDocumentsProvider)
                  .asData!
                  .value
                  .where((doc) => doc.type == 'cv')
                  .map((doc) => doc.id),
              ..._selectedDocumentIds,
            ],
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

  Widget _optionalDocument(StudentDocument document) => CheckboxListTile(
    key: ValueKey('attach-${document.id}'),
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    title: Text(
      document.fileName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(
      document.type == 'transcript' ? 'Transcript' : 'เอกสารอื่นๆ',
    ),
    value: _selectedDocumentIds.contains(document.id),
    onChanged: _submitting
        ? null
        : (selected) => setState(() {
            if (selected == true) {
              _selectedDocumentIds.add(document.id);
            } else {
              _selectedDocumentIds.remove(document.id);
            }
          }),
  );
}
