import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';

/// Reusable Neo-Brutalist Password Strength Visualizer
class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({
    super.key,
    required this.password,
  });

  final String password;

  static int calculateStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[a-zA-Z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(password) || password.length >= 12) {
      score++;
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final strength = calculateStrength(password);

    String statusText;
    Color statusColor;

    if (strength == 0) {
      statusText = 'ยังไม่ปลอดภัย';
      statusColor = NeoColors.subtleInk;
    } else if (strength == 1) {
      statusText = 'ยังไม่ปลอดภัย';
      statusColor = NeoColors.errorBorder;
    } else if (strength == 2) {
      statusText = 'ปานกลาง';
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusText = 'ปลอดภัยมาก';
      statusColor = const Color(0xFF10B981);
    }

    return Row(
      children: [
        const Text(
          'ระดับความปลอดภัย: ',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: NeoColors.subtleInk,
          ),
        ),
        for (int i = 1; i <= 3; i++) ...[
          Expanded(
            child: Container(
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i <= strength
                    ? (strength == 1
                        ? NeoColors.errorBorder
                        : strength == 2
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981))
                    : NeoColors.pureWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: i <= strength
                      ? NeoColors.inkSolid
                      : NeoColors.mutedInk,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ],
        const Gap(6),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: statusColor,
          ),
        ),
      ],
    );
  }
}
