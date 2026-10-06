import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/job_card.dart';
import '../../domain/entities/company_logo.dart';
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
      markColor: companyMarkColor(job.category),
      logo: job.companyLogoAvailable
          ? _StableCompanyLogo(
              jobId: job.id,
              companyName: job.companyName,
              fallback: Center(
                child: Text(
                  letter,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            )
          : null,
      isSaved: isSaved,
      onTap: onTap,
      onBookmarkTap: onBookmarkTap,
    );
  }
}

Color companyMarkColor(String category) {
  return switch (category) {
    'IT & Software' => NeoColors.skyBlue,
    'Design & UX/UI' => NeoColors.pastelCoral,
    'Marketing' => NeoColors.softRose,
    'Data' => NeoColors.softLilac,
    _ => NeoColors.butterYellow,
  };
}

/// Keeps the decoded logo across bookmark rebuilds.
/// A new [Image.memory] each frame treats the bytes as a new picture and flashes.
class _StableCompanyLogo extends ConsumerStatefulWidget {
  const _StableCompanyLogo({
    required this.jobId,
    required this.companyName,
    required this.fallback,
  });

  final String jobId;
  final String companyName;
  final Widget fallback;

  @override
  ConsumerState<_StableCompanyLogo> createState() => _StableCompanyLogoState();
}

class _StableCompanyLogoState extends ConsumerState<_StableCompanyLogo> {
  CompanyLogo? _shown;
  Widget? _picture;

  @override
  Widget build(BuildContext context) {
    final asyncLogo = ref.watch(jobCardLogoProvider(widget.jobId));
    final incoming = asyncLogo.asData?.value ?? _shown;
    if (incoming == null) return widget.fallback;
    if (!identical(incoming, _shown)) {
      _shown = incoming;
      final bytes = Uint8List.fromList(incoming.bytes);
      final label = 'โลโก้บริษัท ${widget.companyName}';
      _picture = incoming.mimeType.startsWith('image/svg+xml')
          ? SvgPicture.memory(
              bytes,
              fit: BoxFit.contain,
              semanticsLabel: label,
              errorBuilder: (_, _, _) => widget.fallback,
            )
          : Image.memory(
              bytes,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              semanticLabel: label,
              errorBuilder: (_, _, _) => widget.fallback,
            );
    }
    return _picture ?? widget.fallback;
  }
}
