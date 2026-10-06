import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              IconButton(
                tooltip: 'หน้าก่อนหน้า',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: currentPage > 1
                    ? () => onPageSelected(currentPage - 1)
                    : null,
              ),
              for (
                var page = start;
                page <= totalPages && page < start + 3;
                page++
              )
                OutlinedButton(
                  onPressed: page == currentPage
                      ? null
                      : () => onPageSelected(page),
                  child: Text('$page'),
                ),
              IconButton(
                tooltip: 'หน้าถัดไป',
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: currentPage < totalPages
                    ? () => onPageSelected(currentPage + 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'หน้า $currentPage จาก $totalPages (แสดง $from-$to จาก $totalItems ตำแหน่ง)',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
