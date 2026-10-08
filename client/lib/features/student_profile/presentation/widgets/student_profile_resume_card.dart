import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../resume/domain/entities/resume_file.dart';
import '../../../resume/presentation/providers/resume_controller.dart';
import '../../../resume/presentation/widgets/student_documents_dialog.dart';
import '../providers/student_profile_controller.dart';
import 'resume_preview_modal.dart';

/// Documents are visible and actionable on the profile, like contact links.
class StudentProfileResumeCard extends ConsumerStatefulWidget {
  const StudentProfileResumeCard({super.key, required this.resumeFileName});
  final String? resumeFileName;

  @override
  ConsumerState<StudentProfileResumeCard> createState() =>
      _StudentProfileResumeCardState();
}

class _StudentProfileResumeCardState
    extends ConsumerState<StudentProfileResumeCard> {
  String? _deletingId, _error;

  Future<void> _delete(StudentDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบเอกสาร?'),
        content: Text(
          'ต้องการลบ ${document.fileName} หรือไม่?\nCV ที่ใช้สมัครงานไปแล้วจะยังอยู่ในใบสมัครเดิม',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ลบ',
              style: TextStyle(color: NeoColors.errorText),
            ),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _deletingId != null) return;
    setState(() {
      _deletingId = document.id;
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
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(studentDocumentsProvider);
    final documents = result.asData?.value ?? const <StudentDocument>[];
    // Legacy filename is only a fallback until the canonical library is loaded.
    final legacyName = result.asData == null ? widget.resumeFileName : null;
    final busy = _deletingId != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoColors.inkSolid, width: 1.5),
        boxShadow: const [
          BoxShadow(color: NeoColors.inkSolid, offset: Offset(3, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: NeoColors.freshMint,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: NeoColors.inkSolid, width: 1.2),
                ),
                child: const Icon(Icons.description_rounded, size: 15),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'เอกสารของฉัน',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => StudentDocumentsDialog.show(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: NeoColors.freshMint,
                  foregroundColor: NeoColors.inkSolid,
                  side: const BorderSide(color: NeoColors.inkSolid, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('+ เพิ่ม'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (documents.isEmpty)
            if (legacyName != null && legacyName.isNotEmpty)
              _DocumentRow(
                label: 'CV',
                fileName: legacyName,
                onOpen: () =>
                    ResumePreviewModal.show(context, fileName: legacyName),
              )
            else
              const Text(
                'ยังไม่มี CV ในระบบ',
                style: TextStyle(color: NeoColors.subtleInk),
              ),
          for (final document in documents)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DocumentRow(
                label:
                    {
                      'cv': 'CV',
                      'transcript': 'Transcript',
                      'other': 'เอกสารอื่นๆ',
                    }[document.type] ??
                    document.type,
                fileName: document.fileName,
                isDeleting: document.id == _deletingId,
                onOpen: busy
                    ? null
                    : () => ResumePreviewModal.show(
                        context,
                        fileName: document.fileName,
                        documentId: document.id,
                      ),
                onEdit: busy
                    ? null
                    : () => StudentDocumentsDialog.show(
                        context,
                        existing: document,
                      ),
                onDelete: busy ? null : () => _delete(document),
                editable: true,
              ),
            ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: NeoColors.errorText)),
          if (result.hasError && documents.isEmpty)
            TextButton(
              onPressed: busy
                  ? null
                  : () => ref.invalidate(studentDocumentsProvider),
              child: const Text('โหลดเอกสารไม่สำเร็จ · ลองใหม่'),
            ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.label,
    required this.fileName,
    this.onOpen,
    this.onEdit,
    this.onDelete,
    this.editable = false,
    this.isDeleting = false,
  });
  final String label, fileName;
  final VoidCallback? onOpen, onEdit, onDelete;
  final bool editable, isDeleting;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: NeoColors.pureWhite,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: NeoColors.inkSolid, width: 1.2),
      boxShadow: const [
        BoxShadow(color: NeoColors.inkSolid, offset: Offset(1.5, 2)),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 36,
          decoration: BoxDecoration(
            color: NeoColors.skyBlue,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: NeoColors.inkSolid),
          ),
          child: const Icon(Icons.picture_as_pdf_rounded, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: NeoColors.subtleInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: NeoColors.electricIndigo,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          key: ValueKey('document-actions-$fileName'),
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _action('เปิดดู $fileName', Icons.visibility_outlined, onOpen),
              if (editable) ...[
                _action('แก้ไข $fileName', Icons.edit_outlined, onEdit),
                if (isDeleting)
                  const SizedBox(
                    width: 31,
                    height: 44,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.5,
                        vertical: 13,
                      ),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  _action(
                    'ลบ $fileName',
                    Icons.delete_outline_rounded,
                    onDelete,
                    color: NeoColors.errorText,
                  ),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  Widget _action(
    String tooltip,
    IconData icon,
    VoidCallback? onPressed, {
    Color color = NeoColors.inkSolid,
  }) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      // 18px icons: reduce the visible gap from 26px to 13px.
      fixedSize: const Size(31, 44),
      minimumSize: const Size(31, 44),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    icon: Icon(icon, size: 18, color: color),
  );
}
