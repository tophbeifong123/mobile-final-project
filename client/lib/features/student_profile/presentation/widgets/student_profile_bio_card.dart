import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';

/// Bio / About Me Card for Student Profile Screen
class StudentProfileBioCard extends StatelessWidget {
  const StudentProfileBioCard({super.key, required this.bioController});

  final TextEditingController bioController;

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: NeoColors.freshMint,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: NeoColors.inkSolid,
                      offset: Offset(1.5, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.format_quote_rounded,
                  size: 16,
                  color: NeoColors.inkSolid,
                ),
              ),
              const Gap(8),
              const Expanded(
                child: Text(
                  'เกี่ยวกับฉัน (About Me)',
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
          const Gap(12),

          TextFormField(
            controller: bioController,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: NeoColors.inkSolid,
            ),
            decoration: InputDecoration(
              hintText:
                  'แนะนำตัวเองสั้นๆ ความสนใจ ความมุ่งมั่น หรือสิ่งที่คุณกำลังมองหาในการฝึกงาน...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: NeoColors.mutedInk,
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: NeoColors.paperCanvas,
              counterStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: NeoColors.mutedInk,
              ),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: NeoColors.inkSolid,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: NeoColors.mutedInk,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: NeoColors.inkSolid,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
