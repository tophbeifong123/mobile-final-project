import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/password_recovery_exception.dart';
import '../../domain/entities/registration_password_policy.dart';
import '../providers/password_recovery_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/neo_submit_button.dart';
import '../widgets/password_recovery_layout.dart';
import '../widgets/registration_password_checklist.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _complete = false;
  bool _attemptedSubmit = false;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  RegistrationPasswordPolicy get _passwordPolicy => RegistrationPasswordPolicy(
    _passwordController.text,
    _confirmationController.text,
  );

  bool get _validToken =>
      RegExp(r'^[a-f0-9]{64}$').hasMatch(widget.token ?? '');

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _attemptedSubmit = true);
    if (_cooldownSeconds > 0 ||
        !_validToken ||
        !_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    final complete = await ref
        .read(resetPasswordControllerProvider.notifier)
        .resetPassword(widget.token!, _passwordController.text);
    if (!mounted) return;
    if (complete) {
      _passwordController.clear();
      _confirmationController.clear();
      setState(() => _complete = true);
      // Remove the one-use secret from the browser URL after a successful reset.
      context.replace('/reset-password');
    } else {
      final error = ref.read(resetPasswordControllerProvider).error;
      if (error is PasswordRecoveryException &&
          error.retryAfterSeconds != null) {
        _cooldownTimer?.cancel();
        setState(() => _cooldownSeconds = error.retryAfterSeconds!);
        _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() => _cooldownSeconds--);
          if (_cooldownSeconds <= 0) timer.cancel();
        });
      }
    }
  }

  Widget _visibilityButton(bool obscure, VoidCallback toggle) => IconButton(
    tooltip: obscure ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
    onPressed: toggle,
    icon: Icon(
      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      size: 20,
      color: NeoColors.inkSolid,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(resetPasswordControllerProvider);
    final error = request.error;
    final invalidLink =
        !_validToken ||
        (error is PasswordRecoveryException && error.invalidLink);
    return PasswordRecoveryLayout(
      title: 'ตั้งรหัสผ่านใหม่',
      heading: _complete ? 'เรียบร้อยแล้ว!' : 'เริ่มต้นใหม่ได้เลย',
      description: _complete
          ? 'รหัสผ่านของคุณได้รับการเปลี่ยนแล้ว ใช้รหัสผ่านใหม่เพื่อเข้าสู่ระบบ'
          : 'เลือกรหัสผ่านใหม่ที่มีอย่างน้อย 8 ตัวอักษร ต้องไม่ซ้ำกับรหัสผ่านเดิม และไม่ควรใช้รหัสผ่านเดียวกับบัญชีอื่น',
      icon: _complete ? Icons.verified_outlined : Icons.lock_reset_rounded,
      child: _complete
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PasswordRecoveryFeedback(
                  message:
                      'ตั้งรหัสผ่านใหม่เรียบร้อยแล้ว กรุณาเข้าสู่ระบบอีกครั้ง',
                ),
                const Gap(24),
                NeoSubmitButton(
                  text: 'เข้าสู่ระบบด้วยรหัสผ่านใหม่',
                  backgroundColor: NeoColors.butterYellow,
                  onTap: () => context.go('/login'),
                ),
              ],
            )
          : invalidLink
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PasswordRecoveryFeedback(
                  message:
                      'ลิงก์รีเซ็ตรหัสผ่านไม่ถูกต้องหรือหมดอายุแล้ว กรุณาขอลิงก์ใหม่',
                  isError: true,
                ),
                const Gap(24),
                NeoSubmitButton(
                  text: 'ขอลิงก์รีเซ็ตใหม่',
                  backgroundColor: NeoColors.butterYellow,
                  onTap: () => context.go('/forgot-password'),
                ),
                const Gap(16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('กลับไปเข้าสู่ระบบ'),
                ),
              ],
            )
          : Form(
              key: _formKey,
              autovalidateMode: _attemptedSubmit
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    controller: _passwordController,
                    label: 'รหัสผ่านใหม่',
                    hintText: 'อย่างน้อย 8 ตัวอักษร',
                    badgeColor: NeoColors.skyBlue,
                    badgeIcon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    enabled: !request.isLoading,
                    suffixIcon: _visibilityButton(
                      _obscurePassword,
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (_) => _passwordPolicy.passwordError,
                  ),
                  const Gap(8),
                  RegistrationPasswordChecklist(policy: _passwordPolicy),
                  const Gap(18),
                  AuthTextField(
                    controller: _confirmationController,
                    label: 'ยืนยันรหัสผ่านใหม่',
                    hintText: 'กรอกรหัสผ่านใหม่อีกครั้ง',
                    badgeColor: NeoColors.softLilac,
                    badgeIcon: Icons.lock_outline_rounded,
                    obscureText: _obscureConfirmation,
                    enabled: !request.isLoading,
                    suffixIcon: _visibilityButton(
                      _obscureConfirmation,
                      () => setState(
                        () => _obscureConfirmation = !_obscureConfirmation,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    autovalidateMode: AutovalidateMode.always,
                    validator: (_) =>
                        _confirmationController.text.isEmpty &&
                            !_attemptedSubmit
                        ? null
                        : _passwordPolicy.confirmationError,
                  ),
                  const Gap(20),
                  if (request.hasError) ...[
                    PasswordRecoveryFeedback(
                      message: userVisibleError(error!),
                      isError: true,
                    ),
                    const Gap(20),
                  ],
                  NeoSubmitButton(
                    text: _cooldownSeconds > 0
                        ? 'ลองอีกครั้งใน $_cooldownSeconds วินาที'
                        : 'บันทึกรหัสผ่านใหม่',
                    backgroundColor: NeoColors.butterYellow,
                    isLoading: request.isLoading,
                    onTap: _cooldownSeconds > 0 ? null : _submit,
                  ),
                  const Gap(16),
                  TextButton(
                    onPressed: request.isLoading
                        ? null
                        : () => context.go('/forgot-password'),
                    child: const Text('ขอลิงก์รีเซ็ตใหม่'),
                  ),
                ],
              ),
            ),
    );
  }
}
