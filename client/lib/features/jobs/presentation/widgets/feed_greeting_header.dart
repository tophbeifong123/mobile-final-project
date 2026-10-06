import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';

/// Greeting Header Section for Student Job Feed
class FeedGreetingHeader extends StatelessWidget {
  const FeedGreetingHeader({super.key, this.name, this.university});

  final String? name;
  final String? university;

  @override
  Widget build(BuildContext context) {
    final displayName = name?.trim() ?? '';
    final displayUniversity = university?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          // No fabricated online/completeness status on the profile avatar.
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NeoColors.butterYellow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: NeoColors.inkSolid, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: NeoColors.inkSolid,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 22,
                  color: NeoColors.inkSolid,
                ),
              ),
            ],
          ),
          const Gap(12),
          // Greeting & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'สวัสดี',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: NeoColors.inkSolid,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (displayName.isNotEmpty) ...[
                      const Gap(4),
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: NeoColors.inkSolid,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                    const Gap(4),
                    const Text('✨', style: TextStyle(fontSize: 16)),
                  ],
                ),
                if (displayUniversity.isNotEmpty) ...[
                  const Gap(2),
                  Text(
                    displayUniversity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: NeoColors.subtleInk,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
