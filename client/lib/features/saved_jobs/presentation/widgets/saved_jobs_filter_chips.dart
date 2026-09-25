import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../jobs/domain/entities/job.dart';

/// WorkMode filter item definition
class WorkModeFilterItem {
  const WorkModeFilterItem({
    required this.mode,
    required this.label,
    required this.count,
  });

  final WorkMode? mode;
  final String label;
  final int count;
}

/// Horizontal scrollable WorkMode filter pills for Saved Jobs Screen
class SavedJobsFilterChips extends StatelessWidget {
  const SavedJobsFilterChips({
    super.key,
    required this.selectedMode,
    required this.items,
    required this.onSelected,
  });

  final WorkMode? selectedMode;
  final List<WorkModeFilterItem> items;
  final ValueChanged<WorkMode?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Gap(8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selectedMode == item.mode;

          return GestureDetector(
            onTap: () => onSelected(item.mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? NeoColors.inkSolid : NeoColors.surfaceCream,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: NeoColors.inkSolid,
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: isSelected
                    ? NeoShadows.elevation1
                    : const [
                        BoxShadow(
                          color: NeoColors.inkSolid,
                          offset: Offset(1.5, 1.5),
                          blurRadius: 0,
                        ),
                      ],
              ),
              child: Text(
                '${item.label} (${item.count})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  color: isSelected ? Colors.white : NeoColors.inkSolid,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
