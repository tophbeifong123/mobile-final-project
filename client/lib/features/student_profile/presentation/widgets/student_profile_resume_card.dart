import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import 'resume_preview_modal.dart';

/// Active Resume Card for Student Profile Screen matching Neo-Brutalist design
class StudentProfileResumeCard extends StatelessWidget {
  const StudentProfileResumeCard({
    super.key,
    required this.resumeFileName,
  });

  final String? resumeFileName;

  @override
  Widget build(BuildContext context) {
    final hasResume = resumeFileName != null && resumeFileName!.isNotEmpty;

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: NeoColors.freshMint,
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: NeoColors.inkSolid, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: NeoColors.inkSolid,
                            offset: Offset(1.5, 1.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        size: 15,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                    const Gap(8),
                    const Expanded(
                      child: Text(
                        'เรซูเม่หลัก (Active Resume)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.inkSolid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(8),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: hasResume ? NeoColors.freshMint : NeoColors.mutedInk,
                  shape: BoxShape.circle,
                  border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                ),
              ),
            ],
          ),
          const Gap(12),

          // Inner File Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NeoColors.surfaceCream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeoColors.inkSolid, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: NeoColors.inkSolid,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: hasResume
                            ? NeoColors.softRose
                            : NeoColors.surfaceCream,
                        borderRadius: BorderRadius.circular(10),
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
                      child: Icon(
                        hasResume
                            ? Icons.picture_as_pdf_rounded
                            : Icons.upload_file_rounded,
                        size: 22,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resume',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: NeoColors.subtleInk,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            hasResume
                                ? resumeFileName!
                                : 'ยังไม่มี Resume ในระบบ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: hasResume
                                  ? NeoColors.inkSolid
                                  : NeoColors.subtleInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(12),

                // Action Buttons
                Row(
                  children: [
                    if (hasResume) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ResumePreviewModal.show(
                              context,
                              fileName: resumeFileName!,
                              onReplace: () => context.push('/student/resume'),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: NeoColors.pureWhite,
                            foregroundColor: NeoColors.inkSolid,
                            side: const BorderSide(
                              color: NeoColors.inkSolid,
                              width: 1.5,
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 10,
                            ),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.visibility_rounded, size: 15),
                              Gap(4),
                              Flexible(
                                child: Text(
                                  'ดูตัวอย่าง',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Gap(8),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.push('/student/resume'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NeoColors.butterYellow,
                          foregroundColor: NeoColors.inkSolid,
                          elevation: 0,
                          side: const BorderSide(
                            color: NeoColors.inkSolid,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 10,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              hasResume
                                  ? Icons.sync_rounded
                                  : Icons.upload_file_rounded,
                              size: 15,
                            ),
                            const Gap(4),
                            Flexible(
                              child: Text(
                                hasResume ? 'เปลี่ยน' : 'อัปโหลด',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
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
