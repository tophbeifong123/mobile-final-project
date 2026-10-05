import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../domain/entities/company_job.dart';
import '../providers/company_jobs_controller.dart';

// ── Filter Tab Enum ───────────────────────────────────────────────────────────

enum _FilterTab {
  all('ทั้งหมด', null),
  open('เปิดรับสมัคร', 'open'),
  draft('ฉบับร่าง', 'draft'),
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(jobsAsync: jobsAsync),
            _FilterTabBar(
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

class _Header extends StatelessWidget {
  const _Header({required this.jobsAsync});
  final AsyncValue<List<CompanyJob>> jobsAsync;

  @override
  Widget build(BuildContext context) {
    final count = jobsAsync.asData?.value.length ?? 0;
    return Container(
      color: NeoColors.paperCanvas,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: NeoColors.electricIndigo,
              border: Border.all(color: NeoColors.inkSolid, width: 1.5),
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: NeoColors.inkSolid, offset: Offset(1.5, 1.5)),
              ],
            ),
            child: const Text(
              'RECRUITER HUB',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const Gap(8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'จัดการตำแหน่งงาน',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: NeoColors.inkSolid,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: NeoColors.electricIndigo,
                  border: Border.all(color: NeoColors.inkSolid, width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: NeoColors.inkSolid,
                      offset: Offset(1.5, 1.5),
                    ),
                  ],
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Gap(8),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: NeoColors.softLilac,
                  border: Border.all(color: NeoColors.inkSolid, width: 1.8),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: NeoColors.inkSolid, offset: Offset(2, 2)),
                  ],
                ),
                child: const Icon(
                  LucideIcons.award,
                  size: 20,
                  color: NeoColors.inkSolid,
                ),
              ),
            ],
          ),
          const Gap(4),
          const Text(
            'สร้าง แก้ไข และจัดการประกาศงานทั้งหมดของบริษัทคุณ',
            style: TextStyle(
              fontSize: 13,
              color: NeoColors.subtleInk,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Tab Bar ────────────────────────────────────────────────────────────

class _FilterTabBar extends StatelessWidget {
  const _FilterTabBar({required this.selected, required this.onSelect});
  final _FilterTab selected;
  final ValueChanged<_FilterTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NeoColors.surfaceCream,
        border: Border.symmetric(
          horizontal: BorderSide(color: NeoColors.inkSolid, width: 1.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: _FilterTab.values.map((tab) {
            final isActive = selected == tab;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? NeoColors.inkSolid : NeoColors.pureWhite,
                    border: Border.all(color: NeoColors.inkSolid, width: 1.8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isActive
                        ? null
                        : const [
                            BoxShadow(
                              color: NeoColors.inkSolid,
                              offset: Offset(1.5, 1.5),
                            ),
                          ],
                  ),
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : NeoColors.inkSolid,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: filtered.length + 1,
          separatorBuilder: (_, _) => const Gap(12),
          itemBuilder: (context, index) {
            if (index == filtered.length) return const _RecruiterTipCard();
            return _CompanyJobCard(job: filtered[index]);
          },
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบประกาศ?'),
        content: Text(
          'ต้องการลบ "${widget.job.title}" หรือไม่? การกระทำนี้ไม่สามารถยกเลิกได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: NeoColors.errorText),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(companyJobsControllerProvider.notifier)
          .remove(widget.job.id);
      if (mounted) AppToast.info(context, 'ลบประกาศแล้ว');
    } catch (e) {
      if (mounted) AppToast.error(context, userVisibleError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final isDraft = job.status == 'draft';
    final isOpen = job.status == 'open';

    final badgeColor = isDraft
        ? NeoColors.pastelCoral
        : isOpen
        ? NeoColors.freshMint
        : NeoColors.skyBlue;
    final statusLabel = isDraft
        ? 'ฉบับร่าง'
        : isOpen
        ? 'เปิดรับสมัคร'
        : 'ปิดรับสมัคร';

    return Container(
      decoration: BoxDecoration(
        color: isDraft ? NeoColors.surfaceCream : NeoColors.pureWhite,
        border: Border.all(
          color: NeoColors.inkSolid,
          width: isDraft ? 2.0 : 2.5,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isDraft ? NeoShadows.elevation1 : NeoShadows.elevation2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card Header ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusBadge(label: statusLabel, color: badgeColor),
                      const Gap(6),
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: NeoColors.inkSolid,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isDraft) ...[
                  const Gap(8),
                  _MoreMenuButton(
                    isOpen: isOpen,
                    isLoading: _isLoading,
                    onToggle: () => _changeStatus(isOpen ? 'closed' : 'open'),
                  ),
                ],
              ],
            ),
          ),
          const Gap(10),
          // ── Meta Tags ───────────────────────────────────────────
          if (!isDraft)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MetaTag(
                    icon: LucideIcons.monitor,
                    label: _workModeLabel(job.workMode),
                  ),
                  if (job.deadline != null)
                    _MetaTag(
                      icon: LucideIcons.calendarDays,
                      label: 'ถึง ${_formatDeadline(job.deadline!)}',
                    ),
                ],
              ),
            ),
          if (!isDraft) const Gap(10),
          // ── Applicant Ribbon ────────────────────────────────────
          if (!isDraft)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _ApplicantRibbon(
                applicantCount: job.applicantCount,
                pendingCount: job.pendingApplicantCount,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: const _DraftApplicantBadge(),
            ),
          const Gap(12),
          // ── Divider & Actions ───────────────────────────────────
          const Divider(height: 1, thickness: 1, color: NeoColors.inkSolid),
          Padding(
            padding: const EdgeInsets.all(10),
            child: isDraft
                ? _DraftActions(
                    isLoading: _isLoading,
                    onDelete: _delete,
                    jobId: job.id,
                  )
                : _ActiveActions(isLoading: _isLoading, jobId: job.id),
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

class _ApplicantRibbon extends StatelessWidget {
  const _ApplicantRibbon({
    required this.applicantCount,
    required this.pendingCount,
  });
  final int applicantCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: NeoColors.butterYellow,
        border: Border.all(color: NeoColors.inkSolid, width: 1.5),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: NeoColors.inkSolid, offset: Offset(1.5, 1.5)),
        ],
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.users, size: 16, color: NeoColors.inkSolid),
          const Gap(8),
          Expanded(
            child: Text(
              'ผู้สมัครทั้งหมด $applicantCount คน',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: NeoColors.inkSolid,
              ),
            ),
          ),
          if (pendingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: NeoColors.inkSolid,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$pendingCount รอพิจารณา',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DraftApplicantBadge extends StatelessWidget {
  const _DraftApplicantBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: NeoColors.surfaceCream,
            border: Border.all(color: NeoColors.mutedInk, width: 1.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.users, size: 13, color: NeoColors.mutedInk),
              Gap(4),
              Text(
                '0 ผู้สมัคร',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: NeoColors.mutedInk,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreMenuButton extends StatelessWidget {
  const _MoreMenuButton({
    required this.isOpen,
    required this.isLoading,
    required this.onToggle,
  });
  final bool isOpen;
  final bool isLoading;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      enabled: !isLoading,
      onSelected: (value) {
        if (value == 'toggle') onToggle();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: NeoColors.pureWhite,
          border: Border.all(color: NeoColors.inkSolid, width: 1.5),
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(color: NeoColors.inkSolid, offset: Offset(1.5, 1.5)),
          ],
        ),
        child: const Icon(
          LucideIcons.ellipsisVertical,
          size: 16,
          color: NeoColors.inkSolid,
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                isOpen ? LucideIcons.x : LucideIcons.check,
                size: 16,
                color: NeoColors.inkSolid,
              ),
              const Gap(8),
              Text(isOpen ? 'ปิดรับสมัคร' : 'เปิดรับสมัครอีกครั้ง'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveActions extends StatelessWidget {
  const _ActiveActions({required this.isLoading, required this.jobId});
  final bool isLoading;
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
            isLoading: isLoading,
            onPressed: () => context.push('/company/jobs/$jobId/edit'),
          ),
        ),
        const Gap(8),
        Expanded(
          child: NeoButton(
            variant: NeoButtonVariant.secondary,
            text: 'ผู้สมัคร',
            icon: const Icon(LucideIcons.users, size: 16),
            isLoading: isLoading,
            onPressed: () => context.push('/company/jobs/$jobId/applicants'),
          ),
        ),
      ],
    );
  }
}

class _DraftActions extends StatelessWidget {
  const _DraftActions({
    required this.isLoading,
    required this.onDelete,
    required this.jobId,
  });
  final bool isLoading;
  final VoidCallback onDelete;
  final String jobId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NeoButton(
          variant: NeoButtonVariant.destructive,
          text: 'ลบ',
          icon: const Icon(LucideIcons.trash2, size: 16),
          isLoading: isLoading,
          onPressed: onDelete,
        ),
        const Gap(8),
        Expanded(
          child: NeoButton(
            variant: NeoButtonVariant.primary,
            text: 'แก้ไขต่อ & เผยแพร่',
            icon: const Icon(LucideIcons.send, size: 16),
            isLoading: isLoading,
            onPressed: () => context.push('/company/jobs/$jobId/edit'),
          ),
        ),
      ],
    );
  }
}

