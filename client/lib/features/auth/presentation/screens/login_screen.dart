import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_toast.dart';
import '../providers/auth_controller.dart';
import '../widgets/widgets.dart';

/// Neo-Brutalist Login Screen refactored with clean reusable components.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
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
            const AuthTopBar(title: 'เข้าสู่ระบบนักศึกษา'),

            // Centered Scrollable Content
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
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Main Neo-Brutalist Card
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: NeoColors.pureWhite,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: NeoColors.inkSolid,
                                        width: 2.5,
                                      ),
                                      boxShadow: NeoShadows.elevation3,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Email Field
                                        AuthTextField(
                                          controller: _emailController,
                                          label: 'อีเมลนักศึกษา / มหาวิทยาลัย',
                                          helperText:
                                              'รหัสนักศึกษาหรืออีเมลมหาวิทยาลัย',
                                          hintText: 'student@university.ac.th',
                                          badgeColor: NeoColors.softLilac,
                                          badgeIcon: Icons.school_outlined,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: (value) {
                                            final email = value?.trim() ?? '';
                                            if (email.isEmpty ||
                                                !email.contains('@') ||
                                                !email.contains('.')) {
                                              return 'กรอกอีเมลให้ถูกต้อง';
                                            }
                                            return null;
                                          },
                                        ),
                                        const Gap(14),

                                        // Password Field
                                        AuthTextField(
                                          controller: _passwordController,
                                          label: 'รหัสผ่าน',
                                          helperText: 'ลืมรหัส PIN?',
                                          onHelperTap: () => _showNotice(
                                            'ระบบรีเซ็ต PIN กำลังอยู่ระหว่างการพัฒนา',
                                          ),
                                          hintText: '••••••••••••',
                                          badgeColor: NeoColors.skyBlue,
                                          badgeIcon: Icons.lock_outline_rounded,
                                          obscureText: _obscurePassword,
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
                                                  : Icons
                                                        .visibility_off_outlined,
                                              size: 20,
                                              color: NeoColors.inkSolid,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'กรอกรหัสผ่าน';
                                            }
                                            if (value.length < 8) {
                                              return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                                            }
                                            return null;
                                          },
                                        ),
                                        const Gap(12),

                                        // Remember Me & Forgot Password Row
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: GestureDetector(
                                                onTap: () => setState(
                                                  () => _rememberMe =
                                                      !_rememberMe,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 18,
                                                      height: 18,
                                                      decoration: BoxDecoration(
                                                        color: _rememberMe
                                                            ? NeoColors
                                                                  .freshMint
                                                            : NeoColors
                                                                  .pureWhite,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              5,
                                                            ),
                                                        border: Border.all(
                                                          color: NeoColors
                                                              .inkSolid,
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      child: _rememberMe
                                                          ? const Icon(
                                                              Icons.check,
                                                              size: 14,
                                                              color: NeoColors
                                                                  .inkSolid,
                                                            )
                                                          : null,
                                                    ),
                                                    const Gap(8),
                                                    const Flexible(
                                                      child: Text(
                                                        'จดจำฉันไว้ในระบบ',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: NeoColors
                                                              .inkSolid,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => _showNotice(
                                                'ระบบรีเซ็ตรหัสผ่านยังไม่เปิดให้บริการ',
                                              ),
                                              child: const Text(
                                                'ลืมรหัสผ่าน?',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: NeoColors.subtleInk,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Error Banner
                                        if (_error != null) ...[
                                          const Gap(14),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: NeoColors.errorBg,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: NeoColors.errorBorder,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Text(
                                              _error!,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: NeoColors.errorText,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const Gap(16),

                                        // Login Action Button
                                        NeoSubmitButton(
                                          text: 'เข้าสู่ระบบ',
                                          backgroundColor:
                                              NeoColors.butterYellow,
                                          isLoading: _submitting,
                                          trailingIcon: const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 18,
                                            color: NeoColors.inkSolid,
                                          ),
                                          onTap: _submit,
                                        ),
                                        const Gap(18),

                                        // Divider
                                        const AuthDivider(
                                          text: 'หรือเข้าสู่ระบบด้วย',
                                        ),
                                        const Gap(14),

                                        // Social Buttons
                                        Row(
                                          children: [
                                            Expanded(
                                              child: AuthSocialButton(
                                                label: 'Google',
                                                icon: const GoogleGIcon(),
                                                onTap: () => _showNotice(
                                                  'ระบบเข้าสู่ระบบด้วย Google จะเปิดให้บริการในเร็วๆ นี้',
                                                ),
                                              ),
                                            ),
                                            const Gap(12),
                                            Expanded(
                                              child: AuthSocialButton(
                                                label: 'GitHub',
                                                icon: const GitHubIcon(),
                                                onTap: () => _showNotice(
                                                  'ระบบเข้าสู่ระบบด้วย GitHub จะเปิดให้บริการในเร็วๆ นี้',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Gap(18),

                                  // Register Member Prompt
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      const Text(
                                        'ยังไม่มีบัญชีผู้ใช้?',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: NeoColors.subtleInk,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _submitting
                                            ? null
                                            : () => context.go('/register'),
                                        child: const Text(
                                          'ลงทะเบียนสมาชิก',
                                          style: TextStyle(
                                            fontSize: 12.5,
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
                                  const Gap(12),

                                  // Partner Badge
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: NeoColors.onlineGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const Gap(6),
                                      const Flexible(
                                        child: Text(
                                          'เชื่อมต่อกับระบบมหาวิทยาลัยพันธมิตรกว่า 250+ แห่ง',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: NeoColors.subtleInk,
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
