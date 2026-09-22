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
import '../../domain/entities/company_job.dart';
import '../providers/company_jobs_controller.dart';

class ManageJobsScreen extends ConsumerWidget {
  const ManageJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(companyJobListProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(kPagePadding, 16, kPagePadding, 0),
              child: PageHeading(
                title: 'ประกาศของบริษัท',
                subtitle: 'สร้างประกาศใหม่ได้จากปุ่มด้านล่าง',
              ),
            ),
            Expanded(
              child: jobs.when(
                loading: () => const LoadingView(label: 'กำลังโหลดประกาศ'),
                error: (error, _) => EmptyState(
                  icon: Icons.work_outline,
                  title: 'โหลดประกาศไม่ได้',
                  message: userVisibleError(error),
                  action: AppPrimaryButton(
                    onPressed: () => ref.invalidate(companyJobListProvider),
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.work_outline,
                      title: 'ยังไม่มีประกาศ',
                      message: 'ประกาศใหม่จะเริ่มที่สถานะ Open',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      kPagePadding,
                      8,
                      kPagePadding,
                      16,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _CompanyJobCard(job: items[index]),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kPagePadding,
                8,
                kPagePadding,
                16,
              ),
              child: AppPrimaryButton(
                onPressed: () => context.push('/company/jobs/new'),
                child: const Text('สร้างประกาศ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyJobCard extends StatelessWidget {
  const _CompanyJobCard({required this.job});

  final CompanyJob job;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final open = job.status == 'open';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(job.title, style: textTheme.titleMedium)),
                StatusChip(label: open ? 'เปิดรับ' : 'ปิดรับ'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ผู้สมัคร ${job.applicantCount} คน',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => context.push('/company/jobs/${job.id}/edit'),
                  child: const Text('แก้ไข'),
                ),
                TextButton(
                  onPressed: () =>
                      context.push('/company/jobs/${job.id}/applicants'),
                  child: const Text('ผู้สมัคร'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
