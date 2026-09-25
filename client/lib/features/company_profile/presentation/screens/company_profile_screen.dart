import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/company_profile.dart';
import '../providers/company_profile_controller.dart';

class CompanyProfileScreen extends ConsumerWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(companyProfileControllerProvider);

    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
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
            action: NeoButton(
              variant: NeoButtonVariant.secondary,
              height: 38,
              onPressed: onRetry,
              text: 'ลองอีกครั้ง',
            ),
          ),
        ),
        TextButton(
          onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          child: const Text(
            'ออกจากระบบ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: NeoColors.errorText,
            ),
          ),
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
  late final TextEditingController _websiteUrlController;
  late final TextEditingController _locationController;
  late final TextEditingController _newPerkController;

  late String _selectedCompanySize;
  late List<String> _perks;

  bool _saving = false;
  bool _uploadingLogo = false;
  bool _uploadingCover = false;
  bool _showSavedToast = false;
  String? _error;

  static const List<String> _companySizes = [
    '1-50',
    '51-200',
    '201-500',
    '500+',
  ];

  static const List<String> _presetIndustries = [
    'ฟินเทค & บล็อกเชน (FinTech / Blockchain)',
    'ซอฟต์แวร์ & ไอที (Software & IT Solutions)',
    'อีคอมเมิร์ซ & ค้าปลีก (E-Commerce)',
    'เอเจนซี่การตลาด & ดิจิทัลมีเดีย (Agency & Media)',
    'ปัญญาประดิษฐ์ & ข้อมูล (AI & Big Data)',
    'พลังงาน & สิ่งแวดล้อม (Energy & Environment)',
    'การศึกษา (EdTech)',
    'อื่นๆ (Other)',
  ];

  static const List<Color> _perkTagColors = [
    NeoColors.butterYellow,
    NeoColors.freshMint,
    NeoColors.skyBlue,
    NeoColors.softLilac,
    NeoColors.pastelCoral,
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p.name);
    _businessTypeController = TextEditingController(text: p.businessType);
    _descriptionController = TextEditingController(text: p.description);
    _websiteUrlController = TextEditingController(text: p.websiteUrl);
    _locationController = TextEditingController(text: p.location);
    _newPerkController = TextEditingController();

    _selectedCompanySize = p.companySize.isNotEmpty ? p.companySize : '51-200';
    _perks = List<String>.from(p.perks);
  }

  @override
  void didUpdateWidget(covariant _CompanyProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      final p = widget.profile;
      if (_nameController.text != p.name) _nameController.text = p.name;
      if (_businessTypeController.text != p.businessType) {
        _businessTypeController.text = p.businessType;
      }
      if (_descriptionController.text != p.description) {
        _descriptionController.text = p.description;
      }
      if (_websiteUrlController.text != p.websiteUrl) {
        _websiteUrlController.text = p.websiteUrl;
      }
      if (_locationController.text != p.location) {
        _locationController.text = p.location;
      }
      if (p.companySize.isNotEmpty && _selectedCompanySize != p.companySize) {
        _selectedCompanySize = p.companySize;
      }
      _perks = List<String>.from(p.perks);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessTypeController.dispose();
    _descriptionController.dispose();
    _websiteUrlController.dispose();
    _locationController.dispose();
    _newPerkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(),
                const Gap(14),
                _buildCoverAndAvatarSection(),
                const Gap(16),
                _buildHeaderTitleSection(),
                const Gap(16),
                _buildGeneralInfoCard(),
                const Gap(16),
                _buildLocationCard(),
                const Gap(16),
                _buildCultureCard(),
                const Gap(16),
                _buildPerksCard(),
                if (_error != null) ...[const Gap(12), _buildErrorBox(_error!)],
                const Gap(24),
                _buildActionButtons(),
                const Gap(32),
              ],
            ),
          ),
          if (_showSavedToast)
            Positioned(top: 16, left: 20, right: 20, child: _buildSavedToast()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: NeoColors.butterYellow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NeoColors.inkSolid, width: 2.5),
                boxShadow: NeoShadows.elevation1,
              ),
              child: const Icon(
                Icons.corporate_fare,
                size: 22,
                color: NeoColors.inkSolid,
              ),
            ),
            const Gap(10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'InternFinder',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.inkSolid,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'FOR BUSINESS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.electricIndigo,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: NeoColors.surfaceCream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NeoColors.inkSolid, width: 2.5),
            boxShadow: NeoShadows.elevation1,
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.notifications_outlined,
                  size: 22,
                  color: NeoColors.inkSolid,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: NeoColors.electricIndigo,
                    shape: BoxShape.circle,
                    border: Border.all(color: NeoColors.inkSolid, width: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverAndAvatarSection() {
    final coverKey = widget.profile.coverObjectKey;
    final coverBytesAsync = ref.watch(companyCoverBytesProvider(coverKey));

    return Column(
      children: [
        // Cover Banner
        Container(
          width: double.infinity,
          height: 144,
          decoration: BoxDecoration(
            color: NeoColors.butterYellow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NeoColors.inkSolid, width: 2.5),
            boxShadow: NeoShadows.elevation2,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (coverBytesAsync.value != null &&
                  coverBytesAsync.value!.isNotEmpty)
                Image.memory(
                  Uint8List.fromList(coverBytesAsync.value!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        NeoColors.butterYellow,
                        NeoColors.pastelCoral.withValues(alpha: 0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.apartment_rounded,
                      size: 64,
                      color: NeoColors.inkSolid.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _uploadingCover ? null : _pickAndUploadCover,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: NeoColors.surfaceCream,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NeoColors.inkSolid, width: 2),
                      boxShadow: NeoShadows.elevation1,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_uploadingCover)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: NeoColors.inkSolid,
                            ),
                          )
                        else
                          const Icon(
                            Icons.photo_camera_outlined,
                            size: 15,
                            color: NeoColors.inkSolid,
                          ),
                        const Gap(5),
                        const Text(
                          'เปลี่ยนรูปหน้าปก',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: NeoColors.inkSolid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Overlapping Avatar and Verified Partner pill
        Transform.translate(
          offset: const Offset(0, -38),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLogoAvatarWidget(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: NeoColors.freshMint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                    boxShadow: NeoShadows.elevation1,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: NeoColors.inkSolid,
                      ),
                      Gap(4),
                      Text(
                        'VERIFIED PARTNER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.inkSolid,
                          letterSpacing: 0.2,
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
    );
  }

  Widget _buildLogoAvatarWidget() {
    final logoKey = widget.profile.logoObjectKey;
    final logoBytesAsync = ref.watch(companyLogoBytesProvider(logoKey));
    final trimmedName = widget.profile.name.trim();
    final letter = trimmedName.isNotEmpty
        ? trimmedName.characters.first.toUpperCase()
        : 'C';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: NeoColors.freshMint.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: NeoColors.inkSolid, width: 3),
            boxShadow: NeoShadows.elevation2,
          ),
          clipBehavior: Clip.antiAlias,
          child:
              logoBytesAsync.value != null && logoBytesAsync.value!.isNotEmpty
              ? Image.memory(
                  Uint8List.fromList(logoBytesAsync.value!),
                  fit: BoxFit.cover,
                  width: 80,
                  height: 80,
                )
              : Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: NeoColors.inkSolid,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: NeoColors.freshMint,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        Positioned(
          bottom: -3,
          right: -3,
          child: GestureDetector(
            onTap: _uploadingLogo ? null : _pickAndUploadLogo,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: NeoColors.butterYellow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NeoColors.inkSolid, width: 2),
                boxShadow: NeoShadows.elevation1,
              ),
              child: Center(
                child: _uploadingLogo
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: NeoColors.inkSolid,
                        ),
                      )
                    : const Icon(
                        Icons.add_a_photo_outlined,
                        size: 15,
                        color: NeoColors.inkSolid,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.profile.name.isNotEmpty
                    ? widget.profile.name
                    : 'โปรไฟล์บริษัท',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: NeoColors.inkSolid,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ],
        ),
        const Gap(4),
        const Text(
          'จัดการข้อมูลองค์กร เพื่อสร้างความน่าเชื่อถือและดึงดูดผู้สมัครคุณภาพสูง',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: NeoColors.subtleInk,
          ),
        ),
      ],
    );
  }

  Widget _buildCardShell({
    required Color iconBg,
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailingHeader,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: NeoColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoColors.inkSolid, width: 2.5),
        boxShadow: NeoShadows.elevation2,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: NeoColors.inkSolid,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(icon, size: 16, color: NeoColors.inkSolid),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.inkSolid,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ?trailingHeader,
            ],
          ),
          const Gap(10),
          const Divider(color: NeoColors.inkSolid, height: 1, thickness: 1.5),
          const Gap(14),
          child,
        ],
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    return _buildCardShell(
      iconBg: NeoColors.butterYellow,
      icon: Icons.domain_rounded,
      title: 'ข้อมูลทั่วไปของบริษัท',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(label: 'ชื่อบริษัท / องค์กร', isRequired: true),
          const Gap(4),
          _buildTextInput(
            controller: _nameController,
            hint: 'Bitkub Online Co., Ltd.',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'กรอกข้อมูลนี้' : null,
          ),
          const Gap(12),
          _buildFieldLabel(
            label: 'กลุ่มอุตสาหกรรม (Industry)',
            isRequired: true,
          ),
          const Gap(4),
          _buildIndustrySelector(),
          const Gap(14),
          _buildFieldLabel(label: 'ขนาดองค์กร (Company Size)'),
          const Gap(6),
          _buildCompanySizeGrid(),
          const Gap(12),
          _buildFieldLabel(label: 'เว็บไซต์ทางการ (Website URL)'),
          const Gap(4),
          _buildTextInput(
            controller: _websiteUrlController,
            hint: 'https://www.bitkub.com',
            prefixIcon: Icons.language,
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  Widget _buildIndustrySelector() {
    final currentVal = _businessTypeController.text.trim();
    final String selectedValue;
    if (_presetIndustries.contains(currentVal)) {
      selectedValue = currentVal;
    } else {
      final match = _presetIndustries.firstWhere(
        (e) =>
            currentVal.isNotEmpty &&
            e.toLowerCase().contains(currentVal.toLowerCase()),
        orElse: () => 'อื่นๆ (Other)',
      );
      selectedValue = match;
    }
    final isCustom = selectedValue == 'อื่นๆ (Other)';

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: NeoColors.paperCanvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NeoColors.inkSolid, width: 2),
            boxShadow: NeoShadows.elevation1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedValue,
              icon: const Icon(
                Icons.arrow_drop_down_rounded,
                color: NeoColors.inkSolid,
                size: 26,
              ),
              items: _presetIndustries.map((ind) {
                return DropdownMenuItem<String>(
                  value: ind,
                  child: Text(
                    ind,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: NeoColors.inkSolid,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  if (val == 'อื่นๆ (Other)') {
                    _businessTypeController.text = '';
                  } else {
                    _businessTypeController.text = val;
                  }
                });
              },
            ),
          ),
        ),
        if (isCustom || currentVal.isEmpty) ...[
          const Gap(8),
          _buildTextInput(
            controller: _businessTypeController,
            hint: 'ระบุกลุ่มอุตสาหกรรม เช่น ซอฟต์แวร์, ค้าปลีก',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'กรอกข้อมูลนี้' : null,
          ),
        ],
      ],
    );
  }

  Widget _buildCompanySizeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 42,
      ),
      itemCount: _companySizes.length,
      itemBuilder: (context, index) {
        final size = _companySizes[index];
        final isSelected =
            _selectedCompanySize.startsWith(size) ||
            _selectedCompanySize == size;
        final displayText = size == '500+'
            ? '500+ คน (Enterprise)'
            : '$size คน';

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCompanySize = size;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? NeoColors.butterYellow
                  : NeoColors.paperCanvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeoColors.inkSolid, width: 2),
              boxShadow: isSelected
                  ? NeoShadows.elevation2
                  : NeoShadows.elevation1,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              isSelected ? '✓ $displayText' : displayText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: NeoColors.inkSolid,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationCard() {
    return _buildCardShell(
      iconBg: NeoColors.skyBlue,
      icon: Icons.location_on_rounded,
      title: 'สถานที่ฝึกงาน & การเดินทาง',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(label: 'ที่ตั้งสำนักงาน (Office Address)'),
          const Gap(4),
          _buildTextInput(
            controller: _locationController,
            hint: 'FYI Center อาคาร 2 ชั้น 11 ถนนรัชดาภิเษก คลองเตย กรุงเทพฯ',
            maxLines: 3,
          ),
          const Gap(12),
          // Transit preview pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: NeoColors.surfaceCream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeoColors.inkSolid, width: 1.5),
              boxShadow: NeoShadows.elevation1,
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.train_rounded,
                  size: 18,
                  color: NeoColors.electricIndigo,
                ),
                Gap(8),
                Expanded(
                  child: Text(
                    'ใกล้สถานีรถไฟฟ้า MRT / BTS จุดเชื่อมต่อการเดินทางสะดวก',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: NeoColors.inkSolid,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCultureCard() {
    return _buildCardShell(
      iconBg: NeoColors.softLilac,
      icon: Icons.lightbulb_outline_rounded,
      title: 'เกี่ยวกับและวัฒนธรรมองค์กร',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(label: 'เรื่องราวบริษัท (About & Culture)'),
          const Gap(4),
          _buildTextInput(
            controller: _descriptionController,
            hint:
                'บริษัทผู้นำด้านเทคโนโลยี เรามุ่งมั่นพัฒนาคนรุ่นใหม่ สนับสนุนให้นักศึกษาได้ลงมือทำจริง...',
            maxLines: 4,
          ),
          const Gap(14),
          _buildFieldLabel(label: 'บรรยากาศการทำงานจริง (Life at Office)'),
          const Gap(6),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: NeoColors.freshMint.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NeoColors.inkSolid, width: 2),
                    boxShadow: NeoShadows.elevation1,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.groups_rounded,
                        size: 26,
                        color: NeoColors.inkSolid,
                      ),
                      Gap(4),
                      Text(
                        'Team & Collab',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: NeoColors.inkSolid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: NeoColors.butterYellow.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NeoColors.inkSolid, width: 2),
                    boxShadow: NeoShadows.elevation1,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.coffee_rounded,
                        size: 26,
                        color: NeoColors.inkSolid,
                      ),
                      Gap(4),
                      Text(
                        'Pantry & Snacks',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: NeoColors.inkSolid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerksCard() {
    return _buildCardShell(
      iconBg: NeoColors.pastelCoral,
      icon: Icons.celebration_rounded,
      title: 'สวัสดิการเด็กฝึกงาน',
      trailingHeader: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: NeoColors.paperCanvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NeoColors.inkSolid, width: 1.5),
        ),
        child: Text(
          '${_perks.length} แท็ก',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: NeoColors.subtleInk,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_perks.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_perks.length, (index) {
                final perk = _perks[index];
                final color = _perkTagColors[index % _perkTagColors.length];

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NeoColors.inkSolid, width: 2),
                    boxShadow: NeoShadows.elevation1,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        perk,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: NeoColors.inkSolid,
                        ),
                      ),
                      const Gap(6),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _perks.removeAt(index);
                          });
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: NeoColors.inkSolid,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            )
          else
            const Text(
              'ยังไม่มีการระบุสวัสดิการพิเศษ เพิ่มแท็กเพื่อดึงดูดผู้สมัคร',
              style: TextStyle(
                fontSize: 12,
                color: NeoColors.mutedInk,
                fontStyle: FontStyle.italic,
              ),
            ),
          const Gap(12),
          // Add perk input row
          Row(
            children: [
              Expanded(
                child: _buildTextInput(
                  controller: _newPerkController,
                  hint: 'เช่น วันหยุดพิเศษ, คลาสเรียนฟรี...',
                  onSubmitted: (_) => _addNewPerk(),
                ),
              ),
              const Gap(8),
              NeoButton(
                variant: NeoButtonVariant.surface,
                height: 44,
                onPressed: _addNewPerk,
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: NeoColors.inkSolid,
                ),
                text: 'เพิ่ม',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addNewPerk() {
    final text = _newPerkController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _perks.add(text);
      _newPerkController.clear();
    });
  }

  Widget _buildFieldLabel({required String label, bool isRequired = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: NeoColors.inkSolid,
            ),
          ),
        ),
        if (isRequired) ...[
          const Gap(8),
          const Text(
            '*จำเป็น',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: NeoColors.errorText,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: NeoColors.inkSolid,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: NeoColors.mutedInk,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: NeoColors.subtleInk)
            : null,
        filled: true,
        fillColor: NeoColors.paperCanvas,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NeoColors.inkSolid, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NeoColors.inkSolid, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: NeoColors.electricIndigo,
            width: 2.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NeoColors.errorBorder, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NeoColors.errorBorder, width: 2),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        NeoButton(
          variant: NeoButtonVariant.secondary,
          isFullWidth: true,
          height: 54,
          isLoading: _saving,
          onPressed: _saving ? null : _save,
          icon: const Icon(
            Icons.save_rounded,
            size: 22,
            color: NeoColors.inkSolid,
          ),
          text: 'บันทึกโปรไฟล์',
        ),
        const Gap(8),
        const Text(
          'การเปลี่ยนแปลงจะมีผลต่อประกาศรับสมัครงานทุกตำแหน่งขององค์กรทันที',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: NeoColors.subtleInk,
          ),
          textAlign: TextAlign.center,
        ),
        const Gap(16),
        TextButton(
          onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          child: const Text(
            'ออกจากระบบ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: NeoColors.errorText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedToast() {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: NeoColors.freshMint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NeoColors.inkSolid, width: 2.5),
          boxShadow: NeoShadows.elevation3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: NeoColors.inkSolid,
              size: 22,
            ),
            const Gap(8),
            const Flexible(
              child: Text(
                'บันทึกข้อมูลเรียบร้อยแล้ว! 🎉',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: NeoColors.inkSolid,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Gap(8),
            GestureDetector(
              onTap: () => setState(() => _showSavedToast = false),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: NeoColors.inkSolid,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NeoColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeoColors.errorBorder, width: 2),
      ),
      child: Text(
        msg,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: NeoColors.errorText,
        ),
      ),
    );
  }

  Future<void> _pickAndUploadLogo() async {
    setState(() => _error = null);
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
        setState(
          () => _error = 'เลือกได้เฉพาะไฟล์รูปภาพ (PNG, JPG, WEBP, SVG)',
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
        setState(() => _error = 'ไม่สามารถอ่านไฟล์รูปภาพได้');
        return;
      }

      setState(() => _uploadingLogo = true);
      final updated = await ref
          .read(companyProfileControllerProvider.notifier)
          .uploadLogo(filePath: path ?? '', fileName: file.name, bytes: bytes);

      ref.invalidate(companyLogoBytesProvider(updated.logoObjectKey));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('อัปโหลดโลโก้แล้ว')));
    } catch (err) {
      if (!mounted) return;
      setState(() => _error = userVisibleError(err));
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _pickAndUploadCover() async {
    setState(() => _error = null);
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
        setState(
          () => _error = 'เลือกได้เฉพาะไฟล์รูปภาพ (PNG, JPG, WEBP, SVG)',
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
        setState(() => _error = 'ไม่สามารถอ่านไฟล์รูปภาพได้');
        return;
      }

      setState(() => _uploadingCover = true);
      final updated = await ref
          .read(companyProfileControllerProvider.notifier)
          .uploadCover(filePath: path ?? '', fileName: file.name, bytes: bytes);

      ref.invalidate(companyCoverBytesProvider(updated.coverObjectKey));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปเดตรูปหน้าปกสำเร็จแล้ว 📸')),
      );
    } catch (err) {
      if (!mounted) return;
      setState(() => _error = userVisibleError(err));
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
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

    final updated = widget.profile.copyWith(
      name: _nameController.text.trim(),
      businessType: _businessTypeController.text.trim(),
      description: _descriptionController.text.trim(),
      websiteUrl: _websiteUrlController.text.trim(),
      location: _locationController.text.trim(),
      companySize: _selectedCompanySize,
      perks: _perks,
    );

    try {
      await ref.read(companyProfileControllerProvider.notifier).save(updated);
      if (!mounted) return;
      setState(() => _showSavedToast = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกโปรไฟล์แล้ว')));
    } catch (err) {
      if (!mounted) return;
      setState(() => _error = userVisibleError(err));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
