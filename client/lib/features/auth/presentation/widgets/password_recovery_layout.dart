import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';
import 'auth_top_bar.dart';

class PasswordRecoveryLayout extends StatelessWidget {
  const PasswordRecoveryLayout({
    super.key,
    required this.title,
    required this.heading,
    required this.description,
    required this.icon,
    required this.child,
  });

  final String title;
  final String heading;
  final String description;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: NeoColors.paperCanvas,
    body: SafeArea(
      child: Column(
        children: [
          AuthTopBar(title: title),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 448),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 24, 28),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: NeoColors.pureWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: NeoColors.inkSolid,
                              width: 2,
                            ),
                            boxShadow: NeoShadows.elevation3,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: NeoColors.softLilac,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: NeoColors.inkSolid,
                                      width: 1.5,
                                    ),
                                    boxShadow: NeoShadows.elevation2,
                                  ),
                                  child: Icon(icon, size: 30),
                                ),
                              ),
                              const Gap(22),
                              Text(
                                heading,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: NeoColors.inkSolid,
                                ),
                              ),
                              const Gap(8),
                              Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: NeoColors.subtleInk,
                                ),
                              ),
                              const Gap(24),
                              child,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class PasswordRecoveryFeedback extends StatelessWidget {
  const PasswordRecoveryFeedback({
    super.key,
    required this.message,
    this.isError = false,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? NeoColors.errorBg : NeoColors.freshMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeoColors.inkSolid, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 20,
            color: NeoColors.inkSolid,
          ),
          const Gap(10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.6,
                color: NeoColors.inkSolid,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
