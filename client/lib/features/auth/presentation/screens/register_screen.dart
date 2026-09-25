import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/auth_session.dart';
import '../providers/auth_controller.dart';
import '../widgets/widgets.dart';

/// Neo-Brutalist Register Screen refactored with clean reusable components.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _role = UserRole.student;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      setState(() {
        _error = 'กรุณายอมรับข้อกำหนดการให้บริการและนโยบายความเป็นส่วนตัว';
      });
      AppToast.warning(context, 'กรุณายอมรับข้อกำหนดการให้บริการ');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = await ref
        .read(authControllerProvider.notifier)
        .register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _role,
        );

    if (!mounted) return;

    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  void _showNotice(String message) {
    AppToast.info(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            const AuthTopBar(title: 'ลงทะเบียนสมาชิก'),

            // Scrollable Content
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 448),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Hero Section: Title + Rocket Badge
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: const TextSpan(
                                                style: TextStyle(
                                                  fontSize: 21,
                                                  fontWeight: FontWeight.w900,
                                                  color: NeoColors.inkSolid,
                                                  letterSpacing: -0.5,
                                                  fontFamily: 'Mitr',
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: 'เริ่มต้นกับ ',
                                                  ),
                                                  TextSpan(
                                                    text: 'InternMatch',
                                                    style: TextStyle(
                                                      color: NeoColors.inkSolid,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Gap(4),
                                            const Text(
                                              'ค้นหาและสมัครงานฝึกงานในฝันกับสตาร์ทอัพ\nและเทคคอมพานีชั้นนำ',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                height: 1.35,
                                                color: NeoColors.subtleInk,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Gap(12),
                                      const RocketBadge(),
                                    ],
                                  ),
                                  const Gap(18),

                                  // Role Segmented Switcher (Student / Company)
                                  RoleSegmentedToggle(
                                    selectedRole: _role,
                                    enabled: !_submitting,
                                    onRoleChanged: (role) =>
                                        setState(() => _role = role),
                                  ),
                                  const Gap(18),

                                  // Field 1: Name
                                  AuthTextField(
                                    controller: _nameController,
                                    label: 'ชื่อ - นามสกุล',
                                    isRequired: true,
                                    helperText: _role == UserRole.student
                                        ? 'ตรงตามบัตร/รหัสนักศึกษา'
                                        : 'ชื่อผู้ติดต่อ / บริษัท',
                                    hintText: _role == UserRole.student
                                        ? 'เช่น กวิน รัตนพงษ์'
                                        : 'เช่น บริษัท เทคสตาร์ท จำกัด',
                                    badgeColor: NeoColors.softLilac,
                                    badgeIcon: Icons.smart_toy_outlined,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'กรุณากรอกชื่อ - นามสกุล';
                                      }
                                      return null;
                                    },
                                  ),
                                  const Gap(14),

                                  // Field 2: University / Company Email
                                  AuthTextField(
                                    controller: _emailController,
                                    label: _role == UserRole.student
                                        ? 'อีเมลมหาวิทยาลัย'
                                        : 'อีเมลบริษัท',
                                    isRequired: true,
                                    keyboardType: TextInputType.emailAddress,
                                    hintText: _role == UserRole.student
                                        ? 'student@university.ac.th'
                                        : 'contact@company.com',
                                    badgeColor: NeoColors.butterYellow,
                                    badgeIcon: _role == UserRole.student
                                        ? Icons.school_outlined
                                        : Icons.mail_outline_rounded,
                                    validator: (value) {
                                      final email = value?.trim() ?? '';
                                      if (email.isEmpty) {
                                        return 'กรุณากรอกอีเมล';
                                      }
                                      if (!email.contains('@') ||
                                          !email.contains('.')) {
                                        return 'กรอกอีเมลให้ถูกต้อง';
                                      }
                                      return null;
                                    },
                                  ),
                                  const Gap(14),

                                  // Field 3: Password
                                  AuthTextField(
                                    controller: _passwordController,
                                    label: 'ตั้งรหัสผ่าน',
                                    isRequired: true,
                                    helperText: 'อย่างน้อย 8 ตัวอักษร',
                                    obscureText: _obscurePassword,
                                    hintText: 'รหัสผ่าน 8 ตัวอักษรขึ้นไป',
                                    badgeColor: NeoColors.skyBlue,
                                    badgeIcon: Icons.key_outlined,
                                    onChanged: (_) => setState(() {}),
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? 'แสดงรหัสผ่าน'
                                          : 'ซ่อนรหัสผ่าน',
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 20,
                                        color: NeoColors.inkSolid,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.length < 8) {
                                        return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                                      }
                                      return null;
                                    },
                                  ),
                                  const Gap(6),

                                  // Password Security Level Indicator
                                  PasswordStrengthBar(
                                    password: _passwordController.text,
                                  ),
                                  const Gap(14),

                                  // Field 4: Confirm Password
                                  AuthTextField(
                                    controller: _confirmPasswordController,
                                    label: 'ยืนยันรหัสผ่าน',
                                    isRequired: true,
                                    obscureText: _obscureConfirmPassword,
                                    hintText: 'กรอกรหัสผ่านอีกครั้ง',
                                    badgeColor: NeoColors.pastelCoral,
                                    badgeIcon: Icons.history_rounded,
                                    suffixIcon: IconButton(
                                      tooltip: _obscureConfirmPassword
                                          ? 'แสดงรหัสผ่าน'
                                          : 'ซ่อนรหัสผ่าน',
                                      onPressed: () => setState(
                                        () => _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                      ),
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 20,
                                        color: NeoColors.inkSolid,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'กรุณายืนยันรหัสผ่าน';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'รหัสผ่านทั้งสองช่องไม่ตรงกัน';
                                      }
                                      return null;
                                    },
                                  ),
                                  const Gap(16),

                                  // Terms and Privacy Policy Checkbox
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () => setState(
                                          () =>
                                              _agreedToTerms = !_agreedToTerms,
                                        ),
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          margin: const EdgeInsets.only(top: 2),
                                          decoration: BoxDecoration(
                                            color: _agreedToTerms
                                                ? NeoColors.inkSolid
                                                : NeoColors.pureWhite,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: NeoColors.inkSolid,
                                              width: 2.2,
                                            ),
                                          ),
                                          child: _agreedToTerms
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      ),
                                      const Gap(10),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: NeoColors.inkSolid,
                                              fontWeight: FontWeight.w600,
                                              height: 1.4,
                                            ),
                                            children: [
                                              const TextSpan(
                                                text: 'ฉันยอมรับ ',
                                              ),
                                              TextSpan(
                                                text: 'ข้อกำหนดการให้บริการ',
                                                style: const TextStyle(
                                                  color: Color(0xFF2563EB),
                                                  decoration:
                                                      TextDecoration.underline,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () => _showNotice(
                                                    'ข้อกำหนดการให้บริการ InternMatch',
                                                  ),
                                              ),
                                              const TextSpan(
                                                text: ' และรับทราบ ',
                                              ),
                                              TextSpan(
                                                text: 'นโยบายความเป็นส่วนตัว',
                                                style: const TextStyle(
                                                  color: Color(0xFF2563EB),
                                                  decoration:
                                                      TextDecoration.underline,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () => _showNotice(
                                                    'นโยบายความเป็นส่วนตัว InternMatch',
                                                  ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Server / Client Error Banner
                                  if (_error != null) ...[
                                    const Gap(14),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: NeoColors.errorBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: NeoColors.errorBorder,
                                          width: 1.8,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            size: 18,
                                            color: NeoColors.errorText,
                                          ),
                                          const Gap(8),
                                          Expanded(
                                            child: Text(
                                              _error!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: NeoColors.errorText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const Gap(18),

                                  // Submit Action Button
                                  NeoSubmitButton(
                                    text: 'สร้างบัญชีผู้ใช้',
                                    backgroundColor: NeoColors.freshMint,
                                    isLoading: _submitting,
                                    trailingIcon: const Icon(
                                      Icons.spa_outlined,
                                      size: 20,
                                      color: NeoColors.inkSolid,
                                    ),
                                    onTap: _submit,
                                  ),
                                  const Gap(20),

                                  // Divider
                                  const AuthDivider(text: 'หรือลงทะเบียนด้วย'),
                                  const Gap(16),

                                  // Social Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AuthSocialButton(
                                          label: 'Google',
                                          icon: const GoogleGIcon(),
                                          onTap: () => _showNotice(
                                            'การลงทะเบียนด้วย Google ยังไม่เปิดให้บริการ',
                                          ),
                                        ),
                                      ),
                                      const Gap(12),
                                      Expanded(
                                        child: AuthSocialButton(
                                          label: 'SSO มหาวิทยาลัย',
                                          icon: const SsoGridIcon(),
                                          onTap: () => _showNotice(
                                            'การลงทะเบียนด้วย SSO ยังไม่เปิดให้บริการ',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Gap(22),

                                  // Footer: มีบัญชีอยู่แล้ว? เข้าสู่ระบบ
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      const Text(
                                        'มีบัญชีอยู่แล้ว? ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: NeoColors.inkSolid,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _submitting
                                            ? null
                                            : () => context.go('/login'),
                                        child: const Text(
                                          'เข้าสู่ระบบ',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: NeoColors.inkSolid,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationThickness: 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
