import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/job_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../company_profile/domain/entities/company_contact_policy.dart';
import '../../../saved_jobs/presentation/providers/saved_jobs_controller.dart';
import '../../../student_profile/domain/entities/student_profile.dart';
import '../../domain/entities/company_logo.dart';
import '../../domain/entities/job.dart';
import '../job_labels.dart';
import '../providers/jobs_controller.dart';
import '../widgets/student_job_card.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(jobDetailProvider(widget.jobId));
    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        toolbarHeight: 64,
        backgroundColor: NeoColors.paperCanvas,
        foregroundColor: NeoColors.inkSolid,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: NeoColors.inkSolid, width: 2),
        ),
        leading: IconButton(
          tooltip: 'กลับ',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/student/home');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'รายละเอียดงาน',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: detail.when(
        loading: () => const LoadingView(label: 'กำลังโหลดประกาศ'),
        error: (error, _) => EmptyState(
          icon: LucideIcons.briefcase,
          title: 'โหลดประกาศไม่ได้',
          message: userVisibleError(error),
          action: NeoButton(
            variant: NeoButtonVariant.outline,
            text: 'ลองอีกครั้ง',
            onPressed: () => ref.invalidate(jobDetailProvider(widget.jobId)),
          ),
        ),
        data: (job) => _JobBody(job: job),
      ),
      bottomNavigationBar: detail.maybeWhen(
        data: (job) => _Actions(
          saving: _saving,
          saved: job.saved,
          onSave: () => _toggleSave(job),
          onApply: () => context.push('/student/jobs/${job.id}/apply'),
        ),
        orElse: () => null,
      ),
    );
  }

  Future<void> _toggleSave(JobDetail job) async {
    setState(() => _saving = true);
    try {
      final repository = ref.read(jobRepositoryProvider);
      if (job.saved) {
        await repository.unsave(job.id);
      } else {
        await repository.save(job.id);
      }
      ref.invalidate(jobDetailProvider(job.id));
      ref.invalidate(savedJobsProvider);
      if (!mounted) return;
      AppToast.success(
        context,
        job.saved ? 'ยกเลิกบันทึกแล้ว' : 'บันทึกงานแล้ว',
      );
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, userVisibleError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _JobBody extends StatelessWidget {
  const _JobBody({required this.job});

  final JobDetail job;

  @override
  Widget build(BuildContext context) {
    final businessType = job.businessType.trim();
    final description = job.description.trim();
    final requirements = job.requirements.trim();
    final skills = job.skills
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _CompanyHero(job: job),
        const Gap(14),
        Text(
          job.title,
          style: const TextStyle(
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: NeoColors.inkSolid,
          ),
        ),
        const Gap(4),
        Text(
          job.companyName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: NeoColors.inkSolid,
          ),
        ),
        if (businessType.isNotEmpty) ...[
          const Gap(2),
          Text(
            businessType,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: NeoColors.subtleInk,
            ),
          ),
        ],
        const Gap(16),
        _FactsCard(job: job),
        if (description.isNotEmpty) ...[
          const Gap(12),
          _SectionCard(
            icon: LucideIcons.fileText,
            iconBg: NeoColors.butterYellow,
            title: 'รายละเอียดงาน',
            body: description,
          ),
        ],
        if (requirements.isNotEmpty || skills.isNotEmpty) ...[
          const Gap(12),
          _RequirementsCard(requirements: requirements, skills: skills),
        ],
        if (_hasCompanyStory(job)) ...[const Gap(12), _CompanyStory(job: job)],
      ],
    );
  }
}

bool _hasCompanyStory(JobDetail job) {
  return job.companyDescription.trim().isNotEmpty ||
      job.companyContactLinks.any((link) => link.value.trim().isNotEmpty) ||
      job.companyWebsiteUrl.trim().isNotEmpty ||
      job.companySize.trim().isNotEmpty ||
      job.companyLocation.trim().isNotEmpty ||
      job.companyPerks.any((perk) => perk.trim().isNotEmpty);
}

class _CompanyHero extends StatelessWidget {
  const _CompanyHero({required this.job});

