import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/app_colors_extension.dart';
import '../theme/app_tokens.dart';

enum AppButtonVariant {
  default_,
  outline,
  ghost,
  destructive,
  secondary,
}

enum AppButtonSize {
  sm,
  md,
  lg,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    this.text,
    this.child,
    this.variant = AppButtonVariant.default_,
    this.size = AppButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : assert(text != null || child != null, 'Either text or child must be provided');

  final VoidCallback? onPressed;
  final String? text;
  final Widget? child;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDisabled = onPressed == null || isLoading;

    final (height, padding, fontSize) = switch (size) {
      AppButtonSize.sm => (36.0, const EdgeInsets.symmetric(horizontal: 12), 13.0),
      AppButtonSize.md => (48.0, const EdgeInsets.symmetric(horizontal: 16), 15.0),
      AppButtonSize.lg => (54.0, const EdgeInsets.symmetric(horizontal: 24), 16.0),
    };

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;
    List<BoxShadow> shadows = const [];

    switch (variant) {
      case AppButtonVariant.default_:
        backgroundColor = isDisabled ? const Color(0xFFC7D2FE) : AppColors.primary;
        foregroundColor = Colors.white;
        if (!isDisabled) shadows = AppShadows.clay;
      case AppButtonVariant.destructive:
        backgroundColor = isDisabled ? colors.destructive.withValues(alpha: 0.5) : colors.destructive;
        foregroundColor = colors.destructiveForeground;
      case AppButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = isDisabled ? colors.mutedForeground : AppColors.textPrimary;
        borderSide = BorderSide(color: isDisabled ? colors.border.withValues(alpha: 0.5) : colors.border);
      case AppButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = isDisabled ? colors.mutedForeground : AppColors.textPrimary;
      case AppButtonVariant.secondary:
        backgroundColor = isDisabled ? colors.muted.withValues(alpha: 0.5) : colors.muted;
        foregroundColor = isDisabled ? colors.mutedForeground : colors.cardForeground;
    }

    final contentWidget = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: fontSize + 2,
            height: fontSize + 2,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor,
            ),
          ),
          if (text != null || child != null) const Gap(8),
        ] else if (icon != null) ...[
          icon!,
          if (text != null || child != null) const Gap(8),
        ],
        if (child != null)
          child!
        else if (text != null)
          Text(
            text!,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
            ),
          ),
      ],
    );

    final button = Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: borderSide,
      ),
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: height,
          padding: padding,
          alignment: Alignment.center,
          child: contentWidget,
        ),
      ),
    );

    Widget result = shadows.isNotEmpty
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: shadows,
            ),
            child: button,
          )
        : button;

    if (isFullWidth) {
      result = SizedBox(width: double.infinity, child: result);
    }

    return result;
  }
}
