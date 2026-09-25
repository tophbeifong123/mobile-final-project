import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';

/// Reusable Neo-Brutalist Social Authentication Button
class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: NeoColors.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NeoColors.inkSolid, width: 2),
          boxShadow: NeoShadows.elevation2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const Gap(8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: NeoColors.inkSolid,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
