import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/page_heading.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/student_profile.dart';
import '../providers/student_profile_controller.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(studentProfileControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: profile.when(
          loading: () => const LoadingView(label: 'กำลังโหลดโปรไฟล์'),
          error: (error, _) => _ProfileError(
            message: userVisibleError(error),
            onRetry: () => ref.invalidate(studentProfileControllerProvider),
          ),
          data: (value) => _ProfileForm(profile: value),
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
        TextButton(
          onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          child: const Text('ออกจากระบบ'),
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
  late final TextEditingController _skillsController;
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
    _skillsController = TextEditingController(text: profile.skills.join(', '));
    _portfolioController = TextEditingController(
      text: profile.portfolioUrl ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    _skillsController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(kPagePadding),
        children: [
          const PageHeading(
            title: 'โปรไฟล์',
            subtitle: 'ชื่อ มหาวิทยาลัย สาขา ทักษะ และ Portfolio',
          ),
          const Gap(16),
          AppTextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            label: 'ชื่อ',
            prefixIcon: const Icon(LucideIcons.user, size: 18),
            validator: _required,
          ),
          const Gap(12),
          AppTextField(
            controller: _universityController,
            textInputAction: TextInputAction.next,
            label: 'มหาวิทยาลัย',
            prefixIcon: const Icon(LucideIcons.graduationCap, size: 18),
            validator: _required,
          ),
          const Gap(12),
          AppTextField(
            controller: _majorController,
            textInputAction: TextInputAction.next,
            label: 'สาขา',
            prefixIcon: const Icon(LucideIcons.bookOpen, size: 18),
            validator: _required,
          ),
          const Gap(12),
          AppTextField(
            controller: _skillsController,
            textInputAction: TextInputAction.next,
            label: 'ทักษะ',
            hintText: 'คั่นด้วยจุลภาค เช่น Flutter, SQL',
            prefixIcon: const Icon(LucideIcons.sparkles, size: 18),
          ),
          const Gap(12),
          AppTextField(
            controller: _portfolioController,
            keyboardType: TextInputType.url,
            label: 'Portfolio',
            hintText: 'https://',
            prefixIcon: const Icon(LucideIcons.link, size: 18),
            validator: _portfolio,
          ),
          const Gap(16),
          AppCard(
            child: Row(
              children: [
                Icon(
                  LucideIcons.fileText,
                  color: widget.profile.resumeFileName != null
                      ? AppColors.primary
                      : colors.mutedForeground,
                  size: 24,
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resume',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Gap(2),
                      Text(
                        widget.profile.resumeFileName ??
                            'ยังไม่มี Resume ในระบบ',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: widget.profile.resumeFileName != null
                                      ? null
                                      : colors.mutedForeground,
                                ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/student/resume'),
                  child: Text(
                    widget.profile.resumeFileName != null
                        ? 'เปลี่ยน'
                        : 'อัปโหลด',
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const Gap(12),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.destructive,
              ),
            ),
          ],
          const Gap(16),
          AppPrimaryButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'กำลังบันทึก' : 'บันทึกโปรไฟล์'),
          ),
          TextButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            child: const Text('ออกจากระบบ'),
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
    final allowed =
        uri != null &&
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
      skills: _skillsController.text
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty)
          .toList(),
      portfolioUrl: portfolio.isEmpty ? null : portfolio,
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
