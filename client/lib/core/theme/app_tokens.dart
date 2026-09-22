import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color background = Color(0xFFEEF4FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryPressed = Color(0xFF4338CA);
  static const Color accent = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color line = Color(0xFFE2E8F0);
}

abstract final class AppShadows {
  static const List<BoxShadow> clay = [
    BoxShadow(
      color: Color(0x144F46E5),
      blurRadius: 25,
      offset: Offset(0, 10),
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 6,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];
}

const double kPagePadding = 16;
const double kMinTouchTarget = 48;
