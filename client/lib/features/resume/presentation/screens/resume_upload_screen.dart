import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../domain/entities/resume_file.dart';
import '../../../student_profile/presentation/providers/student_profile_controller.dart';
import '../providers/resume_controller.dart';

class ResumeUploadScreen extends ConsumerStatefulWidget {
  const ResumeUploadScreen({super.key});

  @override
  ConsumerState<ResumeUploadScreen> createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends ConsumerState<ResumeUploadScreen> {
  PlatformFile? _pendingCv;
  PlatformFile? _pendingTranscript;
  PlatformFile? _pendingOther;
  String? _error;
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final profileAsync = ref.watch(studentProfileControllerProvider);
    final currentResumeName = profileAsync.asData?.value.resumeFileName;
    final documentsAsync = ref.watch(studentDocumentsProvider);
    final documents = documentsAsync.asData?.value ?? const [];
    final cv = documents.where((d) => d.type == 'cv').firstOrNull;
    final currentCvName = cv?.fileName ?? currentResumeName;
    final transcript = documents
        .where((d) => d.type == 'transcript')
        .firstOrNull;
    final otherDocuments = documents.where((d) => d.type == 'other').toList();
    final pendingCv = _pendingCv;
    final pendingTranscript = _pendingTranscript;
    final pendingOther = _pendingOther;

    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      appBar: AppBar(
        title: const Text('เอกสารของฉัน'),
        backgroundColor: NeoColors.paperCanvas,
        foregroundColor: NeoColors.inkSolid,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(kPagePadding),
        children: [
          Text('CV', style: textTheme.titleLarge),
          const Gap(4),
          Text(
            'ใช้สมัครงาน และแทนที่ไฟล์เดิมได้',
            style: textTheme.bodyMedium?.copyWith(color: NeoColors.subtleInk),
          ),
          const Gap(16),
          _DocumentCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (currentCvName?.isNotEmpty == true) ...[
                  _StoredDocumentRow(
                    label: 'Resume ในระบบ',
                    fileName: currentCvName!,
                    onRemove: cv == null ? null : () => _deleteDocument(cv),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: NeoColors.inkSolid, thickness: 1.5),
                  ),
                ],
                if (pendingCv != null)
                  _PendingUploadArea(
                    fileName: pendingCv.name,
                    uploadLabel: 'อัปโหลด CV',
                    isLoading: _uploading,
                    onRemove: () => _clearPendingFile('cv'),
                    onUpload: () => _upload('cv'),
                  )
                else
                  _DocumentUploadZone(
                    label: currentCvName == null
                        ? 'เลือก CV (PDF)'
                        : 'แก้ไข CV',
                    showPickerHint: currentCvName == null,
                    onPick: _uploading ? null : () => _pickPdf('cv'),
                  ),
              ],
            ),
          ),
          const Gap(24),
          Text('Transcript', style: textTheme.titleLarge),
          const Gap(8),
          _DocumentCard(
            child: Column(
              children: [
                if (transcript != null) ...[
                  _StoredDocumentRow(
                    label: 'Transcript ในระบบ',
                    fileName: transcript.fileName,
                    onRemove: () => _deleteDocument(transcript),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: NeoColors.inkSolid, thickness: 1.5),
                  ),
                ],
                if (pendingTranscript != null)
                  _PendingUploadArea(
                    fileName: pendingTranscript.name,
                    uploadLabel: 'อัปโหลด Transcript',
                    isLoading: _uploading,
                    onRemove: () => _clearPendingFile('transcript'),
                    onUpload: () => _upload('transcript'),
                  )
                else
                  _DocumentUploadZone(
                    label: transcript == null
                        ? 'เพิ่ม Transcript (PDF)'
                        : 'แก้ไข Transcript',
                    showPickerHint: transcript == null,
                    onPick: _uploading ? null : () => _pickPdf('transcript'),
                  ),
              ],
            ),
          ),
          const Gap(24),
          Text(
            'เอกสารอื่น (${otherDocuments.length}/3)',
            style: textTheme.titleLarge,
          ),
          const Gap(8),
          _DocumentCard(
            child: Column(
              children: [
                for (final document in otherDocuments) ...[
                  _StoredDocumentRow(
                    label: 'เอกสารอื่นในระบบ',
                    fileName: document.fileName,
                    onRemove: () => _deleteDocument(document),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: NeoColors.inkSolid, thickness: 1.5),
                  ),
                ],
                if (pendingOther != null)
                  _PendingUploadArea(
                    fileName: pendingOther.name,
                    uploadLabel: 'อัปโหลดเอกสารอื่น',
                    isLoading: _uploading,
                    onRemove: () => _clearPendingFile('other'),
                    onUpload: () => _upload('other'),
                  )
                else
                  _DocumentUploadZone(
                    label: otherDocuments.isEmpty
                        ? 'เพิ่มเอกสารอื่น (PDF)'
                        : 'แก้ไขเอกสารอื่น',
                    showPickerHint: otherDocuments.isEmpty,
                    onPick: _uploading || otherDocuments.length >= 3
                        ? null
                        : () => _pickPdf('other'),
                  ),
              ],
            ),
          ),
          if (otherDocuments.length >= 3)
            Text(
              'ลบไฟล์หนึ่งรายการก่อนเพิ่มเอกสารใหม่',
              style: textTheme.bodySmall?.copyWith(color: NeoColors.subtleInk),
            ),
          if (_error != null) ...[
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NeoColors.errorBg,
                border: Border.all(color: NeoColors.errorBorder, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: NeoShadows.elevation1,
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
    );
  }

  Future<void> _pickPdf(String kind) async {
    setState(() => _error = null);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (file == null) {
        return;
      }
      final extension = file.extension?.toLowerCase();
      final hasPdfExt = file.name.toLowerCase().endsWith('.pdf');
      if (extension != 'pdf' && !hasPdfExt) {
        setState(() => _error = 'เลือกได้เฉพาะไฟล์ PDF เท่านั้น');
        return;
      }
      setState(() {
        switch (kind) {
          case 'cv':
            _pendingCv = file;
          case 'transcript':
            _pendingTranscript = file;
          case 'other':
            _pendingOther = file;
        }
      });
    } catch (error) {
      setState(() => _error = userVisibleError(error));
    }
  }

  void _clearPendingFile(String kind) {
    setState(() {
      switch (kind) {
        case 'cv':
          _pendingCv = null;
        case 'transcript':
          _pendingTranscript = null;
        case 'other':
          _pendingOther = null;
      }
    });
  }

  Future<void> _deleteDocument(StudentDocument document) async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await ref.read(resumeRepositoryProvider).deleteDocument(document.id);
      ref.invalidate(studentDocumentsProvider);
      ref.invalidate(studentProfileControllerProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('นำ ${document.fileName} ออกแล้ว')),
      );
    } catch (error) {
      if (mounted) setState(() => _error = userVisibleError(error));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _upload(String kind) async {
    final file = switch (kind) {
      'cv' => _pendingCv,
      'transcript' => _pendingTranscript,
      _ => _pendingOther,
    };
    if (file == null) {
      return;
    }
    final path = file.path;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      List<int>? bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        bytes = null;
      }
      if ((path == null || path.isEmpty) && (bytes == null || bytes.isEmpty)) {
        setState(() => _error = 'เลือกไฟล์จากเครื่องเพื่ออัปโหลด');
        return;
      }
      await ref
          .read(resumeRepositoryProvider)
          .uploadDocument(
            kind: kind,
            filePath: path ?? '',
            fileName: file.name,
            bytes: bytes,
          );
      ref.invalidate(studentDocumentsProvider);
      ref.invalidate(studentProfileControllerProvider);
      if (!mounted) {
        return;
      }
      final uploadedLabel = switch (kind) {
        'cv' => 'CV',
        'transcript' => 'Transcript',
        _ => 'เอกสารอื่น',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('อัปโหลด$uploadedLabelแล้ว')));
      _clearPendingFile(kind);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = userVisibleError(error));
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: NeoColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoColors.inkSolid, width: 2.5),
        boxShadow: NeoShadows.elevation3,
      ),
      child: child,
    );
  }
}

