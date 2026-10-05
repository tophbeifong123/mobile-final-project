import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/provinces/thai_province.dart';
import '../../../../core/provinces/thai_province_picker.dart';
import '../../../../core/provinces/thai_provinces_provider.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/company_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/company_profile.dart';
import '../providers/company_profile_controller.dart';
import '../widgets/office_map_picker.dart';

class CompanyProfileScreen extends ConsumerWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(companyProfileControllerProvider);

    return Scaffold(
      appBar: const CompanyTopBar(title: 'โปรไฟล์บริษัท'),
      body: SafeArea(
        top: false,
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
  late final TextEditingController _locationController;

  int? _provinceId;
  String? _provinceName;
  double? _latitude;
  double? _longitude;

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
    _locationController = TextEditingController(text: profile.location);
    _provinceId = profile.provinceId;
    _provinceName = profile.provinceName;
    _latitude = profile.latitude;
    _longitude = profile.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessTypeController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final provinceAsync = _provinceId == null
        ? null
        : ref.watch(thaiProvincesProvider);
    final provinceList = provinceAsync?.asData?.value;
    ThaiProvince? province;
    if (provinceList != null && _provinceId != null) {
      for (final item in provinceList) {
        if (item.id == _provinceId) {
          province = item;
          break;
        }
      }
    }
    final pin = _latitude != null && _longitude != null
        ? LatLng(_latitude!, _longitude!)
        : null;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(kPagePadding),
        children: [
          Text(
            'ข้อมูลบริษัทและที่ตั้งสำนักงาน',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.mutedForeground,
            ),
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
          const Gap(20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ที่ตั้งสำนักงาน', style: textTheme.titleMedium),
                const Gap(4),
                Text(
                  'เลือกจังหวัดและใส่ที่อยู่แยกกัน แล้วปักหมุดจุดสำนักงาน',
                  style: textTheme.bodySmall,
                ),
                const Gap(14),
                Text('จังหวัด', style: textTheme.titleSmall),
                const Gap(6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('company-province-picker'),
                        onPressed: _pickProvince,
                        icon: const Icon(Icons.location_on_outlined),
                        label: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            province?.nameTh ?? _provinceName ?? 'เลือกจังหวัด',
                          ),
                        ),
                      ),
                    ),
                    if (_provinceId != null)
                      IconButton(
                        key: const Key('company-clear-province'),
                        tooltip: 'ล้างจังหวัดและหมุด',
                        onPressed: () => setState(() {
                          _provinceId = null;
                          _provinceName = null;
                          _latitude = null;
                          _longitude = null;
                        }),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                const Gap(12),
                AppTextField(
                  controller: _locationController,
                  label: 'ที่อยู่สำนักงาน (แบบสั้น)',
                  hintText: 'เช่น อาคาร A ถนนพระราม 1',
                  keyboardType: TextInputType.streetAddress,
                  maxLines: 2,
                  validator: _validateLocation,
                ),
                if (_provinceId != null) ...[
                  const Gap(14),
                  if (province != null)
                    OfficeMapPicker(
                      key: ValueKey('office-picker-${province.id}'),
                      province: province,
                      pin: pin,
                      onPinChanged: (position) => setState(() {
                        _latitude = position?.latitude;
                        _longitude = position?.longitude;
                      }),
                    )
                  else if (provinceAsync?.hasError ?? false)
                    TextButton(
                      onPressed: () => ref.invalidate(thaiProvincesProvider),
                      child: const Text('โหลดจังหวัดไม่สำเร็จ ลองใหม่'),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('กำลังโหลดแผนที่จังหวัด...'),
                    ),
                ],
              ],
            ),
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

  String? _validateLocation(String? value) {
    if ((value?.trim().length ?? 0) > 255) {
      return 'ที่อยู่ต้องไม่เกิน 255 ตัวอักษร';
    }
    return null;
  }

  void _applySavedProfile(CompanyProfile profile) {
    // Only a successful profile save replaces the draft. A logo upload also
    // updates the provider, but must leave in-progress form edits untouched.
    _nameController.text = profile.name;
    _businessTypeController.text = profile.businessType;
    _descriptionController.text = profile.description;
    _locationController.text = profile.location;
    _provinceId = profile.provinceId;
    _provinceName = profile.provinceName;
    _latitude = profile.latitude;
    _longitude = profile.longitude;
  }

  Future<void> _pickProvince() async {
    final selected = await showThaiProvincePicker(
      context,
      selectedProvinceId: _provinceId,
    );
    if (!mounted || selected == null) return;
    setState(() {
      if (_provinceId != selected.id) {
        // The previous office pin cannot silently move into another province.
        _latitude = null;
        _longitude = null;
      }
      _provinceId = selected.id;
      _provinceName = selected.nameTh;
      _error = null;
    });
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
    if ((_latitude != null || _longitude != null) && _provinceId == null) {
      setState(() => _error = 'เลือกจังหวัดก่อนบันทึกหมุดสำนักงาน');
      return;
    }
    if ((_latitude == null) != (_longitude == null)) {
      setState(() => _error = 'พิกัดสำนักงานไม่ครบ กรุณาปักหมุดใหม่');
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
      provinceId: _provinceId,
      provinceName: _provinceName,
      location: _locationController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
    );

    try {
      final saved = await ref
          .read(companyProfileControllerProvider.notifier)
          .save(updated);
      if (!mounted) return;
      setState(() => _applySavedProfile(saved));
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
