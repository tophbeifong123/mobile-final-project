import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

/// Reusable Neo-Brutalist Top Navigation Bar for Auth screens
class AuthTopBar extends StatelessWidget {
  const AuthTopBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: NeoColors.inkSolid, width: 1.5),
        ),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: NeoColors.inkSolid,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}