  final JobDetail job;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 148,
            child: _CompanyCover(job: job),
          ),
          Positioned(left: 0, bottom: 0, child: _CompanyMark(job: job)),
          Positioned(
            right: 0,
            bottom: 6,
            child: _MetaChip(
              icon: LucideIcons.circleCheck,
              label: jobStatusLabel(job.status),
              fill: job.status == JobStatus.open
                  ? NeoColors.freshMint
                  : NeoColors.skyBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactsCard extends StatelessWidget {
  const _FactsCard({required this.job});

  final JobDetail job;

  @override
  Widget build(BuildContext context) {
    final mode = workModeLabel(job.workMode);
    final rows = <(String, String)>[
      ('เบี้ยเลี้ยง', allowanceLabel(job.hasAllowance, job.allowanceAmount)),
      if (job.openings != null) ('จำนวนรับ', 'รับ ${job.openings} คน'),
      if (job.deadline != null) ('ปิดรับ', deadlineLabel(job.deadline!)),
      if (job.createdAt != null) ('ประกาศ', postedTimeLabel(job.createdAt)),
    ];
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลประกาศ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: NeoColors.inkSolid,
            ),
          ),
          const Gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(icon: LucideIcons.mapPin, label: job.province),
              _MetaChip(
                icon: LucideIcons.monitor,
                label: mode,
                fill: detailChipColor(mode),
              ),
              _MetaChip(icon: LucideIcons.tag, label: job.category),
            ],
          ),
          const Gap(12),
          const Divider(color: NeoColors.inkSolid, height: 1, thickness: 1.5),
          for (final row in rows) ...[
            const Gap(10),
            Text(
              row.$1,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: NeoColors.subtleInk,
              ),
            ),
            const Gap(2),
            Text(
              row.$2,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: NeoColors.inkSolid,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard({required this.requirements, required this.skills});

  final String requirements;
  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NeoColors.freshMint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                ),
                child: const Icon(
                  LucideIcons.listChecks,
                  size: 16,
                  color: NeoColors.inkSolid,
                ),
              ),
              const Gap(8),
              const Expanded(
                child: Text(
                  'คุณสมบัติ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.inkSolid,
                  ),
                ),
              ),
            ],
          ),
          if (requirements.isNotEmpty) ...[
            const Gap(10),
            const Divider(color: NeoColors.inkSolid, height: 1, thickness: 1.5),
            const Gap(14),
            Text(
              requirements,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: NeoColors.inkSolid,
              ),
            ),
          ],
          if (skills.isNotEmpty) ...[
            const Gap(12),
            const Text(
              'ทักษะที่ต้องการ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: NeoColors.subtleInk,
              ),
            ),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in skills)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: NeoColors.skyBlue,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CompanyStory extends StatelessWidget {
  const _CompanyStory({required this.job});

  final JobDetail job;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('เว็บไซต์', job.companyWebsiteUrl),
      ('ขนาดองค์กร', job.companySize),
      ('ที่อยู่สำนักงาน', job.companyLocation),
    ].where((row) => row.$2.trim().isNotEmpty).toList();
    final perks = job.companyPerks
        .map((perk) => perk.trim())
        .where((perk) => perk.isNotEmpty)
        .toList();
    final description = job.companyDescription.trim();
    final contacts = job.companyContactLinks
        .where((link) => link.value.trim().isNotEmpty)
        .toList();

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เกี่ยวกับบริษัท',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: NeoColors.inkSolid,
            ),
          ),
          if (description.isNotEmpty) ...[
            const Gap(12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: NeoColors.inkSolid,
              ),
            ),
          ],
          if (contacts.isNotEmpty) ...[
            const Gap(12),
            const Text(
              'ช่องทางติดต่อ',
              key: Key('company-contacts'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: NeoColors.subtleInk,
              ),
            ),
            const Gap(8),
            for (final contact in contacts) ...[
              _ContactLine(contact: contact),
              const Gap(8),
            ],
          ],
          for (final row in rows) ...[
            const Gap(10),
            Text(
              row.$1,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: NeoColors.subtleInk,
              ),
            ),
            const Gap(2),
            Text(
              row.$2.trim(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: NeoColors.inkSolid,
              ),
            ),
          ],
          if (perks.isNotEmpty) ...[
            const Gap(12),
            const Text(
              'สวัสดิการบริษัท',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: NeoColors.subtleInk,
              ),
            ),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final perk in perks)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: NeoColors.butterYellow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                    ),
                    child: Text(
                      perk,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: NeoColors.inkSolid,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.contact});

  final ContactLink contact;

  @override
  Widget build(BuildContext context) {
    final caption = (contact.label != null && contact.label!.trim().isNotEmpty)
        ? contact.label!.trim()
        : companyContactPlatformLabel(contact.platform);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _contactIcon(contact.platform),
          size: 16,
          color: NeoColors.inkSolid,
        ),
        const Gap(8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                caption,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: NeoColors.subtleInk,
                ),
              ),
              SelectableText(
                contact.value.trim(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: NeoColors.inkSolid,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

IconData _contactIcon(String platform) {
  return switch (platform.toLowerCase()) {
    'phone' => Icons.phone_rounded,
    'email' => Icons.email_rounded,
    'line' => Icons.chat_bubble_rounded,
    'linkedin' => Icons.work_rounded,
    'facebook' => Icons.facebook_rounded,
    'instagram' => Icons.camera_alt_rounded,
    _ => Icons.link_rounded,
  };
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.saving,
    required this.saved,
    required this.onSave,
    required this.onApply,
  });

  final bool saving;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NeoColors.paperCanvas,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: NeoColors.inkSolid, width: 2)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: NeoButton(
                  variant: NeoButtonVariant.outline,
                  text: saved ? 'ยกเลิกบันทึก' : 'บันทึก',
                  isLoading: saving,
                  onPressed: saving ? null : onSave,
                ),
              ),
              const Gap(12),
              Expanded(
                child: NeoButton(text: 'สมัครงาน', onPressed: onApply),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyCover extends ConsumerStatefulWidget {
  const _CompanyCover({required this.job});

  final JobDetail job;

  @override
  ConsumerState<_CompanyCover> createState() => _CompanyCoverState();
}

class _CompanyCoverState extends ConsumerState<_CompanyCover> {
  CompanyLogo? _shown;
  Uint8List? _bytes;

  @override
  Widget build(BuildContext context) {
    final color = companyMarkColor(widget.job.category);
    if (widget.job.companyCoverAvailable) {
      final asyncCover = ref.watch(jobCompanyCoverProvider(widget.job.id));
      final incoming = asyncCover.asData?.value ?? _shown;
      if (incoming != null && !_sameLogo(incoming, _shown)) {
        _shown = incoming;
        _bytes = Uint8List.fromList(incoming.bytes);
      }
    }
    final shown = _shown;
    final bytes = _bytes;
    final label = 'รูปหน้าปกบริษัท ${widget.job.companyName}';
    return Container(
      key: const Key('company-cover'),
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoColors.inkSolid, width: 2.5),
        boxShadow: NeoShadows.elevation2,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CoverFallback(color: color),
          if (shown != null && bytes != null)
            Positioned.fill(
              child: shown.mimeType.startsWith('image/svg+xml')
                  ? SvgPicture.memory(
                      bytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      semanticsLabel: label,
                    )
                  : Image.memory(
                      bytes,
                      key: const Key('company-cover-image'),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      gaplessPlayback: true,
                      semanticLabel: label,
                    ),
            ),
        ],
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Center(
        child: Icon(
          Icons.apartment_rounded,
          size: 56,
          color: NeoColors.inkSolid.withValues(alpha: 0.16),
        ),
      ),
    );
  }
}

