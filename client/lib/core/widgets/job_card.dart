import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/app_tokens.dart';

/// Retro-Chunky Neo-Brutalist Job Card matching Stitch UI specification
class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.title,
    required this.companyName,
    required this.province,
    this.details = const [],
    this.skills = const [],
    this.onTap,
    this.isSaved = false,
    this.onBookmarkTap,
    this.hasAllowance,
    this.allowanceText,
    this.statusText,
    this.isNew = false,
  });

  final String title;
  final String companyName;
  final String province;
  final List<String> details;
  final List<String> skills;
  final VoidCallback? onTap;
  final bool isSaved;
  final VoidCallback? onBookmarkTap;
  final bool? hasAllowance;
  final String? allowanceText;
  final String? statusText;
  final bool isNew;

  Color _getCompanyColor(String name) {
    final initial = name.trim().isEmpty
        ? ''
        : name.trim().substring(0, 1).toUpperCase();
    return switch (initial) {
      'B' => NeoColors.freshMint,
      'L' => NeoColors.pastelCoral,
      'S' => NeoColors.softRose,
      'W' => NeoColors.butterYellow,
      'F' || 'D' => NeoColors.softLilac,
      'M' || 'I' => NeoColors.skyBlue,
      _ => NeoColors.butterYellow,
    };
  }

  Color _getTagColor(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('hybrid')) return NeoColors.softLilac;
    if (lower.contains('remote') || lower.contains('online'))
      return NeoColors.skyBlue;
    if (lower.contains('on-site') || lower.contains('onsite'))
      return NeoColors.paperCanvas;
    if (lower.contains('มีเบี้ยเลี้ยง')) return NeoColors.butterYellow;
    if (lower.contains('ไม่มีเบี้ยเลี้ยง')) return NeoColors.paperCanvas;
    if (lower.contains('figma') || lower.contains('design'))
      return NeoColors.freshMint;
    if (lower.contains('react') ||
        lower.contains('flutter') ||
        lower.contains('sql')) {
      return NeoColors.skyBlue;
    }
    return NeoColors.freshMint;
  }

  @override
  Widget build(BuildContext context) {
    final companyColor = _getCompanyColor(companyName);
    final letter = companyName.trim().isEmpty
        ? '?'
        : String.fromCharCode(companyName.trim().runes.first).toUpperCase();

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Company Mark + Title/Company + Bookmark button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Avatar
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: companyColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NeoColors.inkSolid, width: 1.8),
                    boxShadow: NeoShadows.elevation1,
                  ),
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: NeoColors.inkSolid,
                    ),
                  ),
                ),
                const Gap(10),
                // Title and Company Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: NeoColors.inkSolid,
                              ),
                            ),
                          ),
                          if (isNew) ...[
                            const Gap(6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: NeoColors.pastelCoral,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: NeoColors.inkSolid,
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'ใหม่',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: NeoColors.inkSolid,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Gap(2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              companyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: NeoColors.subtleInk,
                              ),
                            ),
                          ),
                          if (province.trim().isNotEmpty) ...[
                            const Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: NeoColors.subtleInk,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                province,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: NeoColors.subtleInk,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Bookmark Button
                GestureDetector(
                  onTap: onBookmarkTap,
                  child: Container(
                    width: 34,
                    height: 34,
                    margin: const EdgeInsets.only(left: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSaved
                          ? NeoColors.butterYellow
                          : NeoColors.paperCanvas,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: NeoColors.inkSolid, width: 1.8),
                      boxShadow: NeoShadows.elevation1,
                    ),
                    child: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 18,
                      color: NeoColors.inkSolid,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(8),
            // Tags Row
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final detail in details)
                  if (detail.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getTagColor(detail),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: NeoColors.inkSolid,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        detail.trim(),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: NeoColors.inkSolid,
                        ),
                      ),
                    ),
              ],
            ),
            if (skills.isNotEmpty) ...[
              const Gap(6),
              Wrap(
                spacing: 5,
                runSpacing: 4,
                children: [
                  for (final skill in skills.take(3))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: NeoColors.surfaceCream,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: NeoColors.inkSolid, width: 1),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: NeoColors.inkSolid,
                        ),
                      ),
                    ),
                  if (skills.length > 3)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: NeoColors.paperCanvas,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: NeoColors.inkSolid, width: 1),
                      ),
                      child: Text(
                        '+${skills.length - 3}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.subtleInk,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const Gap(8),
            // Dashed Divider
            SizedBox(
              height: 2,
              width: double.infinity,
              child: CustomPaint(painter: _DashedLinePainter()),
            ),
            const Gap(8),
            // Bottom Metadata Row: Allowance pill + Relative time / status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (hasAllowance ?? true)
                          ? NeoColors.butterYellow
                          : NeoColors.paperCanvas,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: NeoColors.inkSolid, width: 1.2),
                    ),
                    child: Text(
                      allowanceText ??
                          ((hasAllowance ?? true)
                              ? 'มีเบี้ยเลี้ยง'
                              : 'ไม่มีเบี้ยเลี้ยง'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                  ),
                ),
                // Status / Time
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: NeoColors.subtleInk,
                    ),
                    const Gap(4),
                    Text(
                      statusText ?? 'เปิดรับสมัคร',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: NeoColors.subtleInk,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NeoColors.inkSolid.withValues(alpha: 0.2)
      ..strokeWidth = 1.5;
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
