import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Interactive Skills Card for Student Profile Screen matching Neo-Brutalism
class StudentProfileSkillsCard extends StatefulWidget {
  const StudentProfileSkillsCard({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  State<StudentProfileSkillsCard> createState() =>
      _StudentProfileSkillsCardState();
}

class _StudentProfileSkillsCardState extends State<StudentProfileSkillsCard> {
  late final TextEditingController _newSkillController;

  @override
  void initState() {
    super.initState();
    _newSkillController = TextEditingController();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _newSkillController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  List<String> get _skills {
    return widget.controller.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _removeSkill(int index) {
    final list = _skills;
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      widget.controller.text = list.join(', ');
    }
  }

  void _addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty) return;
    final list = _skills;
    if (!list.contains(trimmed)) {
      list.add(trimmed);
      widget.controller.text = list.join(', ');
    }
  }

  void _showAddSkillDialog() {
    _newSkillController.clear();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: NeoColors.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: NeoColors.inkSolid, width: 2),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline_rounded, color: NeoColors.inkSolid),
              Gap(8),
              Text(
                'เพิ่มทักษะใหม่',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: NeoColors.inkSolid,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: _newSkillController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'เช่น Flutter, React, Figma',
            ),
            onSubmitted: (value) {
              _addSkill(value);
              Navigator.of(dialogContext).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                _addSkill(_newSkillController.text);
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoColors.electricIndigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('เพิ่มทักษะ'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final skills = _skills;

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
              const Text(
                'แตะ ✕ เพื่อลบ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: NeoColors.subtleInk,
                ),
              ),
            ],
          ),
          const Gap(12),

          // Pills Container
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
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
                onTap: _showAddSkillDialog,
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
          const Gap(12),

          // Standard AppTextField to support direct editing & tests
          AppTextField(
            controller: widget.controller,
            label: 'ทักษะ',
            hintText: 'คั่นด้วยจุลภาค เช่น Flutter, SQL',
            prefixIcon: const Icon(Icons.code_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
