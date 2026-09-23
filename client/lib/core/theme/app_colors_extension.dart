import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.border,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.ring,
    required this.destructive,
    required this.destructiveForeground,
    required this.card,
    required this.cardForeground,
  });

  final Color border;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color ring;
  final Color destructive;
  final Color destructiveForeground;
  final Color card;
  final Color cardForeground;

  static const light = AppColorsExtension(
    border: AppColors.line,
    muted: Color(0xFFF1F5F9),
    mutedForeground: AppColors.textSecondary,
    accent: Color(0xFFF8FAFC),
    ring: AppColors.primary,
    destructive: Color(0xFFEF4444),
    destructiveForeground: Colors.white,
    card: AppColors.surface,
    cardForeground: AppColors.textPrimary,
  );

  @override
  AppColorsExtension copyWith({
    Color? border,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? ring,
    Color? destructive,
    Color? destructiveForeground,
    Color? card,
    Color? cardForeground,
  }) {
    return AppColorsExtension(
      border: border ?? this.border,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      ring: ring ?? this.ring,
      destructive: destructive ?? this.destructive,
      destructiveForeground:
          destructiveForeground ?? this.destructiveForeground,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      border: Color.lerp(border, other.border, t) ?? border,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      mutedForeground:
          Color.lerp(mutedForeground, other.mutedForeground, t) ??
              mutedForeground,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      ring: Color.lerp(ring, other.ring, t) ?? ring,
      destructive: Color.lerp(destructive, other.destructive, t) ?? destructive,
      destructiveForeground:
          Color.lerp(destructiveForeground, other.destructiveForeground, t) ??
              destructiveForeground,
      card: Color.lerp(card, other.card, t) ?? card,
      cardForeground:
          Color.lerp(cardForeground, other.cardForeground, t) ?? cardForeground,
    );
  }
}

extension ThemeContextX on BuildContext {
  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.light;
}
