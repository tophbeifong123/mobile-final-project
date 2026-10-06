import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/widgets/job_card.dart';
import '../../domain/entities/job.dart';
import '../job_labels.dart';
import '../providers/jobs_controller.dart';

class StudentJobCard extends ConsumerWidget {
  const StudentJobCard({
    super.key,
    required this.job,
    required this.isSaved,
    this.onTap,
    this.onBookmarkTap,
  });
  final Job job;
  final bool isSaved;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final letter = job.companyName.trim().isEmpty
        ? '?'
        : job.companyName.trim().characters.first.toUpperCase();
    final fallback = Center(child: Text(letter));
    final logo = job.companyLogoAvailable
        ? ref.watch(jobCardLogoProvider(job.id)).asData?.value
        : null;
    Widget? image;
    if (logo != null) {
      image = logo.mimeType.startsWith('image/svg+xml')
          ? SvgPicture.memory(
              Uint8List.fromList(logo.bytes),
              fit: BoxFit.contain,
              semanticsLabel: 'โลโก้บริษัท ${job.companyName}',
              errorBuilder: (_, _, _) => fallback,
            )
          : Image.memory(
              Uint8List.fromList(logo.bytes),
              fit: BoxFit.contain,
              semanticLabel: 'โลโก้บริษัท ${job.companyName}',
              errorBuilder: (_, _, _) => fallback,
            );
    }
    return JobCard(
      title: job.title,
      companyName: job.companyName,
      province: job.province,
      details: [
        job.category,
        workModeLabel(job.workMode),
        if (job.openings != null) 'รับ ${job.openings} คน',
      ],
      createdAt: job.createdAt,
      hasAllowance: job.hasAllowance,
      allowanceText: allowanceLabel(job.hasAllowance, job.allowanceAmount),
      logo: image,
      isSaved: isSaved,
      onTap: onTap,
      onBookmarkTap: onBookmarkTap,
    );
  }
}
