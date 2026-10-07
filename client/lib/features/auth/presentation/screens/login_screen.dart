import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/auth_session.dart';
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

  Widget _roleChoiceButton(
    BuildContext dialogContext, {
    required String label,
    required UserRole role,
  }) {
    return SizedBox(
      width: 104,
      child: GestureDetector(
        onTap: () => Navigator.pop(dialogContext, role),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: NeoColors.butterYellow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NeoColors.inkSolid, width: 2),
            boxShadow: NeoShadows.elevation3,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: NeoColors.inkSolid,
            ),
          ),
        ),
      ),
    );
  }

  Future<UserRole?> _chooseGoogleRole() {
    return showDialog<UserRole>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            decoration: BoxDecoration(
              color: NeoColors.pureWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NeoColors.inkSolid, width: 2.5),
              boxShadow: NeoShadows.elevation3,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'เลือกประเภทบัญชี',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: NeoColors.inkSolid,
                  ),
                ),
                const Gap(8),
                const Text(
                  'เลือกบทบาทสำหรับบัญชีใหม่ บทบาทนี้เปลี่ยนภายหลังไม่ได้',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: NeoColors.subtleInk,
                  ),
                ),
                const Gap(20),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _roleChoiceButton(
                        context,
                        label: 'นักศึกษา',
                        role: UserRole.student,
                      ),
                      const Gap(12),
                      _roleChoiceButton(
                        context,
                        label: 'บริษัท',
                        role: UserRole.company,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onGoogleIdToken(String idToken) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    var result = await ref
        .read(authControllerProvider.notifier)
        .authenticateWithGoogle(idToken: idToken);
    if (mounted && result.roleRequired) {
      setState(() => _submitting = false);
      final role = await _chooseGoogleRole();
      if (role == null || !mounted) return;
      setState(() => _submitting = true);
      result = await ref
          .read(authControllerProvider.notifier)
          .authenticateWithGoogle(idToken: idToken, role: role);
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = result.error;
    });
  }

  void _openPasswordRecovery() {
    if (_submitting) return;
    context.go(
      Uri(
        path: '/forgot-password',
        queryParameters: _emailController.text.trim().isEmpty
            ? null
            : {'email': _emailController.text.trim()},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            const AuthTopBar(title: 'เข้าสู่ระบบ InternFinder'),

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
                                          label: 'อีเมล',
                                          helperText: 'อีเมลที่ใช้สมัครสมาชิก',
                                          hintText: 'you@example.com',
                                          badgeColor: NeoColors.softLilac,
                                          badgeIcon:
                                              Icons.alternate_email_rounded,
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
                                              onTap: _openPasswordRecovery,
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

                                        GoogleSignInButton(
                                          label: 'เข้าสู่ระบบด้วย Google',
                                          onIdToken: _onGoogleIdToken,
                                          onError: (message) {
                                            if (mounted) {
                                              setState(() {
                                                _submitting = false;
                                                _error = message;
                                              });
                                            }
                                          },
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
