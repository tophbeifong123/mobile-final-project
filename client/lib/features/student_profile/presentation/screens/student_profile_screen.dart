import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../jobs/presentation/widgets/feed_top_bar.dart';
import '../../domain/entities/student_profile.dart';
import '../providers/student_profile_controller.dart';
import '../widgets/student_profile_bio_card.dart';
import '../widgets/student_profile_hero_card.dart';
import '../widgets/student_profile_info_card.dart';
import '../widgets/student_profile_links_card.dart';
import '../widgets/student_profile_resume_card.dart';
import '../widgets/student_profile_skills_card.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(studentProfileControllerProvider);

    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            const FeedTopBar(subtitle: '7. โปรไฟล์นักศึกษา (Student Profile)'),

            // Content Area
            Expanded(
              child: profile.when(
                loading: () => const LoadingView(label: 'กำลังโหลดโปรไฟล์'),
                error: (error, _) => _ProfileError(
                  message: userVisibleError(error),
                  onRetry: () =>
                      ref.invalidate(studentProfileControllerProvider),
                ),
                data: (value) => _ProfileForm(profile: value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileError extends ConsumerWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: EmptyState(
            icon: LucideIcons.userX,
            title: 'โหลดโปรไฟล์ไม่ได้',
            message: message,
            action: AppButton(
              variant: AppButtonVariant.outline,
              size: AppButtonSize.sm,
              onPressed: onRetry,
              text: 'ลองอีกครั้ง',
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          style: TextButton.styleFrom(foregroundColor: NeoColors.errorText),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text(
            'ออกจากระบบ',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.profile});

  final StudentProfile profile;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _universityController;
  late final TextEditingController _majorController;
  late final TextEditingController _bioController;
  late List<String> _skills;
  late List<ContactLink> _links;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController = TextEditingController(text: profile.fullName);
    _universityController = TextEditingController(text: profile.university);
    _majorController = TextEditingController(text: profile.major);
    _bioController = TextEditingController(text: profile.bio);
    _skills = List<String>.from(profile.skills);
    _links = List<ContactLink>.from(profile.contactLinks);

    final existingUrls = _links.map((l) => l.value).toSet();
    for (final p in profile.portfolioLinks) {
      if (p.url.isNotEmpty && !existingUrls.contains(p.url)) {
        _links.add(
          ContactLink(
            platform: 'portfolio',
            label: p.title.isNotEmpty ? p.title : null,
            value: p.url,
          ),
        );
        existingUrls.add(p.url);
      }
    }
    if (profile.portfolioUrl != null &&
        profile.portfolioUrl!.isNotEmpty &&
        !existingUrls.contains(profile.portfolioUrl!)) {
      _links.add(
        ContactLink(
          platform: 'portfolio',
          label: 'Portfolio',
          value: profile.portfolioUrl!,
        ),
      );
      existingUrls.add(profile.portfolioUrl!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // 1. Profile: Student Profile Card Hero
          StudentProfileHeroCard(
            profile: widget.profile,
            onAvatarTap: _handleAvatarTap,
          ),
          const Gap(14),

          // Profile: Active Resume Card
          StudentProfileResumeCard(
            resumeFileName: widget.profile.resumeFileName,
          ),
          const Gap(14),
          // 2. เกี่ยวกับฉัน (About Me / Bio Card)
          StudentProfileBioCard(bioController: _bioController),
          const Gap(14),

          // 3. ข้อมูลทั่วไป (General Information Card)
          StudentProfileInfoCard(
            nameController: _nameController,
            universityController: _universityController,
            majorController: _majorController,
            requiredValidator: _required,
          ),
          const Gap(14),

          // 4. ทักษะ (Skills Section Card)
          StudentProfileSkillsCard(
            skills: _skills,
            onChanged: (updated) => setState(() => _skills = updated),
          ),
          const Gap(14),

          // 5. ผลงานและช่องทางติดต่อ (Unified Links Card)
          StudentProfileLinksCard(
            links: _links,
            onChanged: (updated) => setState(() => _links = updated),
          ),

          if (_error != null) ...[
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NeoColors.errorBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NeoColors.errorBorder, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: NeoColors.errorText,
                    size: 18,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: NeoColors.errorText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Gap(24),

          // Action Section at the bottom of the content
          AppPrimaryButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'กำลังบันทึก' : 'บันทึกโปรไฟล์'),
          ),
          const Gap(12),
          NeoButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            text: 'ออกจากระบบ',
            icon: const Icon(
              Icons.logout_rounded,
              size: 18,
              color: NeoColors.errorText,
            ),
            variant: NeoButtonVariant.destructive,
            isFullWidth: true,
            height: 48,
          ),
        ],
      ),
    );
  }

  void _handleAvatarTap() {
    final hasAvatar =
        widget.profile.avatarObjectKey != null &&
        widget.profile.avatarObjectKey!.isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: NeoColors.pureWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: NeoColors.inkSolid, width: 2),
            boxShadow: const [
              BoxShadow(
                color: NeoColors.inkSolid,
                offset: Offset(0, -4),
                blurRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Title and Neo 'X' button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'รูปโปรไฟล์ (Profile Avatar)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                  ),
                  const Gap(8),
                  InkWell(
                    onTap: () => Navigator.of(bottomSheetCtx).pop(),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: NeoColors.surfaceCream,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: NeoColors.inkSolid,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(16),
              // Option 1: Select new photo
              InkWell(
                onTap: () {
                  Navigator.of(bottomSheetCtx).pop();
                  _pickAndUploadAvatar();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: NeoColors.surfaceCream,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: NeoColors.butterYellow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: NeoColors.inkSolid,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 20,
                          color: NeoColors.inkSolid,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasAvatar
                                  ? 'เปลี่ยนรูปภาพใหม่'
                                  : 'เลือกรูปโปรไฟล์',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: NeoColors.inkSolid,
                              ),
                            ),
                            const Gap(2),
                            const Text(
                              'รองรับไฟล์ JPG, PNG, WEBP, SVG, GIF',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: NeoColors.subtleInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: NeoColors.inkSolid,
                      ),
                    ],
                  ),
                ),
              ),
              if (hasAvatar) ...[
                const Gap(10),
                // Option 2: Remove avatar
                InkWell(
                  onTap: () {
                    Navigator.of(bottomSheetCtx).pop();
                    _confirmDeleteAvatar();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: NeoColors.errorBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: NeoColors.errorBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: NeoColors.pureWhite,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: NeoColors.errorBorder,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: NeoColors.errorText,
                          ),
                        ),
                        const Gap(12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ลบรูปโปรไฟล์',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: NeoColors.errorText,
                                ),
                              ),
                              Gap(2),
                              Text(
                                'กลับไปใช้ตัวอักษรเริ่มต้นแทนรูปภาพ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: NeoColors.errorText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'svg', 'gif'],
      );
      if (file == null) return;

      final ext = file.extension?.toLowerCase() ?? '';
      const allowed = ['png', 'jpg', 'jpeg', 'webp', 'svg', 'gif'];
      if (!allowed.contains(ext) &&
          !allowed.any((e) => file.name.toLowerCase().endsWith('.$e'))) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เลือกได้เฉพาะไฟล์รูปภาพ (PNG, JPG, WEBP, SVG, GIF)'),
            backgroundColor: NeoColors.errorText,
          ),
        );
        return;
      }

      List<int>? bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        bytes = null;
      }

      final path = file.path;
      if ((path == null || path.isEmpty) && (bytes == null || bytes.isEmpty)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถอ่านไฟล์รูปภาพที่เลือกได้'),
            backgroundColor: NeoColors.errorText,
          ),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              Gap(12),
              Text('กำลังอัปโหลดรูปโปรไฟล์...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final updated = await ref
          .read(studentProfileControllerProvider.notifier)
          .uploadAvatar(
            filePath: path ?? '',
            fileName: file.name,
            bytes: bytes,
          );

      ref.invalidate(studentAvatarBytesProvider(updated.avatarObjectKey));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปเดตรูปโปรไฟล์สำเร็จแล้ว 📸')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userVisibleError(error)),
          backgroundColor: NeoColors.errorText,
        ),
      );
    }
  }

  Future<void> _confirmDeleteAvatar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: NeoColors.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: NeoColors.inkSolid, width: 2),
        ),
        title: const Text(
          'ยืนยันการลบรูปโปรไฟล์',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: NeoColors.inkSolid,
          ),
        ),
        content: const Text(
          'คุณต้องการลบรูปโปรไฟล์นี้หรือไม่? ระบบจะเปลี่ยนไปใช้ตัวอักษรแทน',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: NeoColors.subtleInk,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: NeoColors.mutedInk,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: NeoColors.errorText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text(
              'ลบรูปโปรไฟล์',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final oldKey = widget.profile.avatarObjectKey;
      await ref.read(studentProfileControllerProvider.notifier).deleteAvatar();
      if (oldKey != null) {
        ref.invalidate(studentAvatarBytesProvider(oldKey));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบรูปโปรไฟล์แล้ว')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userVisibleError(error)),
          backgroundColor: NeoColors.errorText,
        ),
      );
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรอกข้อมูลนี้';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final portfolioLinks = _links
        .where((l) => LinkPlatformHelper.platforms[l.platform]?.isUrl ?? false)
        .map(
          (l) => PortfolioLink(
            title: (l.label != null && l.label!.isNotEmpty)
                ? l.label!
                : (LinkPlatformHelper.platforms[l.platform]?.name ??
                      l.platform),
            url: l.value,
          ),
        )
        .toList();

    final firstUrl =
        _links
            .where(
              (l) => LinkPlatformHelper.platforms[l.platform]?.isUrl ?? false,
            )
            .map((l) => l.value)
            .firstOrNull ??
        widget.profile.portfolioUrl;

    final profile = StudentProfile(
      fullName: _nameController.text.trim(),
      university: _universityController.text.trim(),
      major: _majorController.text.trim(),
      skills: _skills,
      bio: _bioController.text.trim(),
      contactLinks: _links,
      portfolioLinks: portfolioLinks,
      portfolioUrl: firstUrl,
      resumeFileName: widget.profile.resumeFileName,
      resumeObjectKey: widget.profile.resumeObjectKey,
    );
    try {
      await ref.read(studentProfileControllerProvider.notifier).save(profile);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกโปรไฟล์แล้ว')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = userVisibleError(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
