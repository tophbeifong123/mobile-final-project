import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../jobs/presentation/providers/jobs_controller.dart';
import '../../../resume/presentation/providers/resume_controller.dart';
import '../../../student_profile/presentation/widgets/resume_preview_modal.dart';
import '../widgets/application_documents_dialog.dart';
import '../providers/applications_controller.dart';

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
    final colors = context.colors;

    final library = ref.watch(studentDocumentsProvider);
    final documents = library.asData?.value ?? [];
    final cv = documents.where((d) => d.type == 'cv').firstOrNull;
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
          bottom: BorderSide(color: NeoColors.inkSolid, width: 2),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kPagePadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (library.isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (library.hasError)
                    _ApplicationCard(
                      child: Column(
                        children: [
                          Text(userVisibleError(library.error!)),
                          TextButton(
                            onPressed: () =>
                                ref.invalidate(studentDocumentsProvider),
                            child: const Text('ลองใหม่'),
                          ),
                        ],
                      ),
                    ),
                  _ApplicationCard(
                    backgroundColor: NeoColors.butterYellow,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ยืนยันการสมัคร',
                          style: textTheme.titleLarge?.copyWith(
                            color: NeoColors.inkSolid,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Gap(8),
                        const Text(
                          'เขียน Cover Letter และตรวจสอบ CV ก่อนส่งใบสมัคร สมัครได้ครั้งเดียวต่องาน',
                          style: TextStyle(
                            color: NeoColors.subtleInk,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  if (job != null) ...[
                    _ApplicationCard(
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
                    Text(
                      'รหัสประกาศ ${widget.jobId}',
                      style: textTheme.bodySmall,
                    ),
                    const Gap(12),
                  ],
                  if (!hasResume) ...[
                    _ApplicationCard(
                      backgroundColor: NeoColors.surfaceCream,
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
                              minimumSize: const Size.fromHeight(
                                kMinTouchTarget,
                              ),
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
                    _ApplicationCard(
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
                                          setState(
                                            () => _documentIds = selected,
                                          );
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
                            (d) =>
                                d.type == 'cv' || _documentIds.contains(d.id),
                          ))
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: AppCard(
                                key: ValueKey(
                                  'selected-document-${document.id}',
                                ),
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
                  _ApplicationCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cover Letter',
                          style: TextStyle(
                            color: NeoColors.inkSolid,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Gap(8),
                        TextFormField(
                          controller: _coverLetterController,
                          minLines: 5,
                          maxLines: 12,
                          enabled: !_submitting,
                          style: const TextStyle(
                            color: NeoColors.inkSolid,
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: 'บอกว่าทำไมอยากฝึกงานที่นี่',
                            hintStyle: const TextStyle(
                              color: NeoColors.subtleInk,
                            ),
                            filled: true,
                            fillColor: NeoColors.paperCanvas,
                            contentPadding: const EdgeInsets.all(12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: NeoColors.inkSolid,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: NeoColors.electricIndigo,
                                width: 2,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'กรอก Cover Letter';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
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
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: NeoColors.paperCanvas,
          border: Border(top: BorderSide(color: NeoColors.inkSolid, width: 2)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              kPagePadding,
              8,
              kPagePadding,
              16,
            ),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: NeoButton(
                  onPressed: (!hasResume || _submitting) ? null : _submit,
                  isFullWidth: true,
                  isLoading: _submitting,
                  text: _submitting ? 'กำลังส่ง' : 'ยืนยันสมัคร',
                ),
              ),
            ),
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
              ..._documentIds,
              if (_documentIds.isEmpty)
                ...ref
                    .read(studentDocumentsProvider)
                    .asData!
                    .value
                    .where((d) => d.type == 'cv')
                    .map((d) => d.id),
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
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.child,
    this.backgroundColor = NeoColors.pureWhite,
  });
  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => AppCard(
    backgroundColor: backgroundColor,
    borderColor: NeoColors.inkSolid,
    borderWidth: 2,
    shadows: const [BoxShadow(color: NeoColors.inkSolid, offset: Offset(3, 3))],
    child: child,
  );
}
