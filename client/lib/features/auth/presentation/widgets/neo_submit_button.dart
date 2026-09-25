import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';

/// Reusable Neo-Brutalist Action Button with press feedback and loading spinner
class NeoSubmitButton extends StatelessWidget {
  const NeoSubmitButton({
    super.key,
    required this.text,
    required this.onTap,
    this.backgroundColor = NeoColors.freshMint,
    this.trailingIcon,
    this.isLoading = false,
    this.height = 50,
  });

  final String text;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Widget? trailingIcon;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null && !isLoading;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isEnabled ? backgroundColor : backgroundColor.withAlpha(180),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NeoColors.inkSolid, width: 2.2),
          boxShadow: NeoShadows.elevation3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(NeoColors.inkSolid),
                ),
              )
            else ...[
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: NeoColors.inkSolid,
                  letterSpacing: -0.3,
                ),
              ),
              if (trailingIcon != null) ...[const Gap(8), trailingIcon!],
            ],
          ],
        ),
      ),
    );
  }
}
