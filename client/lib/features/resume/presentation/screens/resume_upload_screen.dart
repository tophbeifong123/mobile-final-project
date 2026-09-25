import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../student_profile/presentation/providers/student_profile_controller.dart';
import '../providers/resume_controller.dart';

class ResumeUploadScreen extends ConsumerStatefulWidget {
  const ResumeUploadScreen({super.key});

  @override
  ConsumerState<ResumeUploadScreen> createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends ConsumerState<ResumeUploadScreen> {
  PlatformFile? _file;
  String? _error;
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    final file = _file;
    final profileAsync = ref.watch(studentProfileControllerProvider);
    final currentResumeName = profileAsync.asData?.value.resumeFileName;

    return Scaffold(
      appBar: AppBar(title: const Text('อัปโหลด Resume')),
      body: ListView(
        padding: const EdgeInsets.all(kPagePadding),
        children: [
          Text('ไฟล์ PDF', style: textTheme.titleLarge),
          const Gap(4),
          Text(
            'ต้องมี Resume เป็น PDF ก่อนสมัครงาน',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          const Gap(16),
          if (currentResumeName != null && currentResumeName.isNotEmpty) ...[
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
                        Text('Resume ในระบบ', style: textTheme.labelMedium),
                        const Gap(2),
                        Text(currentResumeName, style: textTheme.titleMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
          ],
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.uploadCloud,
                  size: 40,
                  color: AppColors.primary,
                ),
                const Gap(8),
                Text(
                  'เลือกไฟล์ PDF จากเครื่อง',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
                const Gap(12),
                OutlinedButton(
                  onPressed: _uploading ? null : _pickPdf,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(kMinTouchTarget),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('เลือกไฟล์'),
                ),
              ],
            ),
          ),
          if (file != null) ...[
            const Gap(16),
            AppCard(
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.fileText,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(file.name, style: textTheme.titleMedium),
                        const Gap(8),
                        const StatusChip(label: 'พร้อมอัปโหลด'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const Gap(12),
            Text(
              _error!,
              style: textTheme.bodyMedium?.copyWith(color: colors.destructive),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(kPagePadding, 8, kPagePadding, 16),
          child: AppPrimaryButton(
            onPressed: file == null || _uploading ? null : _upload,
            child: Text(_uploading ? 'กำลังอัปโหลด' : 'อัปโหลด'),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPdf() async {
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
      setState(() => _file = file);
    } catch (error) {
      setState(() => _error = userVisibleError(error));
    }
  }

  Future<void> _upload() async {
    final file = _file;
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
          .uploadPdf(filePath: path ?? '', fileName: file.name, bytes: bytes);
      ref.invalidate(studentProfileControllerProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('อัปโหลด Resume แล้ว')));
      setState(() => _file = null);
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