// ── Recruiter Tip Card ────────────────────────────────────────────────────────

class _RecruiterTipCard extends StatelessWidget {
  const _RecruiterTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoColors.butterYellow,
        border: Border.all(color: NeoColors.inkSolid, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: NeoShadows.elevation1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: NeoColors.pureWhite,
              border: Border.all(color: NeoColors.inkSolid, width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              LucideIcons.lightbulb,
              size: 18,
              color: NeoColors.inkSolid,
            ),
          ),
          const Gap(12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recruiter Tip',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: NeoColors.inkSolid,
                  ),
                ),
                Gap(4),
                Text(
                  'ประกาศที่มีข้อมูลครบถ้วนได้รับผู้สมัครมากกว่า 3 เท่า '
                  'ลองเพิ่มทักษะที่ต้องการและวันสิ้นสุดการรับสมัครให้ครบนะ!',
                  style: TextStyle(
                    fontSize: 12,
                    color: NeoColors.inkSolid,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              Text('ออนไซต์ · ถึง 31 ธ.ค. 2568'),
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

String _workModeLabel(String workMode) {
  switch (workMode) {
    case 'on_site':
      return 'ออนไซต์';
    case 'hybrid':
      return 'ไฮบริด';
    case 'remote':
      return 'รีโมต';
    default:
      return workMode;
  }
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
