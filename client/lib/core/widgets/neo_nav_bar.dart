import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

@immutable
class NeoNavBarItem {
  const NeoNavBarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class NeoNavBar extends StatelessWidget {
  const NeoNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<NeoNavBarItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NeoColors.pureWhite,
        border: Border(top: BorderSide(color: NeoColors.inkSolid, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: _NeoNavItem(
                    item: items[i],
                    isSelected: i == selectedIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeoNavItem extends StatelessWidget {
  const _NeoNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final NeoNavBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? NeoColors.butterYellow : Colors.transparent,
          border: Border.all(
            color: isSelected ? NeoColors.inkSolid : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isSelected ? NeoColors.inkSolid : Colors.transparent,
              offset: const Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 22,
              color: isSelected ? NeoColors.inkSolid : NeoColors.mutedInk,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? NeoColors.inkSolid : NeoColors.mutedInk,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
