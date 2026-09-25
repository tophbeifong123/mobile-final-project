import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../constants/preset_skills.dart';
import '../theme/app_tokens.dart';
import 'neo_button.dart';

/// Interactive Neo-Brutalist Skills Picker (LinkedIn Light UX)
class SkillPickerSheet extends StatefulWidget {
  const SkillPickerSheet({
    super.key,
    required this.selectedSkills,
    this.title = 'เลือกทักษะ (Select Skills)',
    this.subtitle = 'เลือกจากคำแนะนำ หรือพิมพ์เพื่อเพิ่มทักษะใหม่',
  });

  final List<String> selectedSkills;
  final String title;
  final String subtitle;

  /// Convenience show method returning the selected skills list
  static Future<List<String>?> show(
    BuildContext context, {
    required List<String> selectedSkills,
    String title = 'เลือกทักษะ (Select Skills)',
    String subtitle = 'เลือกจากคำแนะนำ หรือพิมพ์เพื่อเพิ่มทักษะใหม่',
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SkillPickerSheet(
        selectedSkills: selectedSkills,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<SkillPickerSheet> createState() => _SkillPickerSheetState();
}

class _SkillPickerSheetState extends State<SkillPickerSheet> {
  late final TextEditingController _searchController;
  late final List<String> _selected;
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selectedSkills);
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  void _toggleSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      final index = _selected.indexWhere(
        (s) => s.toLowerCase() == trimmed.toLowerCase(),
      );
      if (index >= 0) {
        _selected.removeAt(index);
      } else {
        _selected.add(trimmed);
      }
    });
  }

  void _addCustomSkill() {
    if (_searchQuery.isEmpty) return;
    _toggleSkill(_searchQuery);
    _searchController.clear();
  }

  bool _isSkillSelected(String skill) {
    return _selected.any((s) => s.toLowerCase() == skill.trim().toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final filteredPresets = PresetSkills.search(
      _searchQuery,
      category: _selectedCategory,
    );

    final showCustomAddButton = _searchQuery.isNotEmpty &&
        !filteredPresets.any(
          (s) => s.toLowerCase() == _searchQuery.toLowerCase(),
        );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: NeoColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: NeoColors.inkSolid, width: 2.5),
          left: BorderSide(color: NeoColors.inkSolid, width: 2.5),
          right: BorderSide(color: NeoColors.inkSolid, width: 2.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: NeoColors.mutedInk,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: NeoColors.inkSolid, width: 1),
                ),
              ),
            ),

            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: NeoColors.inkSolid,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: NeoColors.subtleInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: NeoColors.butterYellow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: NeoColors.inkSolid,
                          offset: Offset(1.5, 1.5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      'เลือกแล้ว ${_selected.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: NeoColors.inkSolid, height: 1.5, thickness: 1.5),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: NeoColors.paperCanvas,
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
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: NeoColors.inkSolid,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ค้นหาทักษะ เช่น Flutter, Figma, SQL...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: NeoColors.subtleInk,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: NeoColors.inkSolid,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () => _searchController.clear(),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: NeoColors.inkSolid,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            // Category Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildCategoryPill(null, 'ทั้งหมด'),
                  for (final cat in PresetSkills.categories.keys) ...[
                    const Gap(6),
                    _buildCategoryPill(cat, cat),
                  ],
                ],
              ),
            ),

            // Custom Skill Add Button (if searched item is not in preset)
            if (showCustomAddButton) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: GestureDetector(
                  onTap: _addCustomSkill,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: NeoColors.freshMint,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: NeoColors.inkSolid,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 18,
                          color: NeoColors.inkSolid,
                        ),
                        const Gap(8),
                        Flexible(
                          child: Text(
                            'เพิ่ม "$_searchQuery" เป็นทักษะใหม่',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: NeoColors.inkSolid,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Skills Chips Canvas
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: filteredPresets.isEmpty && !showCustomAddButton
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'ไม่พบทักษะที่ค้นหา',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: NeoColors.subtleInk,
                            ),
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final skill in filteredPresets)
                            _buildSkillChip(skill),
                        ],
                      ),
              ),
            ),

            // Footer Confirm Action
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: NeoColors.paperCanvas,
                border: Border(
                  top: BorderSide(color: NeoColors.inkSolid, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: NeoButton(
                      onPressed: () => Navigator.of(context).pop(_selected),
                      text: 'ยืนยัน (${_selected.length} ทักษะ)',
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      variant: NeoButtonVariant.primary,
                      height: 46,
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

  Widget _buildCategoryPill(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? NeoColors.electricIndigo : NeoColors.pureWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: NeoColors.inkSolid, width: 1.5),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: NeoColors.inkSolid,
                    offset: Offset(1.5, 1.5),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : NeoColors.inkSolid,
          ),
        ),
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    final isSelected = _isSkillSelected(skill);
    return GestureDetector(
      onTap: () => _toggleSkill(skill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? NeoColors.electricIndigo : NeoColors.surfaceCream,
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
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.add_rounded,
              size: 15,
              color: isSelected ? Colors.white : NeoColors.inkSolid,
            ),
            const Gap(5),
            Text(
              skill,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : NeoColors.inkSolid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
