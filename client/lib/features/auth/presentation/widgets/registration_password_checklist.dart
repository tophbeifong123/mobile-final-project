import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/registration_password_policy.dart';

class RegistrationPasswordChecklist extends StatelessWidget {
  const RegistrationPasswordChecklist({super.key, required this.policy});

  final RegistrationPasswordPolicy policy;

  @override
  Widget build(BuildContext context) {
    final missing = <String>[
      if (!policy.hasMinimumCharacters) 'ให้ครบ 8 ตัว',
      if (!policy.hasUppercase) 'ตัวพิมพ์ใหญ่ A–Z',
      if (!policy.hasLowercase) 'ตัวพิมพ์เล็ก a–z',
      if (!policy.hasDigit) 'ตัวเลข',
      if (!policy.hasSpecialCharacter) 'สัญลักษณ์ เช่น ! @ #',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'อย่างน้อย 8 ตัว มี A–Z, a–z, ตัวเลข และสัญลักษณ์',
          style: TextStyle(fontSize: 12, color: NeoColors.subtleInk),
        ),
        if (policy.password.isNotEmpty && missing.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'เพิ่มอีก: ${missing.join(', ')}',
            style: const TextStyle(fontSize: 12, color: NeoColors.subtleInk),
          ),
        ],
      ],
    );
  }
}