class _StoredDocumentRow extends StatelessWidget {
  const _StoredDocumentRow({
    required this.label,
    required this.fileName,
    this.onRemove,
  });

  final String label;
  final String fileName;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          LucideIcons.checkCircle2,
          color: NeoColors.electricIndigo,
          size: 20,
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const Gap(2),
              Text(fileName, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        if (onRemove != null)
          IconButton(
            tooltip: 'นำเอกสารออก',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, color: NeoColors.errorText),
          ),
      ],
    );
  }
}

class _DocumentUploadZone extends StatelessWidget {
  const _DocumentUploadZone({
    required this.label,
    required this.showPickerHint,
    required this.onPick,
  });

  final String label;
  final bool showPickerHint;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showPickerHint) ...[
          const Icon(
            LucideIcons.uploadCloud,
            size: 40,
            color: NeoColors.electricIndigo,
          ),
          const Gap(8),
          Text(
            'เลือกไฟล์ PDF จากเครื่อง',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Gap(12),
        ],
        NeoButton(
          onPressed: onPick,
          text: label,
          icon: const Icon(Icons.upload_file, size: 19),
          variant: NeoButtonVariant.secondary,
          isFullWidth: true,
        ),
      ],
    );
  }
}

class _PendingUploadArea extends StatelessWidget {
  const _PendingUploadArea({
    required this.fileName,
    required this.uploadLabel,
    required this.isLoading,
    required this.onRemove,
    required this.onUpload,
  });

  final String fileName;
  final String uploadLabel;
  final bool isLoading;
  final VoidCallback onRemove;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.fileText,
              color: NeoColors.electricIndigo,
              size: 22,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Gap(2),
                  Text(
                    'พร้อมอัปโหลด',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: NeoColors.subtleInk,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'เอาไฟล์ออก',
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, color: NeoColors.errorText),
            ),
          ],
        ),
        const Gap(12),
        NeoButton(
          onPressed: onUpload,
          text: uploadLabel,
          icon: const Icon(Icons.upload_file, size: 19),
          variant: NeoButtonVariant.secondary,
          isLoading: isLoading,
          isFullWidth: true,
        ),
      ],
    );
  }
}
