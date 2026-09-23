import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/auth_session.dart';
import '../providers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.student;
  String? _error;
  bool _submitting = false;
  bool _obscurePassword = true;

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
        .register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _role,
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'กลับ',
          onPressed: _submitting ? null : () => context.go('/login'),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: [
            Text('สร้างบัญชีใหม่', style: textTheme.headlineSmall),
            const Gap(8),
            Text(
              'เริ่มค้นหาที่ฝึกงาน หรือเปิดรับนักศึกษา',
              style: textTheme.bodyMedium,
            ),
            const Gap(20),
            Text('เลือกบทบาทของคุณ', style: textTheme.titleMedium),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: _RoleCard(
                    selected: _role == UserRole.student,
                    icon: LucideIcons.graduationCap,
                    title: 'นักศึกษา',
                    subtitle: 'กำลังมองหาที่ฝึกงาน',
                    onTap: _submitting
                        ? null
                        : () => setState(() => _role = UserRole.student),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _RoleCard(
                    selected: _role == UserRole.company,
                    icon: LucideIcons.building2,
                    title: 'บริษัท',
                    subtitle: 'เปิดรับสมัครนักศึกษา',
                    onTap: _submitting
                        ? null
                        : () => setState(() => _role = UserRole.company),
                  ),
                ),
              ],
            ),
            const Gap(20),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AppTextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    label: 'อีเมล',
                    hintText: 'name@example.com',
                    prefixIcon: const Icon(LucideIcons.mail, size: 18),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty || !email.contains('@')) {
                        return 'กรอกอีเมลให้ถูกต้อง';
                      }
                      return null;
                    },
                  ),
                  const Gap(16),
                  AppTextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    label: 'รหัสผ่าน',
                    hintText: '••••••••',
                    helperText: 'อย่างน้อย 8 ตัวอักษร',
                    prefixIcon: const Icon(LucideIcons.lock, size: 18),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: 18,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                      }
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const Gap(16),
                    Text(
                      _error!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.destructive,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                onPressed: _submitting ? null : _submit,
                isLoading: _submitting,
                isFullWidth: true,
                text: 'สร้างบัญชี',
              ),
              const Gap(4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('มีบัญชีอยู่แล้ว?', style: textTheme.bodyMedium),
                  TextButton(
                    onPressed: _submitting ? null : () => context.go('/login'),
                    child: const Text('เข้าสู่ระบบ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;

    return AppCard(
      onTap: onTap,
      borderColor: selected ? AppColors.primary : colors.border,
      borderWidth: selected ? 1.5 : 1,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : colors.mutedForeground,
                size: 22,
              ),
              const Spacer(),
              Icon(
                selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                color: selected ? AppColors.primary : colors.border,
                size: 20,
              ),
            ],
          ),
          const Gap(12),
          Text(title, style: textTheme.titleMedium),
          const Gap(4),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
