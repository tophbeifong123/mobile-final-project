import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/password_recovery_email_policy.dart';
import '../../domain/entities/password_recovery_exception.dart';
import '../providers/password_recovery_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/neo_submit_button.dart';
import '../widgets/password_recovery_layout.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _sent = false;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _submit() async {
    if (_cooldownSeconds > 0 || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final sent = await ref
        .read(forgotPasswordControllerProvider.notifier)
        .requestPasswordReset(_emailController.text.trim());
    if (!mounted) return;
    if (sent) {
      setState(() => _sent = true);
      _startCooldown(60);
    } else {
      final error = ref.read(forgotPasswordControllerProvider).error;
      if (error is PasswordRecoveryException &&
          error.retryAfterSeconds != null) {
        _startCooldown(error.retryAfterSeconds!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(forgotPasswordControllerProvider);
    return PasswordRecoveryLayout(
      title: 'กู้คืนบัญชี',
      heading: 'ลืมรหัสผ่านใช่ไหม?',
      description:
          'กรอกอีเมลที่ใช้สมัครสมาชิก ไม่ว่าจะเป็น Gmail, Outlook หรืออีเมลอื่น ๆ ระบบจะส่งลิงก์ตั้งรหัสผ่านใหม่ไปยังอีเมลนั้น',
      icon: Icons.mark_email_unread_outlined,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              controller: _emailController,
              label: 'อีเมลที่ใช้สมัครสมาชิก',
              hintText: 'you@example.com',
              badgeColor: NeoColors.skyBlue,
              badgeIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              enabled: !request.isLoading,
              onChanged: (_) {
                if (_sent) setState(() => _sent = false);
              },
              validator: PasswordRecoveryEmailPolicy.validate,
            ),
            const Gap(20),
            if (_sent) ...[
              const PasswordRecoveryFeedback(
                message:
                    'หากอีเมลนี้มีบัญชีอยู่ ระบบจะส่งลิงก์รีเซ็ตรหัสผ่านให้คุณ',
              ),
              const Gap(12),
              const Text(
                'ตรวจสอบกล่องจดหมายและโฟลเดอร์สแปมของอีเมลที่ใช้สมัครสมาชิก แล้วเปิดลิงก์ในอีเมลเพื่อตั้งรหัสผ่านใหม่',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: NeoColors.subtleInk,
                ),
              ),
              const Gap(20),
            ],
            if (request.hasError) ...[
              PasswordRecoveryFeedback(
                message: userVisibleError(request.error!),
                isError: true,
              ),
              const Gap(20),
            ],
            NeoSubmitButton(
              text: _cooldownSeconds > 0
                  ? 'ส่งอีกครั้งใน $_cooldownSeconds วินาที'
                  : (_sent ? 'ส่งลิงก์อีกครั้ง' : 'ส่งลิงก์รีเซ็ตรหัสผ่าน'),
              backgroundColor: NeoColors.butterYellow,
              isLoading: request.isLoading,
              onTap: _cooldownSeconds > 0 ? null : _submit,
            ),
            const Gap(16),
            TextButton.icon(
              onPressed: request.isLoading ? null : () => context.go('/login'),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('กลับไปเข้าสู่ระบบ'),
            ),
          ],
        ),
      ),
    );
  }
}
