import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/registration_password_policy.dart';

class RegistrationPasswordChecklist extends StatelessWidget {
  const RegistrationPasswordChecklist({super.key, required this.policy});

  final RegistrationPasswordPolicy policy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'เงื่อนไขรหัสผ่าน',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        const SizedBox(height: 6),
        _condition('อย่างน้อย 8 ตัวอักษร', policy.hasMinimumCharacters),
        _condition('ไม่เกิน 72 ไบต์ (UTF-8)', policy.withinByteLimit),
        _condition('ยืนยันรหัสผ่านตรงกัน', policy.confirmationMatches),
      ],
    );
  }

  Widget _condition(String label, bool passed) {
    final text = '${passed ? 'ผ่านแล้ว' : 'ยังขาด'}: $label';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 18,
            color: passed ? const Color(0xFF047857) : NeoColors.subtleInk,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: NeoColors.inkSolid),
            ),
          ),
        ],
      ),
    );
  }
}
