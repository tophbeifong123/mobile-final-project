import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_heading.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/job_application.dart';
import '../providers/applications_controller.dart';

class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(myApplicationsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(kPagePadding, 16, kPagePadding, 0),
              child: PageHeading(
                title: 'ใบสมัคร',
                subtitle: 'ชื่องาน บริษัท และสถานะล่าสุด',
              ),
            ),
            Expanded(
              child: applicationsAsync.when(
                skipLoadingOnReload: true,
                loading: () => Skeletonizer(
                  enabled: true,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      kPagePadding,
                      8,
                      kPagePadding,
                      16,
                    ),
                    itemCount: 3,
                    separatorBuilder: (context, index) => const Gap(12),
                    itemBuilder: (context, index) => const AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(radius: 20),
                              Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ตำแหน่งงานกำลังโหลด'),
                                    Gap(2),
                                    Text('บริษัทตัวอย่าง จำกัด'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Gap(12),
                          Text('ยื่นใบสมัครแล้ว'),
                        ],
                      ),
                    ),
                  ),
                ),
                error: (error, _) => EmptyState(
                  icon: LucideIcons.fileText,
                  title: 'โหลดรายการใบสมัครไม่ได้',
                  message: userVisibleError(error),
                  action: AppButton(
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.sm,
                    onPressed: () => ref.invalidate(myApplicationsProvider),
                    text: 'ลองอีกครั้ง',
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: LucideIcons.fileText,
                      title: 'ยังไม่มีใบสมัคร',
                      message:
                          'สมัครจากหน้ารายละเอียดงาน ใบสมัครใหม่จะขึ้นสถานะ Submitted',
                      action: AppButton(
                        onPressed: () => context.go('/student/home'),
                        text: 'ค้นหางานเพื่อสมัคร',
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.refresh(myApplicationsProvider.future),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        kPagePadding,
                        8,
                        kPagePadding,
                        16,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const Gap(12),
                      itemBuilder: (context, index) {
                        final application = items[index];
                        return _ApplicationCard(
                          application: application,
                          onTap: () => context.push(
                            '/student/applications/${application.id}',
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    this.onTap,
  });

  final JobApplication application;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CompanyMark(name: application.companyName),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.jobTitle,
                      style: textTheme.titleMedium,
                    ),
                    const Gap(2),
                    Text(
                      application.companyName,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(label: application.status.labelTh),
              if (application.createdAt != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 14,
                      color: colors.mutedForeground,
                    ),
                    const Gap(4),
                    Text(
                      'สมัครเมื่อ ${_formatDate(application.createdAt!)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    return '$day/$month/$year';
  }
}

class _CompanyMark extends StatelessWidget {
  const _CompanyMark({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty
        ? '?'
        : String.fromCharCode(name.trim().runes.first).toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Text(
            letter,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
          ),
        ),
      ),
    );
  }
}
