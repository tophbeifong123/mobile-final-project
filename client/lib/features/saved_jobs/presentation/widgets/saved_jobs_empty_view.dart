import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';

/// Neo-Brutalist Empty State View for Saved Jobs Screen
class SavedJobsEmptyView extends StatelessWidget {
  const SavedJobsEmptyView({
    super.key,
    this.title = 'ยังไม่มีงานที่คุณบันทึกไว้',
    this.message = 'ลองสำรวจตำแหน่งงานฝึกงานที่น่าสนใจแล้วกดเซฟไว้เพื่อสมัครภายหลัง!',
    this.actionText = 'ค้นหาตำแหน่งงาน',
    this.onAction,
  });

  final String title;
  final String message;
  final String actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: NeoColors.pureWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: NeoColors.inkSolid, width: 2.5),
            boxShadow: NeoShadows.elevation3,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Butter Yellow Icon Box
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NeoColors.butterYellow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: NeoColors.inkSolid, width: 2),
                  boxShadow: NeoShadows.elevation1,
                ),
                child: const Icon(
                  Icons.bookmark_border_rounded,
                  size: 36,
                  color: NeoColors.inkSolid,
                ),
              ),
              const Gap(16),
              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: NeoColors.inkSolid,
                  letterSpacing: -0.3,
                ),
              ),
              const Gap(6),
              // Message
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: NeoColors.subtleInk,
                    height: 1.4,
                  ),
                ),
              ),
              const Gap(20),
              // CTA Button
              GestureDetector(
                onTap: onAction ?? () => context.go('/student/home'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: NeoColors.electricIndigo,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NeoColors.inkSolid, width: 2),
                    boxShadow: NeoShadows.elevation1,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const Gap(6),
                      const Icon(
                        Icons.travel_explore_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