class _CompanyMark extends ConsumerStatefulWidget {
  const _CompanyMark({required this.job});

  final JobDetail job;

  @override
  ConsumerState<_CompanyMark> createState() => _CompanyMarkState();
}

class _CompanyMarkState extends ConsumerState<_CompanyMark> {
  CompanyLogo? _shown;
  Widget? _picture;

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.job.companyName.trim();
    final letter = trimmed.isEmpty
        ? '?'
        : trimmed.characters.first.toUpperCase();
    final fallback = Center(
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: NeoColors.inkSolid,
        ),
      ),
    );
    Widget child = fallback;
    if (widget.job.companyLogoAvailable) {
      final asyncLogo = ref.watch(jobCompanyLogoProvider(widget.job.id));
      final incoming = asyncLogo.asData?.value ?? _shown;
      if (incoming != null) {
        if (!_sameLogo(incoming, _shown)) {
          _shown = incoming;
          final bytes = Uint8List.fromList(incoming.bytes);
          final label = 'โลโก้บริษัท ${widget.job.companyName}';
          _picture = incoming.mimeType.startsWith('image/svg+xml')
              ? SvgPicture.memory(
                  bytes,
                  fit: BoxFit.contain,
                  semanticsLabel: label,
                  errorBuilder: (_, _, _) => fallback,
                )
              : Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  semanticLabel: label,
                  errorBuilder: (_, _, _) => fallback,
                );
        }
        child = _picture ?? fallback;
      }
    }
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: NeoColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoColors.inkSolid, width: 3),
        boxShadow: NeoShadows.elevation2,
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(10), child: child),
    );
  }
}

bool _sameLogo(CompanyLogo incoming, CompanyLogo? shown) {
  if (shown == null || incoming.mimeType != shown.mimeType) return false;
  if (incoming.bytes.length != shown.bytes.length) return false;
  for (var index = 0; index < incoming.bytes.length; index++) {
    if (incoming.bytes[index] != shown.bytes[index]) return false;
  }
  return true;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                ),
                child: Icon(icon, size: 16, color: NeoColors.inkSolid),
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.inkSolid,
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),
          const Divider(color: NeoColors.inkSolid, height: 1, thickness: 1.5),
          const Gap(14),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: NeoColors.inkSolid,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.fill});

  final IconData icon;
  final String label;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fill ?? NeoColors.surfaceCream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NeoColors.inkSolid, width: 1.4),
        boxShadow: NeoShadows.elevation1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: NeoColors.inkSolid),
          const Gap(6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: NeoColors.inkSolid,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoColors.inkSolid, width: 2.2),
        boxShadow: NeoShadows.elevation2,
      ),
      child: child,
    );
  }
}
