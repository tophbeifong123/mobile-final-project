import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';

/// Neo-Brutalist Search Bar & Filter Button for Student Job Feed
class FeedSearchBar extends StatelessWidget {
  const FeedSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onFilterTap,
    this.hasActiveFilters = false,
    this.badgeCount = 0,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Search Input Container
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: NeoColors.pureWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NeoColors.inkSolid, width: 2.2),
                boxShadow: NeoShadows.elevation2,
              ),
              child: Row(
                children: [
                  const Gap(8),
                  // Lilac Icon Box
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: NeoColors.softLilac,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      size: 15,
                      color: NeoColors.inkSolid,
                    ),
                  ),
                  const Gap(8),
                  // Text Input
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.search,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: NeoColors.inkSolid,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        hintText: 'ค้นหาตำแหน่ง, สกิล, หรือบริษัท...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: NeoColors.mutedInk,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    IconButton(
                      tooltip: 'ล้างคำค้น',
                      onPressed: onClear,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Gap(8),
          // Filter Button with Badge
          GestureDetector(
            onTap: onFilterTap,
            child: Tooltip(
              message: 'ตัวกรอง',
              child: Badge(
                isLabelVisible: badgeCount > 0,
                label: Text('$badgeCount'),
                backgroundColor: NeoColors.electricIndigo,
                textColor: Colors.white,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: NeoColors.butterYellow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NeoColors.inkSolid, width: 2.2),
                    boxShadow: NeoShadows.elevation2,
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 19,
                    color: NeoColors.inkSolid,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
