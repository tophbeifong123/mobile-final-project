import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../jobs/presentation/providers/jobs_controller.dart';
import '../../../resume/presentation/providers/resume_controller.dart';
import '../../../student_profile/presentation/widgets/resume_preview_modal.dart';
import '../providers/applications_controller.dart';
import '../widgets/application_documents_dialog.dart';

class ApplyJobScreen extends ConsumerStatefulWidget {
  const ApplyJobScreen({
    super.key,
    required this.jobId,
    this.documentIds = const [],
  });

  final String jobId;
  final List<String> documentIds;

  @override
  ConsumerState<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends ConsumerState<ApplyJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  String? _error;
  bool _submitting = false;
  late List<String> _documentIds = List.of(widget.documentIds);

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final library = ref.watch(studentDocumentsProvider);
    final documents = library.asData?.value ?? [];
    final cv = documents.where((document) => document.type == 'cv').firstOrNull;
    final hasResume = cv != null;

    final jobAsync = ref.watch(jobDetailProvider(widget.jobId));
    final job = jobAsync.asData?.value;

    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      appBar: AppBar(
        title: const Text('สมัครงาน'),
        centerTitle: false,
        backgroundColor: NeoColors.paperCanvas,
        foregroundColor: NeoColors.inkSolid,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: NeoColors.inkSolid, width: 1.5),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            key: const Key('apply-scroll-view'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              kPagePadding,
              8,
              kPagePadding,
              24,
            ),
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
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            'เขียน Cover Letter และตรวจสอบ CV ก่อนส่ง ใบสมัครใหม่จะมีสถานะ Submitted และสมัครได้ครั้งเดียวต่องาน',
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
                const _NeoPanel(
                  child: Center(child: CircularProgressIndicator()),
                )
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
                          fontWeight: FontWeight.w800,
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
              ] else
                _NeoPanel(
                  color: NeoColors.errorBg,
                  child: Text('ไม่พบประกาศงาน ${widget.jobId}'),
                ),
              if (library.isLoading)
                const _NeoPanel(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (library.hasError)
                _NeoPanel(
                  color: NeoColors.errorBg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'โหลดเอกสารไม่ได้: ${userVisibleError(library.error!)}',
                      ),
                      const Gap(12),
                      NeoButton(
                        onPressed: () =>
                            ref.invalidate(studentDocumentsProvider),
                        variant: NeoButtonVariant.outline,
                        text: 'ลองใหม่',
                      ),
                    ],
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
                                fontWeight: FontWeight.w800,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'เอกสารที่เลือกแนบ',
                              style: TextStyle(
                                color: NeoColors.inkSolid,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _submitting
                                ? null
                                : () async {
                                    final selected =
                                        await ApplicationDocumentsDialog.show(
                                          context,
                                          selectedIds: _documentIds,
                                        );
                                    if (mounted && selected != null) {
                                      setState(() => _documentIds = selected);
                                    }
                                  },
                            child: const Text('เลือกเอกสาร'),
                          ),
                        ],
                      ),
                      const Text(
                        'บริษัทจะเห็นเฉพาะไฟล์ชุดนี้เมื่อส่งใบสมัคร',
                        style: TextStyle(color: NeoColors.subtleInk),
                      ),
                      for (final document in documents.where(
                        (document) =>
                            document.type == 'cv' ||
                            _documentIds.contains(document.id),
                      ))
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: AppCard(
                            key: ValueKey('selected-document-${document.id}'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            backgroundColor: NeoColors.paperCanvas,
                            borderColor: NeoColors.inkSolid,
                            borderWidth: 2,
                            shadows: NeoShadows.elevation1,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                document.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: NeoColors.inkSolid,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                document.type == 'cv'
                                    ? 'CV'
                                    : document.type == 'transcript'
                                    ? 'Transcript'
                                    : 'เอกสารอื่นๆ',
                              ),
                              trailing: IconButton(
                                tooltip: 'เปิดดู ${document.fileName}',
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  color: NeoColors.inkSolid,
                                ),
                                onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (_) => Consumer(
                                    builder: (context, ref, _) =>
                                        ResumePreviewModal(
                                          fileName: document.fileName,
                                          readOnly: true,
                                          pdfBytes: ref.watch(
                                            studentDocumentPdfBytesProvider(
                                              document.id,
                                            ),
                                          ),
                                          onRetry: () => ref.invalidate(
                                            studentDocumentPdfBytesProvider(
                                              document.id,
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Gap(16),
              ],
              _NeoPanel(
                key: const Key('apply-form-card'),
                color: NeoColors.pureWhite,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cover Letter',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
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
                      enabled: !_submitting,
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
                            width: 1.5,
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: NeoColors.paperCanvas,
          border: Border(
            top: BorderSide(color: NeoColors.inkSolid, width: 1.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              kPagePadding,
              8,
              kPagePadding,
              16,
            ),
            child: NeoButton(
              key: const Key('apply-submit'),
              onPressed: (!hasResume || _submitting) ? null : _submit,
              isFullWidth: true,
              isLoading: _submitting,
              height: 52,
              text: _submitting ? 'กำลังส่งใบสมัคร' : 'ยืนยันสมัคร',
              trailingIcon: _submitting
                  ? null
                  : const Icon(LucideIcons.send, size: 18),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final documents = ref.read(studentDocumentsProvider).asData?.value ?? [];
    final cv = documents.where((document) => document.type == 'cv').firstOrNull;

    if (cv == null) {
      setState(() => _error = 'ไม่พบ CV สำหรับใช้สมัครงาน');
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
            documentIds: [cv.id, ..._documentIds.where((id) => id != cv.id)],
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
      border: Border.all(color: NeoColors.inkSolid, width: 2),
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
      fontWeight: FontWeight.w800,
      letterSpacing: 0.7,
    ),
  );
}
