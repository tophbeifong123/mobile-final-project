import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/company_top_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../jobs/presentation/job_labels.dart';
import '../../domain/entities/company_job.dart';
import '../providers/company_jobs_controller.dart';

class CompanyJobDetailScreen extends ConsumerStatefulWidget {
  const CompanyJobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<CompanyJobDetailScreen> createState() =>
      _CompanyJobDetailScreenState();
}

class _CompanyJobDetailScreenState
    extends ConsumerState<CompanyJobDetailScreen> {
  bool _updatingStatus = false;

  Future<void> _changeStatus(CompanyOwnedJob job) async {
    if (_updatingStatus) return;
    final next = job.status == 'open' ? 'closed' : 'open';
    setState(() => _updatingStatus = true);
    try {
      await ref
          .read(companyJobsControllerProvider.notifier)
          .updateJobStatus(jobId: job.id, status: next);
      if (mounted) {
        AppToast.success(
          context,
          next == 'open' ? 'เปิดรับสมัครแล้ว' : 'ปิดรับสมัครแล้ว',
        );
      }
    } catch (error) {
      if (mounted) AppToast.error(context, userVisibleError(error));
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Future<void> _openEdit(CompanyOwnedJob job) async {
    await context.push('/company/jobs/${job.id}/edit');
    ref.invalidate(companyOwnedJobProvider(job.id));
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(companyOwnedJobProvider(widget.jobId));
    final wide = MediaQuery.sizeOf(context).width >= 960;

    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      appBar: CompanyTopBar(
        title: 'รายละเอียดประกาศ',
        showBack: true,
        backLocation: '/company/jobs',
      ),
      body: jobAsync.when(
        loading: () => const LoadingView(label: 'กำลังโหลดประกาศ'),
        error: (error, _) => EmptyState(
          icon: LucideIcons.briefcase,
          title: 'โหลดประกาศไม่ได้',
          message: userVisibleError(error),
          action: NeoButton(
            variant: NeoButtonVariant.outline,
            text: 'ลองอีกครั้ง',
            onPressed: () =>
                ref.invalidate(companyOwnedJobProvider(widget.jobId)),
          ),
        ),
        data: (job) => _DetailFrame(
          wide: wide,
          posting: _PostingColumn(job: job),
          panel: _ManagePanel(
            job: job,
            updating: _updatingStatus,
            onApplicants: () =>
                context.push('/company/jobs/${job.id}/applicants'),
            onEdit: () => _openEdit(job),
            onToggleStatus: () => _changeStatus(job),
          ),
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : jobAsync.maybeWhen(
              data: (job) => _ManagePanel(
                job: job,
                updating: _updatingStatus,
                pinned: true,
                onApplicants: () =>
                    context.push('/company/jobs/${job.id}/applicants'),
                onEdit: () => _openEdit(job),
                onToggleStatus: () => _changeStatus(job),
              ),
              orElse: () => null,
            ),
    );
  }
}

class _DetailFrame extends StatelessWidget {
  const _DetailFrame({
    required this.wide,
    required this.posting,
    required this.panel,
  });

  final bool wide;
  final Widget posting;
  final Widget panel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: wide
            ? Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: posting),
                    const Gap(24),
                    SizedBox(
                      width: 320,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SingleChildScrollView(child: panel),
                      ),
                    ),
                  ],
                ),
              )
            : posting,
      ),
    );
  }
}

class _PostingColumn extends StatelessWidget {
  const _PostingColumn({required this.job});

  final CompanyOwnedJob job;

  @override
  Widget build(BuildContext context) {
    final closed = job.status == 'closed';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
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
        const Gap(12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusBadge(open: job.status == 'open'),
            if (job.province.trim().isNotEmpty)
              _MetaChip(icon: LucideIcons.mapPin, label: job.province),
            _MetaChip(
              icon: LucideIcons.monitor,
              label: _workModeLabel(job.workMode),
            ),
            if (job.category.trim().isNotEmpty)
              _MetaChip(icon: LucideIcons.tag, label: job.category),
            if (job.openings != null)
              _MetaChip(
                icon: LucideIcons.users,
                label: 'รับ ${job.openings} คน',
              ),
            _MetaChip(
              icon: LucideIcons.wallet,
              label: allowanceLabel(job.hasAllowance, job.allowanceAmount),
              fill: job.hasAllowance
                  ? NeoColors.butterYellow
                  : NeoColors.pureWhite,
            ),
            if (job.deadline != null)
              _MetaChip(
                icon: LucideIcons.calendarDays,
                label: 'ถึง ${_formatDeadline(job.deadline!)}',
              ),
          ],
        ),
        if (closed) ...[const Gap(16), const _ClosedNotice()],
        if (job.description.trim().isNotEmpty) ...[
          const Gap(16),
          _SectionCard(
            icon: LucideIcons.fileText,
            iconBg: NeoColors.butterYellow,
            title: 'รายละเอียดงาน',
            body: job.description.trim(),
          ),
        ],
        if (job.requirements.trim().isNotEmpty) ...[
          const Gap(12),
          _SectionCard(
            icon: LucideIcons.listChecks,
            iconBg: NeoColors.freshMint,
            title: 'คุณสมบัติ',
            body: job.requirements.trim(),
          ),
        ],
        if (job.skills.isNotEmpty) ...[
          const Gap(12),
          _SkillsCard(skills: job.skills),
        ],
      ],
    );
  }
}

