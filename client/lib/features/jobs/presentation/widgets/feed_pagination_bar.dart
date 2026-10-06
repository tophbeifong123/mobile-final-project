import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

class FeedPaginationBar extends StatelessWidget {
  const FeedPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.totalPages,
    this.pageSize = 20,
    required this.onPageSelected,
  });

  final int currentPage;
  final int totalItems;
  final int totalPages;
  final int pageSize;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    if (totalItems <= 0 || totalPages <= 0) return const SizedBox.shrink();
    final start = (currentPage - 1).clamp(
      1,
      totalPages > 2 ? totalPages - 2 : 1,
    );
    final from = (currentPage - 1) * pageSize + 1;
    final to = (currentPage * pageSize).clamp(1, totalItems);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ArrowButton(
                tooltip: 'หน้าก่อนหน้า',
                icon: Icons.arrow_back_rounded,
                onPressed: currentPage > 1
                    ? () => onPageSelected(currentPage - 1)
                    : null,
              ),
              for (
                var page = start;
                page <= totalPages && page < start + 3;
                page++
              )
                _PageChip(
                  page: page,
                  selected: page == currentPage,
                  onPressed: () => onPageSelected(page),
                ),
              _ArrowButton(
                tooltip: 'หน้าถัดไป',
                icon: Icons.arrow_forward_rounded,
                onPressed: currentPage < totalPages
                    ? () => onPageSelected(currentPage + 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'หน้า $currentPage จาก $totalPages (แสดง $from-$to จาก $totalItems ตำแหน่ง)',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: NeoColors.subtleInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: enabled ? NeoShadows.elevation1 : const [],
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: NeoColors.inkSolid,
        disabledColor: NeoColors.mutedInk,
        style: IconButton.styleFrom(
          backgroundColor: NeoColors.pureWhite,
          disabledBackgroundColor: NeoColors.surfaceCream,
          foregroundColor: NeoColors.inkSolid,
          side: const BorderSide(color: NeoColors.inkSolid, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          fixedSize: const Size(40, 40),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _PageChip extends StatelessWidget {
  const _PageChip({
    required this.page,
    required this.selected,
    required this.onPressed,
  });

  final int page;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: NeoShadows.elevation1,
      ),
      child: Material(
        color: selected ? NeoColors.butterYellow : NeoColors.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: NeoColors.inkSolid, width: 2),
        ),
        child: InkWell(
          onTap: selected ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Text(
                '$page',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: NeoColors.inkSolid,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
