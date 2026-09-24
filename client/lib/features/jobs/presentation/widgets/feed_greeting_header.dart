import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';

/// Greeting Header Section for Student Job Feed
class FeedGreetingHeader extends StatelessWidget {
  const FeedGreetingHeader({
    super.key,
    this.name,
    this.university,
  });

  final String? name;
  final String? university;

  @override
  Widget build(BuildContext context) {
    final displayName = name?.trim() ?? '';
    final displayUniversity = (university?.trim().isNotEmpty ?? false)
        ? university!.trim()
        : 'ม.ธรรมศาสตร์';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          // Avatar Badge with Online Green Dot
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
              // Status Badge Dot
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: NeoColors.freshMint,
                    shape: BoxShape.circle,
                    border: Border.all(color: NeoColors.inkSolid, width: 1.8),
                  ),
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: NeoColors.inkSolid,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
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
                    const Text(
                      '✨',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const Gap(2),
                Text(
                  '$displayUniversity • พร้อมเริ่มฝึกงาน',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: NeoColors.subtleInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
