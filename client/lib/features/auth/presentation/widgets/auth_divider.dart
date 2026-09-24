import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

/// Reusable Neo-Brutalist Divider with centered pill text
class AuthDivider extends StatelessWidget {
  const AuthDivider({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Divider(
          color: NeoColors.inkSolid,
          thickness: 1.5,
          height: 1.5,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          decoration: BoxDecoration(
            color: NeoColors.paperCanvas,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: NeoColors.inkSolid, width: 1.5),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: NeoColors.inkSolid,
            ),
          ),
        ),
      ],
    );
  }
}
