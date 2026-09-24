import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Portfolio and Links Card for Student Profile Screen
class StudentProfileLinksCard extends StatelessWidget {
  const StudentProfileLinksCard({
    super.key,
    required this.controller,
    required this.validator,
  });

  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

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
                  color: NeoColors.butterYellow,
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
                  Icons.link_rounded,
                  size: 16,
                  color: NeoColors.inkSolid,
                ),
              ),
              const Gap(8),
              const Expanded(
                child: Text(
                  'ผลงานและช่องทางติดต่อ (Links)',
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

          AppTextField(
            controller: controller,
            keyboardType: TextInputType.url,
            label: 'Portfolio',
            hintText: 'https://',
            prefixIcon: const Icon(Icons.language_rounded, size: 18),
            validator: validator,
          ),
        ],
      ),
    );
  }
}
