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
  const ResumeUploadScreen({super.key, this.isDialog = false});
  final bool isDialog;
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
    return PopScope(
      canPop: !widget.isDialog || !_busy,
      child: Scaffold(
        backgroundColor: widget.isDialog
            ? NeoColors.pureWhite
            : NeoColors.paperCanvas,
        appBar: AppBar(
          automaticallyImplyLeading: !widget.isDialog,
          title: Text(
            widget.isDialog ? 'เพิ่ม / จัดการเอกสาร' : 'เอกสารของฉัน',
            style: widget.isDialog
                ? const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)
                : null,
          ),
          backgroundColor: widget.isDialog
              ? NeoColors.pureWhite
              : NeoColors.paperCanvas,
          actions: widget.isDialog
              ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      tooltip: 'ปิดหน้าต่างเอกสาร',
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: NeoColors.paperCanvas,
                        side: const BorderSide(color: NeoColors.inkSolid),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ]
              : null,
          foregroundColor: NeoColors.inkSolid,
          surfaceTintColor: Colors.transparent,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: RefreshIndicator(
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
                  if (!widget.isDialog)
                    Text(
                      'เตรียมเอกสารสมัครงาน',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  if (!widget.isDialog) const Gap(8),
                  const Text(
                    'เลือก PDF แล้วอัปโหลดทันที\nแตะชื่อไฟล์เพื่อเปิดดู จัดการไฟล์จากเมนู ⋮',
                    style: TextStyle(color: NeoColors.subtleInk, height: 1.5),
                  ),
                  const Gap(12),
                  const Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text('PDF เท่านั้น'),
                        visualDensity: VisualDensity.compact,
                      ),
                      Chip(
                        label: Text('ไม่เกิน 10 MiB / ไฟล์'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const Gap(24),
                  if (documents == null) ...[
                    if (result.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      Text(userVisibleError(result.error!)),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(studentDocumentsProvider),
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
                      'เอกสารอื่นๆ',
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
          ),
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
      Row(
        children: [
          Expanded(
            child: Text(
              kind == 'other' ? '$title (${documents.length}/3)' : title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kind == 'cv'
                  ? NeoColors.butterYellow
                  : NeoColors.surfaceCream,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NeoColors.inkSolid),
            ),
            child: Text(
              kind == 'cv' ? 'จำเป็น' : 'ไม่บังคับ',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      const Gap(4),
      Text(
        hint,
        style: const TextStyle(color: NeoColors.subtleInk, fontSize: 12),
      ),
      const Gap(12),
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
          Row(
            children: [
              _fileIcon(false),
              const Gap(12),
              Expanded(
                child: NeoButton(
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

  Widget _fileIcon(bool busy) => Container(
    width: 44,
    height: 48,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: busy ? NeoColors.softLilac : NeoColors.skyBlue,
      border: Border.all(color: NeoColors.inkSolid, width: 1.5),
      borderRadius: BorderRadius.circular(10),
    ),
    child: busy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(
            Icons.picture_as_pdf_outlined,
            color: NeoColors.inkSolid,
            size: 24,
          ),
  );

  void _openDocument(StudentDocument document) {
    ResumePreviewModal.show(
      context,
      fileName: document.fileName,
      documentId: document.id,
    );
  }

  Widget _row(String name, {required bool busy, StudentDocument? document}) =>
      _card(
        Row(
          children: [
            _fileIcon(busy),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (busy)
                    Text(
                      _pendingName ?? name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    )
                  else
                    Semantics(
                      button: true,
                      label: 'เปิดดู $name',
                      child: InkWell(
                        onTap: _busy || document == null
                            ? null
                            : () => _openDocument(document),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      if (!busy) ...[
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: Color(0xFF047857),
                        ),
                        const Gap(4),
                      ],
                      Flexible(
                        child: Text(
                          busy ? 'กำลังอัปโหลด…' : 'อัปโหลดแล้ว',
                          style: const TextStyle(
                            color: NeoColors.subtleInk,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!busy && document != null)
              PopupMenuButton<String>(
                tooltip: 'จัดการ $name',
                enabled: !_busy,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: NeoColors.inkSolid,
                ),
                onSelected: (action) {
                  switch (action) {
                    case 'open':
                      _openDocument(document);
                    case 'replace':
                      _pickAndUpload(document.type, replacing: document);
                    case 'delete':
                      _delete(document);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'open',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.open_in_new_rounded),
                      title: Text('เปิดดู'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'replace',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.swap_horiz_rounded),
                      title: Text('แทนที่'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: NeoColors.errorText,
                      ),
                      title: Text(
                        'ลบ',
                        style: TextStyle(color: NeoColors.errorText),
                      ),
                    ),
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
