import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';
import 'auth_text_field.dart';
import 'neo_submit_button.dart';

class GooglePasswordLinkPanel extends StatefulWidget {
  const GooglePasswordLinkPanel({
    super.key,
    required this.email,
    required this.onSubmit,
    required this.onCancel,
    this.error,
  });

  final String email;
  final String? error;
  final Future<String?> Function(String password) onSubmit;
  final VoidCallback onCancel;

  @override
  State<GooglePasswordLinkPanel> createState() =>
      _GooglePasswordLinkPanelState();
}

class _GooglePasswordLinkPanelState extends State<GooglePasswordLinkPanel> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.isEmpty || _submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(password);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'พบบัญชีนี้แล้ว',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: NeoColors.inkSolid,
            letterSpacing: -0.3,
          ),
        ),
        const Gap(8),
        Text(
          email.isEmpty
              ? 'กรอกรหัสผ่านของบัญชีนี้เพื่อเชื่อมต่อ Google'
              : 'กรอกรหัสผ่านของ $email เพื่อเชื่อมต่อ Google',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: NeoColors.subtleInk,
            height: 1.4,
          ),
        ),
        const Gap(6),
        const Text(
          'ครั้งถัดไปกด Google แล้วเข้าได้เลย',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: NeoColors.inkSolid,
            height: 1.4,
          ),
        ),
        if (email.isNotEmpty) ...[
          const Gap(14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: NeoColors.skyBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeoColors.inkSolid, width: 1.2),
            ),
            child: Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: NeoColors.inkSolid,
              ),
            ),
          ),
        ],
        const Gap(14),
        AuthTextField(
          controller: _passwordController,
          label: 'รหัสผ่าน',
          hintText: '••••••••••••',
          badgeColor: NeoColors.skyBlue,
          badgeIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          enabled: !_submitting,
          suffixIcon: IconButton(
            tooltip: _obscurePassword ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: NeoColors.inkSolid,
            ),
          ),
        ),
        if (widget.error != null) ...[
          const Gap(12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: NeoColors.errorBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NeoColors.errorBorder, width: 1.2),
            ),
            child: Text(
              widget.error!,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: NeoColors.errorText,
              ),
            ),
          ),
        ],
        const Gap(16),
        NeoSubmitButton(
          text: 'เข้าสู่ระบบ',
          backgroundColor: NeoColors.butterYellow,
          isLoading: _submitting,
          onTap: _submit,
        ),
        const Gap(14),
        GestureDetector(
          onTap: _submitting ? null : widget.onCancel,
          child: const Text(
            'กลับ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: NeoColors.subtleInk,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
