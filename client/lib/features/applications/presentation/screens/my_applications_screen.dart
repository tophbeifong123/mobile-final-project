import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_view.dart';
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
                loading: () =>
                    const LoadingView(label: 'กำลังโหลดรายการใบสมัคร'),
                error: (error, _) => EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'โหลดรายการใบสมัครไม่ได้',
                  message: userVisibleError(error),
                  action: AppPrimaryButton(
                    onPressed: () => ref.invalidate(myApplicationsProvider),
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'ยังไม่มีใบสมัคร',
                      message:
                          'สมัครจากหน้ารายละเอียดงาน ใบสมัครใหม่จะขึ้นสถานะ Submitted',
                      action: AppPrimaryButton(
                        onPressed: () => context.go('/student/home'),
                        child: const Text('ค้นหางานเพื่อสมัคร'),
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
                          const SizedBox(height: 12),
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

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CompanyMark(name: application.companyName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.jobTitle,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          application.companyName,
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'สมัครเมื่อ ${_formatDate(application.createdAt!)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
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
