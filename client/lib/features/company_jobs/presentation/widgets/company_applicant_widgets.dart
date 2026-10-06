import 'package:flutter/material.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_card.dart';

/// Paper-and-ink surface shared by the company's applicant list and dossier.
class CompanyApplicantCard extends StatelessWidget {
  const CompanyApplicantCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: padding,
    onTap: onTap,
    backgroundColor: NeoColors.pureWhite,
    borderColor: NeoColors.inkSolid,
    borderWidth: 2,
    shadows: NeoShadows.elevation2,
    child: child,
  );
}

String applicantStatusLabel(String status) =>
    switch (status.trim().toLowerCase()) {
      'submitted' => 'ยื่นใบสมัครแล้ว',
      'reviewing' => 'กำลังพิจารณา',
      'accepted' => 'ผ่านการคัดเลือก',
      'rejected' => 'ไม่ผ่านการคัดเลือก',
      _ => status,
    };

class CompanyApplicantStatusChip extends StatelessWidget {
  const CompanyApplicantStatusChip({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status.trim().toLowerCase()) {
      'accepted' => NeoColors.freshMint,
      'reviewing' => NeoColors.softLilac,
      'rejected' => NeoColors.softRose,
      _ => NeoColors.butterYellow,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: NeoColors.inkSolid, width: 1.5),
        boxShadow: NeoShadows.elevation1,
      ),
      child: Text(
        applicantStatusLabel(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: NeoColors.inkSolid,
        ),
      ),
    );
  }
}
