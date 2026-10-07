import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../domain/entities/resume_file.dart';
import '../../../student_profile/presentation/providers/student_profile_controller.dart';
import '../../../student_profile/presentation/widgets/resume_preview_modal.dart';
import '../providers/resume_controller.dart';

/// Injectable platform picker, avoiding real file dialogs in widget tests.
final documentPickerProvider = Provider<Future<PlatformFile?> Function()>(
  (ref) =>
      () => FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      ),
);

class ResumeUploadScreen extends ConsumerStatefulWidget {
  const ResumeUploadScreen({super.key});
  @override
  ConsumerState<ResumeUploadScreen> createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends ConsumerState<ResumeUploadScreen> {
  String? _busyRow, _pendingName, _error;
  bool _picking = false;
  bool get _busy => _busyRow != null || _picking;

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(studentDocumentsProvider);
    final documents = result.asData?.value;
    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      appBar: AppBar(
        title: const Text('เอกสารของฉัน'),
        backgroundColor: NeoColors.paperCanvas,
        foregroundColor: NeoColors.inkSolid,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!_busy) {
            ref.invalidate(studentDocumentsProvider);
            await ref.read(studentDocumentsProvider.future);
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(kPagePadding),
          children: [
            const Text('PDF เท่านั้น • ขนาดไม่เกิน 10 MiB'),
            const Gap(16),
            if (documents == null) ...[
              if (result.isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                Text(userVisibleError(result.error!)),
                TextButton(
                  onPressed: () => ref.invalidate(studentDocumentsProvider),
                  child: const Text('ลองใหม่'),
                ),
              ],
            ] else ...[
              _group(
                'CV',
                'จำเป็นต่อการสมัครงาน',
                'cv',
                documents.where((d) => d.type == 'cv').toList(),
              ),
              const Gap(24),
              _group(
                'Transcript',
                'ไม่บังคับ',
                'transcript',
                documents.where((d) => d.type == 'transcript').toList(),
              ),
              const Gap(24),
              _group(
                'เอกสารอื่น',
                'ไม่เกิน 3 ไฟล์',
                'other',
                documents.where((d) => d.type == 'other').toList(),
              ),
            ],
            if (_error != null) ...[
              const Gap(12),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: const TextStyle(color: NeoColors.errorText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _group(
    String title,
    String hint,
    String kind,
    List<StudentDocument> documents,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        kind == 'other' ? '$title (${documents.length}/3)' : title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      Text(hint, style: const TextStyle(color: NeoColors.subtleInk)),
      const Gap(8),
      for (final document in documents) ...[
        _row(
          document.fileName,
          busy: _busyRow == document.id,
          document: document,
        ),
        const Gap(8),
      ],
      if (_busyRow == kind)
        _row(_pendingName ?? '', busy: true)
      else if (documents.isEmpty || (kind == 'other' && documents.length < 3))
        _card(
          NeoButton(
            text: switch (kind) {
              'cv' => 'เพิ่ม CV',
              'transcript' => 'เพิ่ม Transcript',
              _ => 'เพิ่มไฟล์',
            },
            variant: NeoButtonVariant.secondary,
            isFullWidth: true,
            onPressed: _busy ? null : () => _pickAndUpload(kind),
          ),
        ),
    ],
  );

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: NeoColors.pureWhite,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: NeoColors.inkSolid, width: 2),
      boxShadow: NeoShadows.elevation1,
    ),
    child: child,
  );

  Widget _row(String name, {required bool busy, StudentDocument? document}) =>
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: NeoColors.electricIndigo,
                  ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        busy ? (_pendingName ?? name) : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        busy ? 'กำลังอัปโหลด…' : 'อัปโหลดแล้ว',
                        style: const TextStyle(color: NeoColors.subtleInk),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!busy && document != null)
              Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => ResumePreviewModal.show(
                            context,
                            fileName: name,
                            documentId: document.id,
                          ),
                    child: const Text('เปิดดู'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _pickAndUpload(
                            document.type,
                            replacing: document,
                          ),
                    child: const Text('แทนที่'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _delete(document),
                    child: const Text('ลบ'),
                  ),
                ],
              ),
          ],
        ),
      );

  Future<void> _pickAndUpload(String kind, {StudentDocument? replacing}) async {
    if (_busy) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final file = await ref.read(documentPickerProvider)();
      if (!mounted || file == null) return;
      if (!file.name.toLowerCase().endsWith('.pdf')) {
        throw const AppException('เลือกได้เฉพาะไฟล์ PDF เท่านั้น');
      }
      if ((file.lengthSync() ?? 0) > 10 * 1024 * 1024) {
        throw const AppException('ไฟล์ใหญ่เกิน 10 MiB กรุณาเลือกไฟล์ที่เล็กลง');
      }
      setState(() {
        _busyRow = replacing?.id ?? kind;
        _pendingName = file.name;
      });
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 10 * 1024 * 1024) {
        throw const AppException('ไฟล์ใหญ่เกิน 10 MiB กรุณาเลือกไฟล์ที่เล็กลง');
      }
      if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
        throw const AppException(
          'ไฟล์นี้ไม่ใช่ PDF ที่ถูกต้อง กรุณาเลือกไฟล์ PDF',
        );
      }
      await ref
          .read(resumeRepositoryProvider)
          .uploadDocument(
            kind: kind,
            filePath: file.path ?? '',
            fileName: file.name,
            bytes: bytes,
            replacingId: kind == 'other' ? replacing?.id : null,
          );
      if (!mounted) return;
      ref.invalidate(studentDocumentsProvider);
      await ref.read(studentDocumentsProvider.future);
      if (!mounted) return;
      ref.invalidate(studentProfileControllerProvider);
    } catch (error) {
      if (mounted) setState(() => _error = userVisibleError(error));
    } finally {
      if (mounted) {
        setState(() {
          _picking = false;
          _busyRow = null;
          _pendingName = null;
        });
      }
    }
  }

  Future<void> _delete(StudentDocument document) async {
    if (_busy) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      await ref.read(resumeRepositoryProvider).deleteDocument(document.id);
      if (!mounted) return;
      ref.invalidate(studentDocumentsProvider);
      await ref.read(studentDocumentsProvider.future);
      if (!mounted) return;
      ref.invalidate(studentProfileControllerProvider);
    } catch (error) {
      if (mounted) setState(() => _error = userVisibleError(error));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }
}
