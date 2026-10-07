import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../domain/entities/resume_file.dart';
import '../../../student_profile/presentation/providers/student_profile_controller.dart';
import '../providers/resume_controller.dart';
import '../screens/resume_upload_screen.dart';

/// Profile document management uses the same modal surface as the Links editor.
class StudentDocumentsDialog extends ConsumerStatefulWidget {
  const StudentDocumentsDialog({super.key, this.existing});
  final StudentDocument? existing;

  static Future<void> show(BuildContext context, {StudentDocument? existing}) =>
      showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (_) => StudentDocumentsDialog(existing: existing),
      );

  @override
  ConsumerState<StudentDocumentsDialog> createState() =>
      _StudentDocumentsDialogState();
}

class _StudentDocumentsDialogState
    extends ConsumerState<StudentDocumentsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _kind = 'cv';
  bool _busy = false;
  String? _error, _uploadedName;
  static const _types = {
    'cv': 'CV',
    'transcript': 'Transcript',
    'other': 'เอกสารอื่นๆ',
  };

  @override
  void initState() {
    super.initState();
    final document = widget.existing;
    if (document != null) {
      _kind = document.type;
      _name.text = document.fileName.replaceFirst(
        RegExp(r'\.pdf$', caseSensitive: false),
        '',
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _upload({bool keepFile = false}) async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _uploadedName = null;
    });
    try {
      // Check the canonical list before opening the picker, not a stale count.
      final documents = await ref.read(studentDocumentsProvider.future);
      if (!mounted) return;
      if (_kind == 'other' &&
          widget.existing == null &&
          documents.where((d) => d.type == 'other').length >= 3) {
        throw const AppException(
          'เอกสารอื่นๆ ครบ 3 ไฟล์แล้ว กรุณาลบหรือแทนที่ไฟล์เดิม',
        );
      }
      final file = keepFile ? null : await ref.read(documentPickerProvider)();
      if (!mounted || (!keepFile && file == null)) return;
      if (file != null && !file.name.toLowerCase().endsWith('.pdf')) {
        throw const AppException('เลือกได้เฉพาะไฟล์ PDF เท่านั้น');
      }
      if ((file?.lengthSync() ?? 0) > 10 * 1024 * 1024) {
        throw const AppException('ไฟล์ใหญ่เกิน 10 MiB กรุณาเลือกไฟล์ที่เล็กลง');
      }
      // Reuse the existing PDF through the atomic upload route when renaming.
      // The service preserves any CV snapshot referenced by an application.
      final bytes = keepFile
          ? await ref
                .read(resumeRepositoryProvider)
                .downloadDocumentPdf(widget.existing!.id)
          : await file!.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 10 * 1024 * 1024) {
        throw const AppException('ไฟล์ใหญ่เกิน 10 MiB กรุณาเลือกไฟล์ที่เล็กลง');
      }
      if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
        throw const AppException(
          'ไฟล์นี้ไม่ใช่ PDF ที่ถูกต้อง กรุณาเลือกไฟล์ PDF',
        );
      }
      final title = _name.text.trim();
      final fileName = title.toLowerCase().endsWith('.pdf')
          ? title
          : '$title.pdf';
      await ref
          .read(resumeRepositoryProvider)
          .uploadDocument(
            kind: _kind,
            filePath: file?.path ?? '',
            fileName: fileName,
            bytes: bytes,
            replacingId: _kind == 'other' ? widget.existing?.id : null,
          );
      if (!mounted) return;
      ref.invalidate(studentDocumentsProvider);
      await ref.read(studentDocumentsProvider.future);
      if (!mounted) return;
      ref.invalidate(studentProfileControllerProvider);
      if (keepFile) {
        Navigator.of(context).pop();
        return;
      }
      setState(() => _uploadedName = fileName);
    } catch (error) {
      if (mounted) setState(() => _error = userVisibleError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(studentDocumentsProvider).asData?.value ?? [];
    final replacing =
        widget.existing != null ||
        (_kind != 'other' && documents.any((d) => d.type == _kind));
    final otherCount = documents.where((d) => d.type == 'other').length;
    return PopScope(
      canPop: !_busy,
      child: _DocumentSurface(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.existing == null ? 'เพิ่มเอกสาร' : 'แก้ไขเอกสาร',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
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
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'ประเภทเอกสาร',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _kind,
                  isExpanded: true,
                  decoration: _decoration(),
                  items: _types.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged:
                      _busy || widget.existing != null || _uploadedName != null
                      ? null
                      : (value) => setState(() {
                          _kind = value!;
                          _error = null;
                          _uploadedName = null;
                        }),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ชื่อเอกสาร *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _name,
                  enabled: !_busy && _uploadedName == null,
                  maxLength: 100,
                  decoration: _decoration(
                    hint: 'เช่น CV สมัครงาน, ผลการเรียน',
                  ).copyWith(counterText: ''),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณาระบุชื่อเอกสาร';
                    }
                    if (RegExp(r'[\\/\x00-\x1f]').hasMatch(value)) {
                      return 'ชื่อเอกสารต้องไม่มี / หรือ \\';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  replacing
                      ? 'ไฟล์ใหม่จะแทนที่ ${_types[_kind]} เดิม'
                      : _kind == 'other'
                      ? 'เอกสารอื่นๆ $otherCount/3 ไฟล์'
                      : _kind == 'cv'
                      ? 'CV จำเป็นต่อการสมัครงาน'
                      : 'Transcript ไม่บังคับ',
                  style: const TextStyle(
                    fontSize: 12,
                    color: NeoColors.subtleInk,
                  ),
                ),
                const Text(
                  'PDF เท่านั้น • ไม่เกิน 10 MiB\nเลือกไฟล์แล้วอัปโหลดทันที',
                  style: TextStyle(
                    fontSize: 12,
                    color: NeoColors.subtleInk,
                    height: 1.5,
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: NeoColors.errorText),
                    ),
                  ),
                if (_uploadedName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'อัปโหลดแล้ว: $_uploadedName',
                      style: const TextStyle(color: NeoColors.subtleInk),
                    ),
                  ),
                const SizedBox(height: 12),
                if (widget.existing != null && _uploadedName == null) ...[
                  NeoButton(
                    onPressed: _busy ? null : () => _upload(keepFile: true),
                    isFullWidth: true,
                    isLoading: _busy,
                    text: 'บันทึกชื่อเอกสาร',
                  ),
                  const SizedBox(height: 10),
                ],
                NeoButton(
                  onPressed: _busy
                      ? null
                      : _uploadedName != null
                      ? () => Navigator.of(context).pop()
                      : () => _upload(),
                  isFullWidth: true,
                  isLoading: _busy,
                  text: _busy
                      ? 'กำลังอัปโหลด…'
                      : _uploadedName != null
                      ? 'บันทึก'
                      : replacing
                      ? 'เลือก PDF เพื่อแทนที่'
                      : 'เลือก PDF',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({String? hint}) => InputDecoration(
    isDense: true,
    hintText: hint,
    filled: true,
    fillColor: NeoColors.paperCanvas,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: NeoColors.mutedInk, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: NeoColors.mutedInk, width: 1.5),
    ),
  );
}

class _DocumentSurface extends StatelessWidget {
  const _DocumentSurface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: NeoColors.pureWhite,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: NeoColors.inkSolid, width: 2),
    ),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      // Let the editor fit both actions instead of clipping at a fixed 410px.
      // Dialog still constrains to the available screen/keyboard height, where
      // the inner scroll view remains an accessibility fallback.
      constraints: const BoxConstraints(maxWidth: 320),
      // Keep the white Scaffold inside the stroke instead of painting over it.
      child: Padding(
        key: ValueKey('document-dialog-border-inset'),
        padding: EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          child: child,
        ),
      ),
    ),
  );
}
