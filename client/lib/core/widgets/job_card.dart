import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Shared, bounded layout for feed and saved-job summaries.
class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.title,
    required this.companyName,
    required this.province,
    this.details = const [],
    this.createdAt,
    this.logo,
    this.onTap,
    this.isSaved = false,
    this.onBookmarkTap,
    this.hasAllowance = false,
  });

  final String title;
  final String companyName;
  final String province;
  final List<String> details;
  final DateTime? createdAt;
  final Widget? logo;
  final VoidCallback? onTap;
  final bool isSaved;
  final VoidCallback? onBookmarkTap;
  final bool hasAllowance;

  @override
  Widget build(BuildContext context) {
    final letter = companyName.trim().isEmpty
        ? '?'
        : companyName.trim().characters.first.toUpperCase();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: NeoColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NeoColors.inkSolid, width: 2.2),
          boxShadow: NeoShadows.elevation2,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: NeoColors.butterYellow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        logo ??
                        Center(
                          child: Text(
                            letter,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: NeoColors.subtleInk,
                        ),
                      ),
                      Text(
                        province,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: NeoColors.subtleInk,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isSaved ? 'ยกเลิกบันทึกงาน' : 'บันทึกงาน',
                  onPressed: onBookmarkTap,
                  icon: Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                  ),
                  color: NeoColors.inkSolid,
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final detail in details)
                    if (detail.trim().isNotEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: NeoColors.softLilac,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: NeoColors.inkSolid),
                          ),
                          child: Text(
                            detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  hasAllowance ? 'มีเบี้ยเลี้ยง' : 'ไม่มีเบี้ยเลี้ยง',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  postedTimeLabel(createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: NeoColors.subtleInk,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String postedTimeLabel(DateTime? createdAt, {DateTime? now}) {
  if (createdAt == null) return 'ไม่ระบุวันที่ประกาศ';
  final current = (now ?? DateTime.now()).toLocal();
  final posted = createdAt.toLocal();
  // Calendar dates, not elapsed 24-hour periods; UTC avoids DST boundaries.
  final days = DateTime.utc(
    current.year,
    current.month,
    current.day,
  ).difference(DateTime.utc(posted.year, posted.month, posted.day)).inDays;
  return days <= 0 ? 'วันนี้' : '$days วันที่แล้ว';
}
