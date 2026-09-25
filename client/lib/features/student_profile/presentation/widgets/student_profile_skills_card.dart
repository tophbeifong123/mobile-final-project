import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/preset_skills.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/skill_picker_sheet.dart';

/// Interactive Skills Card for Student Profile Screen matching LinkedIn Light + Neo-Brutalism
class StudentProfileSkillsCard extends StatelessWidget {
  const StudentProfileSkillsCard({
    super.key,
    required this.skills,
    required this.onChanged,
  });

  final List<String> skills;
  final ValueChanged<List<String>> onChanged;

  void _removeSkill(int index) {
    if (index >= 0 && index < skills.length) {
      final updated = List<String>.from(skills)..removeAt(index);
      onChanged(updated);
    }
  }

  void _addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty) return;
    if (!skills.any((s) => s.toLowerCase() == trimmed.toLowerCase())) {
      final updated = List<String>.from(skills)..add(trimmed);
      onChanged(updated);
    }
  }

  Future<void> _openSkillPicker(BuildContext context) async {
    final result = await SkillPickerSheet.show(
      context,
      selectedSkills: skills,
      title: 'ทักษะและความสามารถ (Skills)',
      subtitle: 'เลือกทักษะที่ตรงกับคุณเพื่อเพิ่มโอกาสในการจับคู่งานฝึกงาน',
    );
    if (result != null) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Quick suggestions from presets not yet added
    final quickSuggestions = PresetSkills.all
        .where((s) => !skills.any((existing) => existing.toLowerCase() == s.toLowerCase()))
        .take(6)
        .toList();

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
                        color: NeoColors.softLilac,
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
                        Icons.psychology_rounded,
                        size: 16,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                    const Gap(8),
                    const Expanded(
                      child: Text(
                        'ทักษะและความสามารถ (Skills)',
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: NeoColors.butterYellow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                ),
                child: Text(
                  '${skills.length} ทักษะ',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.inkSolid,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),

          // Selected Skills Badges
          if (skills.isEmpty)
            GestureDetector(
              onTap: () => _openSkillPicker(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: NeoColors.surfaceCream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: NeoColors.subtleInk,
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 28,
                      color: NeoColors.subtleInk,
                    ),
                    Gap(6),
                    Text(
                      'ยังไม่ได้เพิ่มทักษะ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                    Gap(2),
                    Text(
                      'แตะที่นี่เพื่อเลือกทักษะจากคำแนะนำ หรือเพิ่มทักษะใหม่',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: NeoColors.subtleInk,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < skills.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: NeoColors.surfaceCream,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: NeoColors.inkSolid, width: 1.5),
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
                        Text(
                          skills[i],
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: NeoColors.inkSolid,
                          ),
                        ),
                        const Gap(6),
                        GestureDetector(
                          onTap: () => _removeSkill(i),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: NeoColors.subtleInk,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Add Skill Button
                GestureDetector(
                  onTap: () => _openSkillPicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: NeoColors.butterYellow,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: NeoColors.inkSolid, width: 1.5),
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
                        Icon(Icons.add_rounded, size: 15, color: NeoColors.inkSolid),
                        Gap(4),
                        Text(
                          'เพิ่มทักษะ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: NeoColors.inkSolid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

          // Quick Preset Suggestions
          if (quickSuggestions.isNotEmpty) ...[
            const Gap(14),
            const Text(
              'คำแนะนำสำหรับคุณ:',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: NeoColors.subtleInk,
              ),
            ),
            const Gap(6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final suggestion in quickSuggestions)
                  GestureDetector(
                    onTap: () => _addSkill(suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: NeoColors.pureWhite,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: NeoColors.subtleInk.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 12, color: NeoColors.subtleInk),
                          const Gap(3),
                          Text(
                            suggestion,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: NeoColors.subtleInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
