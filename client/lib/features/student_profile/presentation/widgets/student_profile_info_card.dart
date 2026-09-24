import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_text_field.dart';

/// General Information Card for Student Profile Screen
class StudentProfileInfoCard extends StatelessWidget {
  const StudentProfileInfoCard({
    super.key,
    required this.nameController,
    required this.universityController,
    required this.majorController,
    required this.requiredValidator,
  });

  final TextEditingController nameController;
  final TextEditingController universityController;
  final TextEditingController majorController;
  final FormFieldValidator<String>? requiredValidator;

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
                  color: NeoColors.pastelCoral,
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

          AppTextField(
            controller: universityController,
            textInputAction: TextInputAction.next,
            label: 'มหาวิทยาลัย',
            prefixIcon: const Icon(Icons.school_rounded, size: 18),
            validator: requiredValidator,
          ),
          const Gap(12),

          AppTextField(
            controller: majorController,
            textInputAction: TextInputAction.next,
            label: 'สาขา',
            prefixIcon: const Icon(Icons.menu_book_rounded, size: 18),
            validator: requiredValidator,
          ),
        ],
      ),
    );
  }
}
