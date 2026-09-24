import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_tokens.dart';

/// Retro-Chunky Neo-Brutalist Pagination Bar
class FeedPaginationBar extends StatelessWidget {
  const FeedPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalItems,
    this.pageSize = 20,
    required this.onPageSelected,
  });

  final int currentPage;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    if (totalItems <= 0) return const SizedBox.shrink();

    final totalPages = (totalItems / pageSize).ceil().clamp(1, 999);
    final from = ((currentPage - 1) * pageSize) + 1;
    final to = (currentPage * pageSize).clamp(1, totalItems);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous Page Button
              _PageButton(
                icon: Icons.arrow_back_rounded,
                isEnabled: currentPage > 1,
                onTap: () => onPageSelected(currentPage - 1),
              ),
              const Gap(6),
              // Page 1
              _PageNumberButton(
                page: 1,
                isSelected: currentPage == 1,
                onTap: () => onPageSelected(1),
              ),
              if (totalPages > 1) ...[
                const Gap(6),
                _PageNumberButton(
                  page: 2,
                  isSelected: currentPage == 2,
                  onTap: () => onPageSelected(2),
                ),
              ],
              if (totalPages > 2) ...[
                const Gap(6),
                _PageNumberButton(
                  page: 3,
                  isSelected: currentPage == 3,
                  onTap: () => onPageSelected(3),
                ),
              ],
              if (totalPages > 4) ...[
                const Gap(4),
                const SizedBox(
                  width: 20,
                  child: Center(
                    child: Text(
                      '...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: NeoColors.subtleInk,
                      ),
                    ),
                  ),
                ),
                const Gap(4),
                _PageNumberButton(
                  page: totalPages,
                  isSelected: currentPage == totalPages,
                  onTap: () => onPageSelected(totalPages),
                ),
              ],
              const Gap(6),
              // Next Page Button
              _PageButton(
                icon: Icons.arrow_forward_rounded,
                isEnabled: currentPage < totalPages,
                onTap: () => onPageSelected(currentPage + 1),
              ),
            ],
          ),
          const Gap(8),
          Text(
            'หน้า $currentPage จาก $totalPages (แสดง $from-$to จาก $totalItems ตำแหน่ง)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: NeoColors.subtleInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isEnabled ? NeoColors.pureWhite : NeoColors.paperCanvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isEnabled ? NeoColors.inkSolid : NeoColors.mutedInk,
            width: 2,
          ),
          boxShadow: isEnabled ? NeoShadows.elevation1 : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? NeoColors.inkSolid : NeoColors.mutedInk,
        ),
      ),
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.page,
    required this.isSelected,
    required this.onTap,
  });

  final int page;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? NeoColors.butterYellow : NeoColors.pureWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: NeoColors.inkSolid, width: 2),
          boxShadow: NeoShadows.elevation1,
        ),
        child: Text(
          '$page',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: NeoColors.inkSolid,
          ),
        ),
      ),
    );
  }
}
