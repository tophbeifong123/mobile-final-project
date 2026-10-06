import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/widgets.dart';
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
      ref.invalidate(companyDashboardSummaryProvider);
    });
  }

  Future<void> _openPage(String path) async {
    // The jobs list is another shell branch. push() stacks it on the
    // dashboard branch, so choosing Dashboard later restores that jobs page.
    if (path == '/company/jobs') {
      context.go(path);
      return;
    }
    await context.push<void>(path);
    if (context.mounted) ref.invalidate(companyDashboardSummaryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(companyDashboardSummaryProvider);

    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      appBar: const CompanyTopBar(title: 'แดชบอร์ดบริษัท'),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(companyDashboardSummaryProvider.future),
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
                'ภาพรวมประกาศรับสมัครและผู้สมัครทั้งหมด',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.mutedForeground,
                ),
              ),
              const Gap(20),
              summaryAsync.when(
                skipLoadingOnReload: true,
                loading: () => const Skeletonizer(
                  enabled: true,
                  child: Column(
                    children: [
                      _StatCardPlaceholder(),
                      Gap(12),
                      _StatCardPlaceholder(),
                      Gap(12),
                      _StatCardPlaceholder(),
                      Gap(12),
                      _StatCardPlaceholder(),
                    ],
                  ),
                ),
                error: (error, _) => AppErrorView(
                  title: 'โหลดข้อมูลแดชบอร์ดไม่สำเร็จ',
                  message: userVisibleError(error),
                  onRetry: () =>
                      ref.invalidate(companyDashboardSummaryProvider),
                ),
                data: (summary) => Column(
                  children: [
                    _StatCard(
                      title: 'ประกาศทั้งหมด',
                      value: summary.totalJobs.toString(),
                      subtitle: 'ตำแหน่งงานที่คุณสร้างไว้',
                      icon: Icons.work_outline,
                      iconColor: NeoColors.inkSolid,
                      iconBgColor: NeoColors.skyBlue,
                      onTap: () => _openPage('/company/jobs'),
                    ),
                    const Gap(12),
                    _StatCard(
                      title: 'ประกาศที่เปิดรับ',
                      value: summary.openJobs.toString(),
                      subtitle: 'กำลังแสดงในฟีดของนักศึกษา',
                      icon: Icons.check_circle_outline,
                      iconColor: NeoColors.inkSolid,
                      iconBgColor: NeoColors.freshMint,
                      onTap: () => _openPage('/company/jobs'),
                    ),
                    const Gap(12),
                    _StatCard(
                      title: 'ผู้สมัครทั้งหมด',
                      value: summary.totalApplicants.toString(),
                      subtitle: 'จากทุกตำแหน่งงานของบริษัท',
                      icon: Icons.people_outline,
                      iconColor: NeoColors.inkSolid,
                      iconBgColor: NeoColors.softLilac,
                      onTap: () => _openPage('/company/jobs'),
                    ),
                    const Gap(12),
                    _StatCard(
                      title: 'ใบสมัครที่รอตรวจ',
                      value: summary.pendingApplicants.toString(),
                      subtitle: 'ส่งใบสมัครแล้ว หรือกำลังตรวจสอบ',
                      icon: Icons.pending_actions_outlined,
                      iconColor: NeoColors.inkSolid,
                      iconBgColor: NeoColors.butterYellow,
                      onTap: () => _openPage('/company/jobs'),
                    ),
                  ],
                ),
              ),
              const Gap(28),
              Text(
                'เมนูลัด',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Gap(12),
              NeoButton(
                variant: NeoButtonVariant.secondary,
                isFullWidth: true,
                onPressed: () => _openPage('/company/jobs/new'),
                icon: const Icon(Icons.add, size: 18),
                text: 'สร้างประกาศ',
              ),
              const Gap(10),
              NeoButton(
                variant: NeoButtonVariant.outline,
                isFullWidth: true,
                onPressed: () => _openPage('/company/jobs'),
                icon: const Icon(Icons.format_list_bulleted, size: 18),
                text: 'จัดการประกาศ',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return AppCard(
      onTap: onTap,
      borderColor: NeoColors.inkSolid,
      borderWidth: 2.5,
      backgroundColor: NeoColors.pureWhite,
      shadows: NeoShadows.elevation2,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NeoColors.inkSolid, width: 2),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                const Gap(4),
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Gap(2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.mutedForeground, size: 20),
        ],
      ),
    );
  }
}

class _StatCardPlaceholder extends StatelessWidget {
  const _StatCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      borderColor: NeoColors.inkSolid,
      borderWidth: 2.5,
      backgroundColor: NeoColors.pureWhite,
      child: Row(
        children: [
          SizedBox(width: 48, height: 48),
          Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ประกาศทั้งหมด'),
                Gap(4),
                Text('0', style: TextStyle(fontSize: 24)),
                Gap(2),
                Text('ตำแหน่งงานที่คุณสร้างไว้'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