class _ManagePanel extends StatelessWidget {
  const _ManagePanel({
    required this.job,
    required this.updating,
    required this.onApplicants,
    required this.onEdit,
    required this.onToggleStatus,
    this.pinned = false,
  });

  final CompanyOwnedJob job;
  final bool updating;
  final VoidCallback onApplicants;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final open = job.status == 'open';
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ผู้สมัครทั้งหมด ${job.applicantCount} คน',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: NeoColors.inkSolid,
          ),
        ),
        if (job.pendingApplicantCount > 0) ...[
          const Gap(6),
          Text(
            '${job.pendingApplicantCount} ใบรอตรวจ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: NeoColors.subtleInk,
            ),
          ),
        ],
        const Gap(14),
        NeoButton(
          variant: NeoButtonVariant.secondary,
          text: 'ดูผู้สมัคร',
          icon: const Icon(LucideIcons.users, size: 18),
          isFullWidth: true,
          isLoading: updating,
          onPressed: onApplicants,
        ),
        const Gap(8),
        NeoButton(
          variant: NeoButtonVariant.outline,
          text: 'แก้ไขประกาศ',
          icon: const Icon(LucideIcons.pencil, size: 18),
          isFullWidth: true,
          isLoading: updating,
          onPressed: onEdit,
        ),
        const Gap(8),
        NeoButton(
          variant: open ? NeoButtonVariant.surface : NeoButtonVariant.primary,
          text: open ? 'ปิดรับสมัคร' : 'เปิดรับสมัครอีกครั้ง',
          icon: Icon(open ? LucideIcons.x : LucideIcons.check, size: 18),
          isFullWidth: true,
          isLoading: updating,
          onPressed: onToggleStatus,
        ),
      ],
    );

    if (pinned) {
      return Material(
        color: NeoColors.paperCanvas,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: NeoColors.inkSolid, width: 2),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: content,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoColors.inkSolid, width: 2.2),
        boxShadow: NeoShadows.elevation2,
      ),
      child: content,
    );
  }
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeoColors.inkSolid, width: 2.2),
        boxShadow: NeoShadows.elevation2,
      ),
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

class _SkillsCard extends StatelessWidget {
  const _SkillsCard({required this.skills});

  final List<String> skills;

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
                  color: NeoColors.softLilac,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  size: 16,
                  color: NeoColors.inkSolid,
                ),
              ),
              const Gap(8),
              const Expanded(
                child: Text(
                  'ทักษะที่ต้องการ',
                  style: TextStyle(
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in skills)
                if (skill.trim().isNotEmpty)
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
                      skill.trim(),
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
      ),
    );
  }
}

class _ClosedNotice extends StatelessWidget {
  const _ClosedNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NeoColors.skyBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NeoColors.inkSolid, width: 1.8),
      ),
      child: const Text(
        'ปิดรับสมัครแล้ว นักศึกษาไม่เห็นประกาศนี้ในหน้าแรก',
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: NeoColors.inkSolid,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: open ? NeoColors.freshMint : NeoColors.skyBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NeoColors.inkSolid, width: 1.5),
        boxShadow: NeoShadows.elevation1,
      ),
      child: Text(
        open ? 'เปิดรับสมัคร' : 'ปิดรับสมัคร',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: NeoColors.inkSolid,
        ),
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

String _workModeLabel(String workMode) {
  return switch (workMode) {
    'on_site' => 'On-site',
    'hybrid' => 'Hybrid',
    'remote' => 'Remote',
    _ => workMode,
  };
}

String _formatDeadline(DateTime deadline) {
  const months = [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];
  return '${deadline.day} ${months[deadline.month - 1]} ${deadline.year + 543}';
}
