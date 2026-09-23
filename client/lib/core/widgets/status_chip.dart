import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tone = _tone(label);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppShadows.clay,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: tone.foreground,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  _ChipTone _tone(String value) {
    switch (value.trim().toLowerCase()) {
      case 'open':
      case 'accepted':
      case 'ผ่านการคัดเลือก':
        return const _ChipTone(AppColors.success, Colors.white);
      case 'reviewing':
      case 'submitted':
      case 'ยื่นใบสมัครแล้ว':
      case 'กำลังพิจารณา':
        return const _ChipTone(AppColors.accent, AppColors.textPrimary);
      case 'closed':
      case 'rejected':
      case 'ปิดรับ':
      case 'ไม่ผ่านการคัดเลือก':
        return const _ChipTone(Color(0xFFE2E8F0), AppColors.textSecondary);
      case 'เปิดรับ':
        return const _ChipTone(AppColors.success, Colors.white);
      default:
        return const _ChipTone(AppColors.primary, Colors.white);
    }
  }
}

class _ChipTone {
  const _ChipTone(this.background, this.foreground);

  final Color background;
  final Color foreground;
}
