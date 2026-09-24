import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/student_profile.dart';

/// Hero Card for Student Profile Screen matching Neo-Brutalist design
class StudentProfileHeroCard extends StatelessWidget {
  const StudentProfileHeroCard({
    super.key,
    required this.profile,
    this.onAvatarTap,
  });

  final StudentProfile profile;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NeoColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoColors.inkSolid, width: 2),
        boxShadow: const [
          BoxShadow(
            color: NeoColors.inkSolid,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Playful Neo Stamp Decoration in Background
          Positioned(
            right: -16,
            top: -16,
            child: Transform.rotate(
              angle: 0.15,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: NeoColors.butterYellow.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.rocket_launch_rounded,
                    size: 38,
                    color: NeoColors.inkSolid,
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + Quick Edit Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: NeoColors.skyBlue,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: NeoColors.inkSolid,
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: NeoColors.inkSolid,
                                offset: Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              profile.fullName.isNotEmpty
                                  ? profile.fullName.characters.first
                                  : 'S',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: NeoColors.inkSolid,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: GestureDetector(
                            onTap: onAvatarTap,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: NeoColors.butterYellow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: NeoColors.inkSolid,
                                  width: 1.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: NeoColors.inkSolid,
                                    offset: Offset(1.5, 1.5),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.photo_camera_rounded,
                                size: 14,
                                color: NeoColors.inkSolid,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(12),

                // Student Identifiers
                Text(
                  profile.fullName.isNotEmpty
                      ? profile.fullName
                      : 'ยังไม่ได้ระบุชื่อ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.inkSolid,
                    letterSpacing: -0.3,
                  ),
                ),
                const Gap(4),
                Text(
                  [
                    if (profile.university.isNotEmpty) profile.university,
                    if (profile.major.isNotEmpty) profile.major,
                  ].join(' • '),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: NeoColors.subtleInk,
                    height: 1.4,
                  ),
                ),
                const Gap(12),

                // Metadata Badges Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Internship Readiness Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: NeoColors.freshMint,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: NeoColors.inkSolid,
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: NeoColors.inkSolid,
                            offset: Offset(1.5, 1.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: NeoColors.inkSolid,
                          ),
                          Gap(6),
                          Text(
                            'พร้อมเริ่มฝึกงาน',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: NeoColors.inkSolid,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Resume Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: profile.resumeFileName != null
                            ? NeoColors.butterYellow
                            : NeoColors.surfaceCream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: NeoColors.inkSolid,
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: NeoColors.inkSolid,
                            offset: Offset(1.5, 1.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            profile.resumeFileName != null
                                ? Icons.description_rounded
                                : Icons.info_outline_rounded,
                            size: 14,
                            color: NeoColors.inkSolid,
                          ),
                          const Gap(6),
                          Text(
                            profile.resumeFileName != null
                                ? 'มีเรซูเม่แล้ว'
                                : 'ยังไม่ได้อัปโหลดเรซูเม่',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: NeoColors.inkSolid,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
