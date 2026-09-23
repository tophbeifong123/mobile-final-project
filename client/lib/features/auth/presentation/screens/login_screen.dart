import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../providers/auth_controller.dart';

/// Neo-Brutalist Login Screen styled precisely after design-system.mdc and UI mockups.
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

    if (!mounted) {
      return;
    }
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF18181B),
          ),
        ),
        backgroundColor: const Color(0xFFFEF08A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF18181B), width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const inkSolid = Color(0xFF18181B);
    const paperCanvas = Color(0xFFFDF8EE);

    return Scaffold(
      backgroundColor: paperCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: inkSolid, width: 1.5),
                ),
              ),
              child: const Text(
                'เข้าสู่ระบบนักศึกษา',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: inkSolid,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    // Hero Logo Badge with Stickers
                    const Center(child: _HeroLogoBadge()),
                    const Gap(14),

                    // Greeting Header
                    const Text(
                      'ยินดีต้อนรับกลับมา!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: inkSolid,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Gap(4),
                    const Text(
                      'พร้อมค้นหาตำแหน่งฝึกงานใหม่ๆ วันนี้หรือยัง?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const Gap(18),

                    // Main Neo-Brutalist Form Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: inkSolid, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: inkSolid,
                            offset: Offset(3.5, 3.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email Field Label
                          const Row(
                            children: [
                              Icon(
                                Icons.mail_outline_rounded,
                                size: 15,
                                color: inkSolid,
                              ),
                              Gap(6),
                              Flexible(
                                child: Text(
                                  'อีเมลนักศึกษา / มหาวิทยาลัย',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: inkSolid,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),

                          // Email Input Box
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: inkSolid, width: 2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDDD6FE),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: inkSolid,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.school_outlined,
                                    size: 18,
                                    color: inkSolid,
                                  ),
                                ),
                                const Gap(10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: inkSolid,
                                    ),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      hintText: 'student@university.ac.th',
                                      hintStyle: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    validator: (value) {
                                      final email = value?.trim() ?? '';
                                      if (email.isEmpty ||
                                          !email.contains('@')) {
                                        return 'กรอกอีเมลให้ถูกต้อง';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(4),
                          const Text(
                            'รหัสนักศึกษาหรืออีเมลมหาวิทยาลัย',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const Gap(14),

                          // Password Field Label
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lock_outline_rounded,
                                      size: 15,
                                      color: inkSolid,
                                    ),
                                    Gap(6),
                                    Flexible(
                                      child: Text(
                                        'รหัสผ่าน',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: inkSolid,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showNotice('ระบบรีเซ็ต PIN กำลังอยู่ระหว่างการพัฒนา'),
                                child: const Text(
                                  'ลืมรหัส PIN?',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4B5563),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),

                          // Password Input Box
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: inkSolid, width: 2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFBAE6FD),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: inkSolid,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.key_outlined,
                                    size: 18,
                                    color: inkSolid,
                                  ),
                                ),
                                const Gap(10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    autofillHints: const [AutofillHints.password],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: inkSolid,
                                      letterSpacing: 2,
                                    ),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      hintText: '••••••••',
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF9CA3AF),
                                        letterSpacing: 2,
                                      ),
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'กรอกรหัสผ่าน';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: inkSolid,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 17,
                                      color: inkSolid,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(14),

                          // Remember Me & Forgot Password Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _rememberMe = !_rememberMe,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: _rememberMe
                                              ? const Color(0xFFA7F3D0)
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          border: Border.all(
                                            color: inkSolid,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: _rememberMe
                                            ? const Icon(
                                                Icons.check,
                                                size: 14,
                                                color: inkSolid,
                                              )
                                            : null,
                                      ),
                                      const Gap(8),
                                      const Flexible(
                                        child: Text(
                                          'จดจำฉันไว้ในระบบ',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: inkSolid,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Gap(8),
                              GestureDetector(
                                onTap: () => _showNotice(
                                  'ระบบลืมรหัสผ่านจะเปิดให้บริการในเร็วๆ นี้',
                                ),
                                child: const Text(
                                  'ลืมรหัสผ่าน?',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Error Display
                          if (_error != null) ...[
                            const Gap(12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFEF4444),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ],
                          const Gap(16),

                          // Login Action Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _submitting ? null : _submit,
                              borderRadius: BorderRadius.circular(14),
                              child: Ink(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF08A),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: inkSolid,
                                    width: 2.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: inkSolid,
                                      offset: Offset(3, 3),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _submitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: inkSolid,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'เข้าสู่ระบบ',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w900,
                                                color: inkSolid,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                            Gap(6),
                                            Icon(
                                              Icons.draw_outlined,
                                              size: 18,
                                              color: inkSolid,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const Gap(16),

                          // Divider with Pill
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              const Divider(
                                color: inkSolid,
                                thickness: 1.5,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: inkSolid,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Text(
                                  'หรือเข้าสู่ระบบด้วย',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: inkSolid,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Gap(14),

                          // Social Login Buttons (Google & GitHub)
                          Row(
                            children: [
                              Expanded(
                                child: _SocialButton(
                                  onTap: () => _showNotice('ระบบเข้าสู่ระบบด้วย Google จะเปิดให้บริการในเร็วๆ นี้'),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _GoogleGIcon(),
                                      Gap(6),
                                      Text(
                                        'Google',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: inkSolid,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: _SocialButton(
                                  onTap: () => _showNotice(
                                    'ระบบเข้าสู่ระบบด้วย GitHub จะเปิดให้บริการในเร็วๆ นี้',
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _GitHubIcon(),
                                      Gap(6),
                                      Text(
                                        'GitHub',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: inkSolid,
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
                    ),
                    const Gap(18),

                    // Register Member Prompt
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        const Text(
                          'ยังไม่มีบัญชีผู้ใช้?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDBA74),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: inkSolid, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: inkSolid,
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ลงทะเบียนสมาชิก',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: inkSolid,
                                  ),
                                ),
                                Gap(4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: inkSolid,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(14),

                    // Partner Universities Footer Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDF5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '✓ ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                'เชื่อมต่อกับระบบมหาวิทยาลัยพันธมิตรกว่า 250+ แห่ง',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero Logo Badge with chunky Neo-Brutalist stickers
class _HeroLogoBadge extends StatelessWidget {
  const _HeroLogoBadge();

  @override
  Widget build(BuildContext context) {
    const inkSolid = Color(0xFF18181B);

    return SizedBox(
      width: 100,
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Main Yellow Square
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF08A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: inkSolid, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: inkSolid,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              AppAssets.logo,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.rocket_launch_rounded,
                size: 38,
                color: inkSolid,
              ),
            ),
          ),

          // Top-right ★ PRO sticker
          Positioned(
            top: -4,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFA7F3D0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: inkSolid, width: 1.5),
              ),
              child: const Text(
                '★ PRO',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: inkSolid,
                ),
              ),
            ),
          ),

          // Bottom เวอร์ชัน 2.4 sticker
          Positioned(
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFDA4AF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: inkSolid, width: 1.5),
              ),
              child: const Text(
                'เวอร์ชัน 2.4',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: inkSolid,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Social Button with tactile Neo-Brutalist shadow
class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const inkSolid = Color(0xFF18181B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: inkSolid, width: 2),
            boxShadow: const [
              BoxShadow(
                color: inkSolid,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Colorful Google "G" icon
class _GoogleGIcon extends StatelessWidget {
  const _GoogleGIcon();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Color(0xFF4285F4),
      ),
    );
  }
}

/// GitHub Icon with tactile dark circular badge
class _GitHubIcon extends StatelessWidget {
  const _GitHubIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.terminal_rounded,
          size: 11,
          color: Colors.white,
        ),
      ),
    );
  }
}

