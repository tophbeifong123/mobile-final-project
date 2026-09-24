import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/app_tokens.dart';

/// Button variant for Neo-Brutalist design
enum NeoButtonVariant {
  primary,
  secondary,
  destructive,
  outline,
  surface,
}

/// First-class Neo-Brutalist Action Button matching project design system.
///
/// Features bold black borders (2px), sharp drop shadows (2-3px offset),
/// vibrant retro palettes, loading spinner, and responsive press states.
class NeoButton extends StatefulWidget {
  const NeoButton({
    super.key,
    required this.onPressed,
    this.text,
    this.child,
    this.variant = NeoButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48,
    this.backgroundColor,
    this.foregroundColor,
  }) : assert(
          text != null || child != null,
          'Either text or child must be provided',
        );

  final VoidCallback? onPressed;
  final String? text;
  final Widget? child;
  final NeoButtonVariant variant;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color fg;
    double borderWidth = 2.0;
    double shadowOffset = 2.5;

    switch (widget.variant) {
      case NeoButtonVariant.primary:
        bg = widget.backgroundColor ?? NeoColors.electricIndigo;
        fg = widget.foregroundColor ?? Colors.white;
        borderWidth = 2.0;
        shadowOffset = 3.0;
      case NeoButtonVariant.secondary:
        bg = widget.backgroundColor ?? NeoColors.butterYellow;
        fg = widget.foregroundColor ?? NeoColors.inkSolid;
        borderWidth = 2.0;
        shadowOffset = 2.5;
      case NeoButtonVariant.destructive:
        bg = widget.backgroundColor ?? NeoColors.surfaceCream;
        fg = widget.foregroundColor ?? NeoColors.errorText;
        borderWidth = 1.8;
        shadowOffset = 2.0;
      case NeoButtonVariant.outline:
        bg = widget.backgroundColor ?? NeoColors.pureWhite;
        fg = widget.foregroundColor ?? NeoColors.inkSolid;
        borderWidth = 1.8;
        shadowOffset = 2.0;
      case NeoButtonVariant.surface:
        bg = widget.backgroundColor ?? NeoColors.surfaceCream;
        fg = widget.foregroundColor ?? NeoColors.inkSolid;
        borderWidth = 1.8;
        shadowOffset = 2.0;
    }

    if (!isEnabled) {
      bg = bg.withValues(alpha: 0.55);
      fg = fg.withValues(alpha: 0.65);
      shadowOffset = 1.0;
    }

    final content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          if (widget.text != null || widget.child != null) const Gap(8),
        ] else if (widget.icon != null) ...[
          widget.icon!,
          if (widget.text != null || widget.child != null) const Gap(8),
        ],
        if (widget.child != null)
          Flexible(child: widget.child!)
        else if (widget.text != null)
          Flexible(
            child: Text(
              widget.text!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: fg,
                letterSpacing: -0.2,
              ),
            ),
          ),
        if (widget.trailingIcon != null && !widget.isLoading) ...[
          const Gap(8),
          widget.trailingIcon!,
        ],
      ],
    );

    final currentOffset = _isPressed && isEnabled ? 0.5 : shadowOffset;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        height: widget.height,
        padding: EdgeInsets.symmetric(
          horizontal: widget.height <= 38 ? 12 : 18,
        ),
        transform: Matrix4.translationValues(
          _isPressed && isEnabled ? 1.5 : 0,
          _isPressed && isEnabled ? 1.5 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NeoColors.inkSolid, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: NeoColors.inkSolid,
              offset: Offset(currentOffset, currentOffset),
              blurRadius: 0,
            ),
          ],
        ),
        child: widget.isFullWidth
            ? SizedBox(width: double.infinity, child: content)
            : content,
      ),
    );
  }
}
