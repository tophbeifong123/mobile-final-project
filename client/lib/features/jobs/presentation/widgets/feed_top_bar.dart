import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';

/// Top Bar for Student Job Feed Screen
class FeedTopBar extends StatelessWidget {
  const FeedTopBar({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Brand Name
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: NeoColors.butterYellow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NeoColors.inkSolid, width: 2),
                    boxShadow: NeoShadows.elevation1,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      size: 18,
                      color: NeoColors.inkSolid,
                    ),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'InternMatch',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: NeoColors.inkSolid,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (subtitle != null) ...[
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: NeoColors.subtleInk,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
          // Notification Bell
          GestureDetector(
            onTap: () => context.push('/student/notifications'),
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: NeoColors.surfaceCream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NeoColors.inkSolid, width: 1.8),
                boxShadow: NeoShadows.elevation1,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 20,
                color: NeoColors.inkSolid,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
