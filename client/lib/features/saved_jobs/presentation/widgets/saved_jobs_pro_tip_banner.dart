import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';

/// Neo-Brutalist Pro Tip Notification Banner for Saved Jobs Screen
class SavedJobsProTipBanner extends StatelessWidget {
  const SavedJobsProTipBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: NeoColors.butterYellow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NeoColors.inkSolid, width: 2.2),
          boxShadow: NeoShadows.elevation2,
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lightbulb Icon in Pure White Square
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: NeoColors.pureWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                boxShadow: NeoShadows.elevation1,
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                size: 20,
                color: NeoColors.inkSolid,
              ),
            ),
            const Gap(10),
            // Pro Tip Text Content
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เคล็ดลับการสมัครงาน',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: NeoColors.inkSolid,
                    ),
                  ),
                  Gap(2),
                  Text(
                    'ตำแหน่งที่มีผู้สมัครจำนวนมากมักปิดรับก่อนกำหนด แนะนำให้ส่งใบสมัครโดยเร็วเพื่อไม่ให้พลาดโอกาส!',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: NeoColors.inkSolid,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
