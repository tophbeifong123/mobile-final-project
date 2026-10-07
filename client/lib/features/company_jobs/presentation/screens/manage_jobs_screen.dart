import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/company_top_bar.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../jobs/presentation/job_labels.dart';
import '../../domain/entities/company_job.dart';
import '../providers/company_jobs_controller.dart';

// ── Filter Tab Enum ───────────────────────────────────────────────────────────

enum _FilterTab {
  all('ทั้งหมด', null),
  open('เปิดรับสมัคร', 'open'),
  closed('ปิดรับสมัคร', 'closed');

  const _FilterTab(this.label, this.statusValue);
  final String label;
  final String? statusValue;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ManageJobsScreen extends ConsumerStatefulWidget {
  const ManageJobsScreen({super.key});

  @override
  ConsumerState<ManageJobsScreen> createState() => _ManageJobsScreenState();
}

class _ManageJobsScreenState extends ConsumerState<ManageJobsScreen> {
  _FilterTab _selectedTab = _FilterTab.all;

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(companyJobListProvider);
    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      appBar: const CompanyTopBar(title: 'ประกาศของบริษัท'),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _JobSummary(jobsAsync: jobsAsync),
            _FilterTabBar(
              jobsAsync: jobsAsync,
              selected: _selectedTab,
              onSelect: (tab) => setState(() => _selectedTab = tab),
            ),
            Expanded(
              child: _JobListBody(jobsAsync: jobsAsync, tab: _selectedTab),
            ),
            const _CreateButton(),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _JobSummary extends StatelessWidget {
  const _JobSummary({required this.jobsAsync});
  final AsyncValue<List<CompanyJob>> jobsAsync;

  @override
  Widget build(BuildContext context) {
    final jobs = jobsAsync.asData?.value;
    if (jobs == null) return const SizedBox(height: 12);
    final openCount = jobs.where((job) => job.status == 'open').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(
        'ทั้งหมด ${jobs.length} ตำแหน่ง · เปิดรับ $openCount',
        style: const TextStyle(
          fontSize: 13,
          color: NeoColors.subtleInk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Filter Tab Bar ────────────────────────────────────────────────────────────

class _FilterTabBar extends StatelessWidget {
  const _FilterTabBar({
    required this.jobsAsync,
    required this.selected,
    required this.onSelect,
  });

  final AsyncValue<List<CompanyJob>> jobsAsync;
  final _FilterTab selected;
  final ValueChanged<_FilterTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final jobs = jobsAsync.asData?.value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          for (var index = 0; index < _FilterTab.values.length; index++) ...[
            if (index > 0) const Gap(8),
            Expanded(
              child: _FilterSegment(
                tab: _FilterTab.values[index],
                count: jobs == null
                    ? null
                    : _countFor(_FilterTab.values[index], jobs),
                selected: selected == _FilterTab.values[index],
                onTap: () => onSelect(_FilterTab.values[index]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _countFor(_FilterTab tab, List<CompanyJob> jobs) {
    if (tab.statusValue == null) return jobs.length;
    return jobs.where((job) => job.status == tab.statusValue).length;
  }
}

class _FilterSegment extends StatelessWidget {
  const _FilterSegment({
    required this.tab,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final _FilterTab tab;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? NeoColors.inkSolid : NeoColors.pureWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: NeoColors.inkSolid, width: 1.8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : NeoColors.inkSolid,
                ),
              ),
              if (count != null)
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? NeoColors.butterYellow
                        : NeoColors.subtleInk,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Job List Body ─────────────────────────────────────────────────────────────

class _JobListBody extends ConsumerWidget {
  const _JobListBody({required this.jobsAsync, required this.tab});
  final AsyncValue<List<CompanyJob>> jobsAsync;
  final _FilterTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return jobsAsync.when(
      skipLoadingOnReload: true,
      loading: () => const _JobSkeletonList(),
      error: (error, _) => _ErrorState(error: error),
      data: (items) {
        final filtered = tab.statusValue == null
            ? items
            : items.where((j) => j.status == tab.statusValue).toList();
        if (filtered.isEmpty) {
          return _EmptyState(noJobsAtAll: items.isEmpty);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const Gap(12),
          itemBuilder: (context, index) =>
              _CompanyJobCard(job: filtered[index]),
        );
      },
    );
  }
}

// ── Error & Empty States ──────────────────────────────────────────────────────

class _ErrorState extends ConsumerWidget {
  const _ErrorState({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: NeoColors.pastelCoral,
                border: Border.all(color: NeoColors.inkSolid, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: NeoShadows.elevation2,
              ),
              child: const Icon(
                LucideIcons.alertCircle,
                size: 28,
                color: NeoColors.inkSolid,
              ),
            ),
            const Gap(16),
            const Text(
              'โหลดประกาศไม่ได้',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: NeoColors.inkSolid,
              ),
            ),
            const Gap(6),
            Text(
              userVisibleError(error),
              style: const TextStyle(fontSize: 14, color: NeoColors.subtleInk),
              textAlign: TextAlign.center,
            ),
            const Gap(20),
            NeoButton(
              variant: NeoButtonVariant.outline,
              text: 'ลองอีกครั้ง',
              onPressed: () => ref.invalidate(companyJobListProvider),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.noJobsAtAll});
  final bool noJobsAtAll;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: NeoColors.butterYellow,
                border: Border.all(color: NeoColors.inkSolid, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: NeoShadows.elevation2,
              ),
              child: const Icon(
                LucideIcons.briefcase,
                size: 32,
                color: NeoColors.inkSolid,
              ),
            ),
            const Gap(16),
            Text(
              noJobsAtAll ? 'ยังไม่มีประกาศงาน' : 'ไม่มีประกาศในสถานะนี้',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: NeoColors.inkSolid,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(6),
            Text(
              noJobsAtAll
                  ? 'กดปุ่มด้านล่างเพื่อสร้างประกาศงานแรก'
                  : 'ลองเปลี่ยนตัวกรองเพื่อดูประกาศอื่น',
              style: const TextStyle(fontSize: 14, color: NeoColors.subtleInk),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create Button ─────────────────────────────────────────────────────────────

class _CreateButton extends StatelessWidget {
  const _CreateButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NeoColors.paperCanvas,
        border: Border(top: BorderSide(color: NeoColors.inkSolid, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: NeoButton(
        variant: NeoButtonVariant.primary,
        text: 'สร้างประกาศงานใหม่',
        icon: const Icon(LucideIcons.plus, size: 18),
        isFullWidth: true,
        onPressed: () => context.push('/company/jobs/new'),
      ),
    );
  }
}

// ── Job Card ──────────────────────────────────────────────────────────────────

class _CompanyJobCard extends ConsumerStatefulWidget {
  const _CompanyJobCard({required this.job});
  final CompanyJob job;

  @override
  ConsumerState<_CompanyJobCard> createState() => _CompanyJobCardState();
}

class _CompanyJobCardState extends ConsumerState<_CompanyJobCard> {
  bool _isLoading = false;

  Future<void> _changeStatus(String newStatus) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(companyJobsControllerProvider.notifier)
          .updateJobStatus(jobId: widget.job.id, status: newStatus);
      if (mounted) {
        AppToast.success(
          context,
          newStatus == 'open' ? 'เปิดรับสมัครแล้ว' : 'ปิดรับสมัครแล้ว',
        );
      }
    } catch (e) {
      if (mounted) AppToast.error(context, userVisibleError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final isOpen = job.status == 'open';
    final statusLabel = isOpen ? 'เปิดรับสมัคร' : 'ปิดรับสมัคร';

    return Container(
      decoration: BoxDecoration(
        color: NeoColors.pureWhite,
        border: Border.all(color: NeoColors.inkSolid, width: 2.2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: NeoShadows.elevation2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _StatusBadge(
                      label: statusLabel,
                      color: isOpen
                          ? NeoColors.freshMint
                          : NeoColors.surfaceCream,
                    ),
                    const Spacer(),
                    _StatusAction(
                      label: isOpen ? 'ปิดรับ' : 'เปิดรับ',
                      isLoading: _isLoading,
                      onPressed: () =>
                          _changeStatus(isOpen ? 'closed' : 'open'),
                    ),
                  ],
                ),
                const Gap(8),
                InkWell(
                  onTap: () => context.push('/company/jobs/${job.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        job.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.inkSolid,
                          height: 1.25,
                        ),
                      ),
                      const Gap(8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MetaTag(
                            icon: LucideIcons.monitor,
                            label: workModeLabelFromApi(job.workMode),
                          ),
                          _MetaTag(
                            icon: LucideIcons.calendarCheck,
                            label: interviewModeLabelFromApi(job.interviewMode),
                          ),
                          if (job.deadline != null)
                            _MetaTag(
                              icon: LucideIcons.calendarDays,
                              label: 'ถึง ${_formatDeadline(job.deadline!)}',
                            ),
                        ],
                      ),
                      const Gap(10),
                      _ApplicantLine(
                        applicantCount: job.applicantCount,
                        pendingCount: job.pendingApplicantCount,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1.5, color: NeoColors.inkSolid),
          Padding(
            padding: const EdgeInsets.all(10),
            child: _ActiveActions(jobId: job.id),
          ),
        ],
      ),
    );
  }
}

// ── Card Sub-widgets ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: NeoColors.inkSolid, width: 1.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: NeoColors.inkSolid, offset: Offset(1.5, 1.5)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: NeoColors.inkSolid,
        ),
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: NeoColors.surfaceCream,
        border: Border.all(color: NeoColors.inkSolid, width: 1.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: NeoColors.subtleInk),
          const Gap(4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: NeoColors.inkSolid,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantLine extends StatelessWidget {
  const _ApplicantLine({
    required this.applicantCount,
    required this.pendingCount,
  });

  final int applicantCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(LucideIcons.users, size: 16, color: NeoColors.inkSolid),
        const Gap(6),
        Expanded(
          child: Text(
            'ผู้สมัครทั้งหมด $applicantCount คน',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: NeoColors.inkSolid,
            ),
          ),
        ),
        if (pendingCount > 0) ...[
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: NeoColors.butterYellow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NeoColors.inkSolid, width: 1.4),
            ),
            child: Text(
              '$pendingCount รอตรวจ',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: NeoColors.inkSolid,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusAction extends StatelessWidget {
  const _StatusAction({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NeoColors.pureWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: NeoColors.inkSolid, width: 1.8),
      ),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
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

class _ActiveActions extends StatelessWidget {
  const _ActiveActions({required this.jobId});
  final String jobId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: NeoButton(
            variant: NeoButtonVariant.outline,
            text: 'แก้ไข',
            icon: const Icon(LucideIcons.pencil, size: 16),
            height: 44,
            onPressed: () => context.push('/company/jobs/$jobId/edit'),
          ),
        ),
        const Gap(8),
        Expanded(
          child: NeoButton(
            variant: NeoButtonVariant.secondary,
            text: 'ผู้สมัคร',
            icon: const Icon(LucideIcons.users, size: 16),
            height: 44,
            onPressed: () => context.push('/company/jobs/$jobId/applicants'),
          ),
        ),
      ],
    );
  }
}

// ── Skeleton List ─────────────────────────────────────────────────────────────

class _JobSkeletonList extends StatelessWidget {
  const _JobSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: 3,
        separatorBuilder: (_, _) => const Gap(12),
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: NeoColors.pureWhite,
            border: Border.all(color: NeoColors.inkSolid, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(14),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('สถานะ'),
              Gap(8),
              Text('ตำแหน่งงานตัวอย่าง Flutter Developer Intern'),
              Gap(8),
              Text('On-site · ถึง 31 ธ.ค. 2568'),
              Gap(8),
              Text('ผู้สมัครทั้งหมด 0 คน'),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

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
