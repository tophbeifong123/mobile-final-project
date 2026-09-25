import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final bg = backgroundColor ?? NeoColors.electricIndigo;

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: isEnabled ? bg : bg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeoColors.inkSolid, width: 2),
        boxShadow: [
          BoxShadow(
            color: NeoColors.inkSolid,
            offset: isEnabled ? const Offset(2.5, 2.5) : const Offset(1, 1),
            blurRadius: 0,
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.65),
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        child: child,
      ),
    );
  }
}
