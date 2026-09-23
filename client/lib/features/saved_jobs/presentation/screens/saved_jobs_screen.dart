import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/job_card.dart';
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
                    itemBuilder: (context, index) => const JobCard(
                      title: 'ตำแหน่งงานกำลังโหลด',
                      companyName: 'บริษัทตัวอย่าง จำกัด',
                      province: 'กรุงเทพฯ',
                      details: ['On-site', 'IT & Software', 'มีเบี้ยเลี้ยง'],
                    ),
                  ),
                ),
                error: (error, _) => EmptyState(
                  icon: LucideIcons.bookmark,
                  title: 'โหลดงานที่บันทึกไม่ได้',
                  message: userVisibleError(error),
                  action: AppButton(
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.sm,
                    onPressed: () => ref.invalidate(savedJobsProvider),
                    text: 'ลองอีกครั้ง',
                  ),
                ),
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return EmptyState(
                      icon: LucideIcons.bookmark,
                      title: 'ยังไม่มีงานที่บันทึก',
                      message: 'เปิดรายละเอียดงานแล้วกดบันทึก งานนั้นจะมาอยู่ที่นี่',
                      action: AppButton(
                        onPressed: () => context.go('/student/home'),
                        text: 'ไปหน้าแรก',
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
                    separatorBuilder: (context, index) => const Gap(12),
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
