import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

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
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/company_profile.dart';
import '../providers/company_profile_controller.dart';

class CompanyProfileScreen extends ConsumerWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(companyProfileControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const LoadingView(label: 'กำลังโหลดโปรไฟล์บริษัท'),
          error: (error, _) => _ProfileError(
            message: userVisibleError(error),
            onRetry: () => ref.invalidate(companyProfileControllerProvider),
          ),
          data: (profile) => _CompanyProfileForm(profile: profile),
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
            icon: Icons.business_outlined,
            title: 'โหลดโปรไฟล์บริษัทไม่ได้',
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

class _CompanyProfileForm extends ConsumerStatefulWidget {
  const _CompanyProfileForm({required this.profile});

  final CompanyProfile profile;

  @override
  ConsumerState<_CompanyProfileForm> createState() =>
      _CompanyProfileFormState();
}

class _CompanyProfileFormState extends ConsumerState<_CompanyProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _businessTypeController;
  late final TextEditingController _descriptionController;

  PlatformFile? _pickedLogoFile;
  bool _saving = false;
  bool _uploadingLogo = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController = TextEditingController(text: profile.name);
    _businessTypeController = TextEditingController(text: profile.businessType);
    _descriptionController = TextEditingController(text: profile.description);
  }

  @override
  void didUpdateWidget(covariant _CompanyProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      if (_nameController.text != widget.profile.name) {
        _nameController.text = widget.profile.name;
      }
      if (_businessTypeController.text != widget.profile.businessType) {
        _businessTypeController.text = widget.profile.businessType;
      }
      if (_descriptionController.text != widget.profile.description) {
        _descriptionController.text = widget.profile.description;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessTypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(kPagePadding),
        children: [
          const PageHeading(
            title: 'โปรไฟล์บริษัท',
            subtitle: 'ชื่อ โลโก้ ประเภทกิจการ และคำอธิบาย',
          ),
          const Gap(16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CompanyLogoAvatar(
                      name: widget.profile.name,
                      logoKey: widget.profile.logoObjectKey,
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('โลโก้บริษัท', style: textTheme.titleSmall),
                          const Gap(4),
                          Text(
                            widget.profile.logoObjectKey != null &&
                                    widget.profile.logoObjectKey!.isNotEmpty
                                ? 'มีโลโก้บริษัทแล้ว'
                                : 'ยังไม่มีโลโก้บริษัท',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.sm,
                      onPressed: _uploadingLogo ? null : _pickLogo,
                      text: widget.profile.logoObjectKey != null
                          ? 'เปลี่ยน'
                          : 'เลือกรูป',
                    ),
                  ],
                ),
                if (_pickedLogoFile != null) ...[
                  const Gap(12),
                  const Divider(height: 1),
                  const Gap(12),
                  Row(
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          _pickedLogoFile!.name,
                          style: textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Gap(8),
                      const StatusChip(label: 'พร้อมอัปโหลด'),
                      const Gap(8),
                      AppButton(
                        size: AppButtonSize.sm,
                        isLoading: _uploadingLogo,
                        onPressed: _uploadingLogo ? null : _uploadLogo,
                        text: 'อัปโหลด',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Gap(16),
          AppTextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            label: 'ชื่อบริษัท',
            hintText: 'กรอกชื่อบริษัท',
            prefixIcon: const Icon(Icons.business_outlined, size: 20),
            validator: _required,
          ),
          const Gap(12),
          AppTextField(
            controller: _businessTypeController,
            textInputAction: TextInputAction.next,
            label: 'ประเภทกิจการ',
            hintText: 'เช่น ซอฟต์แวร์, ค้าปลีก',
            prefixIcon: const Icon(Icons.category_outlined, size: 20),
            validator: _required,
          ),
          const Gap(12),
          AppTextField(
            controller: _descriptionController,
            label: 'คำอธิบายบริษัท',
            hintText: 'ข้อมูลเกี่ยวกับบริษัทหรือรายละเอียดเพิ่มเติม',
            maxLines: 4,
            prefixIcon: const Icon(Icons.description_outlined, size: 20),
          ),
          if (_error != null) ...[
            const Gap(12),
            Text(
              _error!,
              style: textTheme.bodyMedium?.copyWith(color: colors.destructive),
            ),
          ],
          const Gap(20),
          AppPrimaryButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'กำลังบันทึก' : 'บันทึกโปรไฟล์'),
          ),
          const Gap(8),
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

  Future<void> _pickLogo() async {
    setState(() => _error = null);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'svg'],
      );
      if (file == null) {
        return;
      }
      final ext = file.extension?.toLowerCase() ?? '';
      final allowed = ['png', 'jpg', 'jpeg', 'webp', 'svg'];
      if (!allowed.contains(ext) &&
          !allowed.any((e) => file.name.toLowerCase().endsWith('.$e'))) {
        setState(
          () =>
              _error = 'เลือกได้เฉพาะไฟล์รูปภาพเท่านั้น (PNG, JPG, WEBP, SVG)',
        );
        return;
      }
      setState(() => _pickedLogoFile = file);
    } catch (error) {
      setState(() => _error = userVisibleError(error));
    }
  }

  Future<void> _uploadLogo() async {
    final file = _pickedLogoFile;
    if (file == null) {
      return;
    }
    setState(() {
      _uploadingLogo = true;
      _error = null;
    });

    try {
      List<int>? bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        bytes = null;
      }

      final path = file.path;
      if ((path == null || path.isEmpty) && (bytes == null || bytes.isEmpty)) {
        setState(() => _error = 'เลือกไฟล์จากเครื่องเพื่ออัปโหลด');
        return;
      }

      await ref
          .read(companyProfileControllerProvider.notifier)
          .uploadLogo(filePath: path ?? '', fileName: file.name, bytes: bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('อัปโหลดโลโก้แล้ว')));
      setState(() => _pickedLogoFile = null);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = userVisibleError(error));
    } finally {
      if (mounted) {
        setState(() => _uploadingLogo = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final updated = CompanyProfile(
      name: _nameController.text.trim(),
      businessType: _businessTypeController.text.trim(),
      description: _descriptionController.text.trim(),
      logoObjectKey: widget.profile.logoObjectKey,
    );

    try {
      await ref.read(companyProfileControllerProvider.notifier).save(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกโปรไฟล์แล้ว')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = userVisibleError(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _CompanyLogoAvatar extends StatelessWidget {
  const _CompanyLogoAvatar({required this.name, required this.logoKey});

  final String name;
  final String? logoKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trimmed = name.trim();
    final letter = trimmed.isEmpty
        ? 'C'
        : trimmed.characters.first.toUpperCase();

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: logoKey != null ? AppColors.primary.withAlpha(25) : colors.muted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: logoKey != null
              ? AppColors.primary.withAlpha(80)
              : colors.border,
        ),
      ),
      child: Center(
        child: logoKey != null
            ? const Icon(Icons.business, color: AppColors.primary, size: 26)
            : Text(
                letter,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.mutedForeground,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
