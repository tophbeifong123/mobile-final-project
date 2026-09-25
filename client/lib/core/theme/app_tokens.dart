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

/// Retro-Chunky Neo-Brutalist Color Tokens
abstract final class NeoColors {
  // Surfaces & Neutrals
  static const Color paperCanvas = Color(0xFFFDF8EE);
  static const Color surfaceCream = Color(0xFFFFFBEB);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color inkSolid = Color(0xFF18181B);
  static const Color subtleInk = Color(0xFF4B5563);
  static const Color mutedInk = Color(0xFF9CA3AF);

  // Vibrant Retro Accents
  static const Color butterYellow = Color(0xFFFEF08A);
  static const Color skyBlue = Color(0xFFBAE6FD);
  static const Color pastelCoral = Color(0xFFFDBA74);
  static const Color softLilac = Color(0xFFDDD6FE);
  static const Color freshMint = Color(0xFFA7F3D0);
  static const Color softRose = Color(0xFFFDA4AF);
  static const Color electricIndigo = Color(0xFF4F46E5);

  // Status / Feedback
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color errorBorder = Color(0xFFEF4444);
  static const Color errorText = Color(0xFFDC2626);
  static const Color onlineGreen = Color(0xFF4ADE80);
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

/// Retro-Chunky Neo-Brutalist Hard Drop Shadows
abstract final class NeoShadows {
  static const List<BoxShadow> elevation1 = [
    BoxShadow(
      color: NeoColors.inkSolid,
      offset: Offset(1.5, 1.5),
      blurRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevation2 = [
    BoxShadow(color: NeoColors.inkSolid, offset: Offset(3, 3), blurRadius: 0),
  ];

  static const List<BoxShadow> elevation3 = [
    BoxShadow(
      color: NeoColors.inkSolid,
      offset: Offset(3.5, 3.5),
      blurRadius: 0,
    ),
  ];
}

const double kPagePadding = 16;
const double kMinTouchTarget = 48;
