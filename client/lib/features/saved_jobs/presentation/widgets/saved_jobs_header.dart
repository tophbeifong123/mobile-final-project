import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';

/// Hero Header for Saved Jobs Screen
class SavedJobsHeader extends StatelessWidget {
  const SavedJobsHeader({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: NeoColors.surfaceCream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NeoColors.inkSolid, width: 2),
          boxShadow: NeoShadows.elevation1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: 'งานที่บันทึกไว้',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: NeoColors.inkSolid,
                  letterSpacing: -0.5,
                ),
                children: [
                  const WidgetSpan(child: SizedBox(width: 8)),
                  TextSpan(
                    text: '($count ตำแหน่ง)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: NeoColors.electricIndigo,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(4),
            const Text(
              'ตำแหน่งงานฝึกงานที่คุณสนใจและบันทึกไว้เพื่อพิจารณา',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: NeoColors.subtleInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
