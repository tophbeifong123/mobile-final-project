import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../company_jobs/domain/entities/company_job.dart';
import '../../../company_jobs/presentation/providers/company_jobs_controller.dart';
import '../../domain/dashboard_attention.dart';
import '../../domain/entities/company_dashboard_summary.dart';
import '../providers/company_dashboard_controller.dart';

class CompanyDashboardScreen extends ConsumerStatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  ConsumerState<CompanyDashboardScreen> createState() =>
      _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState
    extends ConsumerState<CompanyDashboardScreen> {
  GoRouter? _router;
  String? _lastPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (identical(router, _router)) return;
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _router = router;
    _lastPath = router?.state.uri.path;
    router?.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    if (!mounted || _router == null) return;
    final path = _router!.state.uri.path;
    final returnedToDashboard =
        path == '/company/dashboard' && _lastPath != null && _lastPath != path;
    _lastPath = path;
    if (!returnedToDashboard) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reload();
    });
  }

  void _reload() {
    ref.invalidate(companyDashboardSummaryProvider);
    ref.invalidate(companyJobListProvider);
  }

  Future<void> _refresh() {
    return Future.wait([
      ref.refresh(companyDashboardSummaryProvider.future),
      ref.refresh(companyJobListProvider.future),
    ]);
  }

  Future<void> _open(String path) async {
    await context.push<void>(path);
    if (context.mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(companyDashboardSummaryProvider);
    final jobsAsync = ref.watch(companyJobListProvider);

    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      appBar: const CompanyTopBar(title: 'แดชบอร์ดบริษัท'),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              kPagePadding,
              16,
              kPagePadding,
              24,
            ),
            children: [
              Text(
                'สรุปของบริษัท และงานที่ควรทำตอนนี้',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.mutedForeground,
                ),
              ),
              const Gap(20),
              summaryAsync.when(
                skipLoadingOnReload: true,
                loading: () => const _StatGridSkeleton(),
                error: (error, _) => AppErrorView(
                  title: 'โหลดข้อมูลแดชบอร์ดไม่สำเร็จ',
                  message: userVisibleError(error),
                  onRetry: _reload,
                ),
                data: (summary) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatGrid(summary: summary),
                    const Gap(24),
                    jobsAsync.when(
                      skipLoadingOnReload: true,
                      loading: () => const _ActionSkeleton(),
                      error: (error, _) => AppErrorView(
                        title: 'โหลดรายการที่ต้องทำไม่สำเร็จ',
                        message: userVisibleError(error),
                        onRetry: () => ref.invalidate(companyJobListProvider),
                      ),
                      data: (jobs) => _AttentionBody(
                        summary: summary,
                        jobs: jobs,
                        now: DateTime.now(),
                        onOpen: _open,
                        onShowAllJobs: () => context.go('/company/jobs'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _managedJobIcon(DashboardJobTask task) {
  switch (task) {
    case DashboardJobTask.draft:
      return LucideIcons.pencil;
    case DashboardJobTask.overdue:
      return LucideIcons.calendarX;
    case DashboardJobTask.dueSoon:
      return LucideIcons.calendarDays;
  }
}

Color _managedJobColor(DashboardJobTask task) {
  switch (task) {
    case DashboardJobTask.draft:
      return NeoColors.pastelCoral;
    case DashboardJobTask.overdue:
      return NeoColors.softRose;
    case DashboardJobTask.dueSoon:
      return NeoColors.skyBlue;
  }
}

class _AttentionBody extends StatelessWidget {
  const _AttentionBody({
    required this.summary,
    required this.jobs,
    required this.now,
    required this.onOpen,
    required this.onShowAllJobs,
  });

  final CompanyDashboardSummary summary;
  final List<CompanyJob> jobs;
  final DateTime now;
  final Future<void> Function(String path) onOpen;
  final VoidCallback onShowAllJobs;

  @override
  Widget build(BuildContext context) {
    if (summary.totalJobs == 0 && jobs.isEmpty) {
      return _EmptyCompany(onCreate: () => onOpen('/company/jobs/new'));
    }

    final attention = selectDashboardAttention(jobs, now);
    if (attention.isClear) {
      return const _ClearState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (attention.pendingReviews.isEmpty)
          const _ClearState()
        else
          _AttentionSection(
            title: 'ใบสมัครที่รอตรวจ',
            caption: 'เปิดรายชื่อผู้สมัครของประกาศนั้น',
            icon: LucideIcons.users,
            color: NeoColors.butterYellow,
            children: [
              for (final job in attention.pendingReviews) ...[
                _TaskRow(
                  title: job.title,
                  detail: 'รอตรวจ ${job.pendingApplicantCount}',
                  icon: LucideIcons.users,
                  color: NeoColors.butterYellow,
                  onTap: () => onOpen('/company/jobs/${job.id}/applicants'),
                ),
                const Gap(10),
              ],
              if (attention.hiddenPendingCount > 0)
                _MoreJobsLink(
                  count: attention.hiddenPendingCount,
                  onTap: onShowAllJobs,
                ),
            ],
          ),
        if (attention.jobsToManage.isNotEmpty) ...[
          const Gap(20),
          _AttentionSection(
            title: 'ประกาศที่ควรจัดการ',
            caption: 'ฉบับร่าง และประกาศที่ใกล้หมดเขต',
            icon: LucideIcons.briefcase,
            color: NeoColors.pastelCoral,
            children: [
              for (final item in attention.jobsToManage) ...[
                _TaskRow(
                  title: item.job.title,
                  detail: dashboardManagedJobLabel(item),
                  icon: _managedJobIcon(item.task),
                  color: _managedJobColor(item.task),
                  onTap: () => onOpen('/company/jobs/${item.job.id}/edit'),
                ),
                const Gap(10),
              ],
              if (attention.hiddenManageCount > 0)
                _MoreJobsLink(
                  count: attention.hiddenManageCount,
                  onTap: onShowAllJobs,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _EmptyCompany extends StatelessWidget {
  const _EmptyCompany({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: NeoColors.inkSolid,
      borderWidth: 2.5,
      backgroundColor: NeoColors.surfaceCream,
      shadows: NeoShadows.elevation2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: _IconBadge(
              icon: LucideIcons.briefcase,
              color: NeoColors.butterYellow,
              size: 52,
            ),
          ),
          const Gap(12),
          Text(
            'ยังไม่มีประกาศ',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Gap(6),
          Text(
            'สร้างประกาศแรกเพื่อให้นักศึกษาเห็นบริษัทของคุณ',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.mutedForeground,
            ),
          ),
          const Gap(16),
          NeoButton(
            variant: NeoButtonVariant.primary,
            isFullWidth: true,
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 18),
            text: 'สร้างประกาศ',
          ),
        ],
      ),
    );
  }
}

class _ClearState extends StatelessWidget {
  const _ClearState();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: NeoColors.inkSolid,
      borderWidth: 2.5,
      backgroundColor: NeoColors.freshMint,
      shadows: NeoShadows.elevation1,
      child: Row(
        children: [
          const _IconBadge(icon: LucideIcons.check, color: NeoColors.pureWhite),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ไม่มีใบสมัครที่ต้องตรวจ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(2),
                Text(
                  'ตรวจครบแล้วสำหรับตอนนี้',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: NeoColors.subtleInk,
                    fontWeight: FontWeight.w600,
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

class _AttentionSection extends StatelessWidget {
  const _AttentionSection({
    required this.title,
    required this.caption,
    required this.icon,
    required this.color,
    required this.children,
  });

  final String title;
  final String caption;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _IconBadge(icon: icon, color: color, size: 32),
            const Gap(8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    caption,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.mutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Gap(12),
        ...children,
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderColor: NeoColors.inkSolid,
      borderWidth: 2.5,
      backgroundColor: NeoColors.pureWhite,
      shadows: NeoShadows.elevation2,
      child: Row(
        children: [
          _IconBadge(icon: icon, color: color),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap(6),
                _DetailPill(label: detail, color: color),
              ],
            ),
          ),
          const Gap(8),
          const Icon(Icons.chevron_right, color: NeoColors.inkSolid, size: 20),
        ],
      ),
    );
  }
}

class _MoreJobsLink extends StatelessWidget {
  const _MoreJobsLink({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderColor: NeoColors.inkSolid,
      borderWidth: 2,
      backgroundColor: NeoColors.surfaceCream,
      shadows: NeoShadows.elevation1,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(
            LucideIcons.briefcase,
            size: 16,
            color: NeoColors.inkSolid,
          ),
          const Gap(8),
          Expanded(
            child: Text(
              'ดูอีก $count ประกาศ',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: NeoColors.inkSolid,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: NeoColors.inkSolid),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.summary});

  final CompanyDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                title: 'ประกาศทั้งหมด',
                value: summary.totalJobs.toString(),
                icon: LucideIcons.briefcase,
                color: NeoColors.skyBlue,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _StatTile(
                title: 'ประกาศที่เปิดรับ',
                value: summary.openJobs.toString(),
                icon: LucideIcons.check,
                color: NeoColors.freshMint,
              ),
            ),
          ],
        ),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                title: 'ผู้สมัครทั้งหมด',
                value: summary.totalApplicants.toString(),
                icon: LucideIcons.users,
                color: NeoColors.softLilac,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _StatTile(
                title: 'ใบสมัครที่รอตรวจ',
                value: summary.pendingApplicants.toString(),
                icon: LucideIcons.clock,
                color: NeoColors.butterYellow,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: NeoColors.inkSolid,
      borderWidth: 2.5,
      backgroundColor: NeoColors.pureWhite,
      shadows: NeoShadows.elevation1,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(icon: icon, color: color, size: 32),
          const Gap(10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const Gap(2),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.mutedForeground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color, this.size = 40});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NeoColors.inkSolid, width: 1.5),
        boxShadow: NeoShadows.elevation1,
      ),
      child: Icon(icon, size: size * 0.46, color: NeoColors.inkSolid),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NeoColors.inkSolid, width: 1.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: NeoColors.inkSolid,
        ),
      ),
    );
  }
}

class _StatGridSkeleton extends StatelessWidget {
  const _StatGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Skeletonizer(
      enabled: true,
      child: _StatGrid(
        summary: CompanyDashboardSummary(
          totalJobs: 0,
          openJobs: 0,
          totalApplicants: 0,
        ),
      ),
    );
  }
}

class _ActionSkeleton extends StatelessWidget {
  const _ActionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Skeletonizer(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ใบสมัครที่รอตรวจ'),
          Gap(12),
          AppCard(child: Text('กำลังโหลดรายการประกาศ')),
        ],
      ),
    );
  }
}
