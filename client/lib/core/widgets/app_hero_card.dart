import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class AppHeroCard extends StatelessWidget {
  const AppHeroCard({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.clay,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(body, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
