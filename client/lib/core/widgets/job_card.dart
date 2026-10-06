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
    this.markColor = NeoColors.butterYellow,
    this.onTap,
    this.isSaved = false,
    this.onBookmarkTap,
    this.hasAllowance = false,
    this.allowanceText,
  });

  final String title;
  final String companyName;
  final String province;
  final List<String> details;
  final DateTime? createdAt;
  final Widget? logo;
  final Color markColor;
  final VoidCallback? onTap;
  final bool isSaved;
  final VoidCallback? onBookmarkTap;
  final bool hasAllowance;
  final String? allowanceText;

  @override
  Widget build(BuildContext context) {
    final letter = companyName.trim().isEmpty
        ? '?'
        : companyName.trim().characters.first.toUpperCase();
    final allowance =
        allowanceText ?? (hasAllowance ? 'มีเบี้ยเลี้ยง' : 'ไม่มีเบี้ยเลี้ยง');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: NeoColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NeoColors.inkSolid, width: 2.5),
          boxShadow: NeoShadows.elevation2,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: markColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NeoColors.inkSolid, width: 2),
                    boxShadow: NeoShadows.elevation1,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child:
                        logo ??
                        Center(
                          child: Text(
                            letter,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: NeoColors.inkSolid,
                            ),
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.inkSolid,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: NeoColors.inkSolid,
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
                const SizedBox(width: 8),
                _BookmarkButton(isSaved: isSaved, onPressed: onBookmarkTap),
              ],
            ),
            if (details.any((detail) => detail.trim().isNotEmpty)) ...[
              const SizedBox(height: 12),
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
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: detailChipColor(detail),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: NeoColors.inkSolid,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: NeoColors.inkSolid,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const _DashedRule(),
            const SizedBox(height: 10),
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: hasAllowance
                          ? NeoColors.butterYellow
                          : NeoColors.surfaceCream,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                    ),
                    child: Text(
                      allowance,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: NeoColors.subtleInk,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    postedTimeLabel(createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: NeoColors.subtleInk,
                    ),
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

Color detailChipColor(String detail) {
  return switch (detail) {
    'Online' => NeoColors.skyBlue,
    'Hybrid' => NeoColors.freshMint,
    'On-site' => NeoColors.pastelCoral,
    _ when detail.startsWith('รับ ') => NeoColors.surfaceCream,
    _ => NeoColors.softLilac,
  };
}

class _BookmarkButton extends StatelessWidget {
  const _BookmarkButton({required this.isSaved, required this.onPressed});

  final bool isSaved;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isSaved ? 'ยกเลิกบันทึกงาน' : 'บันทึกงาน',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSaved ? NeoColors.butterYellow : NeoColors.paperCanvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NeoColors.inkSolid, width: 2),
            boxShadow: NeoShadows.elevation1,
          ),
          child: Icon(
            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            size: 18,
            color: NeoColors.inkSolid,
          ),
        ),
      ),
    );
  }
}

class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 2,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter()),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x6618181B)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.square;
    const dash = 6.0;
    const gap = 4.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      final end = (x + dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
