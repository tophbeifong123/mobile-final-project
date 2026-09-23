import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/app_tokens.dart';
import 'app_card.dart';

class AppHeroCard extends StatelessWidget {
  const AppHeroCard({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      shadows: AppShadows.clay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleLarge),
          const Gap(4),
          Text(body, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
