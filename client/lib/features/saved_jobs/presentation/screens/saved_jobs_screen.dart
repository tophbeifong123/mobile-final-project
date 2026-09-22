import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/job_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/page_heading.dart';
import '../../../jobs/presentation/job_labels.dart';
import '../providers/saved_jobs_controller.dart';

class SavedJobsScreen extends ConsumerWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedJobsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(kPagePadding, 16, kPagePadding, 0),
              child: PageHeading(
                title: 'งานที่บันทึก',
                subtitle: 'งานที่กดบันทึกจากหน้ารายละเอียด',
              ),
            ),
            Expanded(
              child: saved.when(
                loading: () => const LoadingView(label: 'กำลังโหลดงานที่บันทึก'),
                error: (error, _) => EmptyState(
                  icon: Icons.bookmark_outline,
                  title: 'โหลดงานที่บันทึกไม่ได้',
                  message: userVisibleError(error),
                  action: AppPrimaryButton(
                    onPressed: () => ref.invalidate(savedJobsProvider),
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ),
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return EmptyState(
                      icon: Icons.bookmark_outline,
                      title: 'ยังไม่มีงานที่บันทึก',
                      message: 'เปิดรายละเอียดงานแล้วกดบันทึก งานนั้นจะมาอยู่ที่นี่',
                      action: AppPrimaryButton(
                        onPressed: () => context.go('/student/home'),
                        child: const Text('ไปหน้าแรก'),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      kPagePadding,
                      8,
                      kPagePadding,
                      16,
                    ),
                    itemCount: jobs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return JobCard(
                        title: job.title,
                        companyName: job.companyName,
                        province: job.province,
                        details: [
                          workModeLabel(job.workMode),
                          job.category,
                          allowanceLabel(job.hasAllowance),
                        ],
                        onTap: () => context.push('/student/jobs/${job.id}'),
                      );
                    },
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
