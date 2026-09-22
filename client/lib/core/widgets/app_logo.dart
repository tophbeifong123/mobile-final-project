import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: AppShadows.clay,
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.24),
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: size * 0.62,
            ),
          ),
        ),
      ),
    );
  }
}
