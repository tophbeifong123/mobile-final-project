import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_text_field.dart';

/// General Information Card for Student Profile Screen
class StudentProfileInfoCard extends StatelessWidget {
  const StudentProfileInfoCard({
    super.key,
    required this.nameController,
    required this.universityName,
    required this.onChooseUniversity,
    required this.onClearUniversity,
    required this.majorName,
    required this.onChooseMajor,
    required this.onClearMajor,
    required this.requiredValidator,
  });

  final TextEditingController nameController;
  final String universityName;
  final VoidCallback onChooseUniversity;
  final VoidCallback onClearUniversity;
  final String majorName;
  final VoidCallback onChooseMajor;
  final VoidCallback onClearMajor;
  final FormFieldValidator<String>? requiredValidator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NeoColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoColors.inkSolid, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: NeoColors.inkSolid,
            offset: Offset(2, 2),
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
                  color: NeoColors.pastelCoral,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: NeoColors.inkSolid, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: NeoColors.inkSolid,
                      offset: Offset(1, 1),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.badge_rounded,
                  size: 16,
                  color: NeoColors.inkSolid,
                ),
              ),
              const Gap(8),
              const Expanded(
                child: Text(
                  'ข้อมูลทั่วไป (General Info)',
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
          const Gap(14),

          AppTextField(
            controller: nameController,
            textInputAction: TextInputAction.next,
            label: 'ชื่อ',
            prefixIcon: const Icon(Icons.person_rounded, size: 18),
            validator: requiredValidator,
          ),
          const Gap(12),

          InkWell(
            key: const Key('student-university-picker'),
            onTap: onChooseUniversity,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'มหาวิทยาลัย',
                prefixIcon: const Icon(Icons.school_rounded, size: 18),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search),
                    if (universityName.isNotEmpty)
                      IconButton(
                        key: const Key('student-clear-university'),
                        tooltip: 'ล้างมหาวิทยาลัย',
                        onPressed: onClearUniversity,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                border: const OutlineInputBorder(),
              ),
              child: Text(
                universityName.isEmpty ? 'เลือกมหาวิทยาลัย' : universityName,
                style: TextStyle(
                  color: universityName.isEmpty
                      ? NeoColors.mutedInk
                      : NeoColors.inkSolid,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const Gap(12),

          InkWell(
            key: const Key('student-major-picker'),
            onTap: onChooseMajor,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'สาขา',
                prefixIcon: const Icon(Icons.menu_book_rounded, size: 18),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search),
                    if (majorName.isNotEmpty)
                      IconButton(
                        key: const Key('student-clear-major'),
                        tooltip: 'ล้างสาขา',
                        onPressed: onClearMajor,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                border: const OutlineInputBorder(),
              ),
              child: Text(
                majorName.isEmpty ? 'เลือกหรือค้นหาสาขา' : majorName,
                style: TextStyle(
                  color: majorName.isEmpty
                      ? NeoColors.mutedInk
                      : NeoColors.inkSolid,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
