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
  late List<String> _skills;
  late final TextEditingController _portfolioController;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController = TextEditingController(text: profile.fullName);
    _universityController = TextEditingController(text: profile.university);
    _majorController = TextEditingController(text: profile.major);
    _skills = List<String>.from(profile.skills);
    _portfolioController = TextEditingController(
      text: profile.portfolioUrl ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Student Profile Card Hero
          StudentProfileHeroCard(
            profile: widget.profile,
            onAvatarTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('คุณสามารถเปลี่ยนรูปโปรไฟล์ได้เร็วๆ นี้ 📸'),
                ),
              );
            },
          ),
          const Gap(14),

          // Active Resume Card
          StudentProfileResumeCard(
            resumeFileName: widget.profile.resumeFileName,
          ),
          const Gap(14),

          // General Information Card
          StudentProfileInfoCard(
            nameController: _nameController,
            universityController: _universityController,
            majorController: _majorController,
            requiredValidator: _required,
          ),
          const Gap(14),

          // Skills Section Card
          StudentProfileSkillsCard(
            skills: _skills,
            onChanged: (updated) => setState(() => _skills = updated),
          ),
          const Gap(14),

          // Portfolio & Links Card
          StudentProfileLinksCard(
            controller: _portfolioController,
            validator: _portfolio,
          ),

          if (_error != null) ...[
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NeoColors.errorBg,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: NeoColors.errorBorder, width: 1.5),
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
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
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

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรอกข้อมูลนี้';
    }
    return null;
  }

  String? _portfolio(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    final allowed = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    if (!allowed) {
      return 'ใส่ลิงก์ที่ขึ้นต้นด้วย https://';
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
    final portfolio = _portfolioController.text.trim();
    final profile = StudentProfile(
      fullName: _nameController.text.trim(),
      university: _universityController.text.trim(),
      major: _majorController.text.trim(),
      skills: _skills,
      portfolioUrl: portfolio.isEmpty ? null : portfolio,
    );
    try {
      await ref.read(studentProfileControllerProvider.notifier).save(profile);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกโปรไฟล์แล้ว')),
      );
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
