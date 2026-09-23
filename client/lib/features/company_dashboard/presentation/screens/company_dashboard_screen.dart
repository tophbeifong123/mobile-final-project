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

class CompanyDashboardScreen extends ConsumerWidget {
  const CompanyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(companyDashboardSummaryProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(companyDashboardSummaryProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              kPagePadding,
              16,
              kPagePadding,
              24,
            ),
            children: [
              const PageHeading(
                title: 'แดชบอร์ดบริษัท',
                subtitle: 'ภาพรวมประกาศรับสมัครและผู้สมัครทั้งหมด',
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
                      iconColor: AppColors.primary,
                      iconBgColor: const Color(0x1A4F46E5),
                      onTap: () => context.push('/company/jobs'),
                    ),
                    const Gap(12),
                    _StatCard(
                      title: 'ประกาศที่เปิดรับ',
                      value: summary.openJobs.toString(),
                      subtitle: 'กำลังแสดงในฟีดของนักศึกษา',
                      icon: Icons.check_circle_outline,
                      iconColor: const Color(0xFF16A34A),
                      iconBgColor: const Color(0x1A16A34A),
                      onTap: () => context.push('/company/jobs'),
                    ),
                    const Gap(12),
                    _StatCard(
                      title: 'ผู้สมัครทั้งหมด',
                      value: summary.totalApplicants.toString(),
                      subtitle: 'จากทุกตำแหน่งงานของบริษัท',
                      icon: Icons.people_outline,
                      iconColor: const Color(0xFFD97706),
                      iconBgColor: const Color(0x1AD97706),
                      onTap: () => context.push('/company/jobs'),
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
              AppButton(
                variant: AppButtonVariant.default_,
                isFullWidth: true,
                onPressed: () => context.push('/company/jobs/new'),
                icon: const Icon(Icons.add, size: 18),
                text: 'สร้างประกาศ',
              ),
              const Gap(10),
              AppButton(
                variant: AppButtonVariant.outline,
                isFullWidth: true,
                onPressed: () => context.push('/company/jobs'),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.bold,
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
