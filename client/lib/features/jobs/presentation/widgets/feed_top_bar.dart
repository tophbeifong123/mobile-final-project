import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';

/// Shared header for the student tabs: home, saved jobs, applications, profile.
class FeedTopBar extends StatelessWidget {
  const FeedTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
          const Expanded(
            child: Text(
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
          ),
          const Gap(8),
          Semantics(
            button: true,
            label: 'การแจ้งเตือน',
            child: GestureDetector(
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
          ),
        ],
      ),
    );
  }
}
