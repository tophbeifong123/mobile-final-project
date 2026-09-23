import 'package:flutter/material.dart';

import '../theme/app_colors_extension.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
    this.shadows,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = borderRadius ?? BorderRadius.circular(16);
    final bg = backgroundColor ?? colors.card;
    final border = BorderSide(
      color: borderColor ?? colors.border,
      width: borderWidth,
    );

    Widget content = Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: border,
      ),
      clipBehavior: clipBehavior,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius is BorderRadius ? radius : BorderRadius.circular(16),
        child: padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );

    if (shadows != null && shadows!.isNotEmpty) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: shadows,
        ),
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
