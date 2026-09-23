import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/empty_state.dart';
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
                          Text('ตำแหน่งงานตัวอย่างที่กำลังเปิดรับ'),
                          Gap(8),
                          Text('ผู้สมัคร 0 คน'),
                        ],
                      ),
                    ),
                  ),
                ),
                error: (error, _) => EmptyState(
                  icon: LucideIcons.briefcase,
                  title: 'โหลดประกาศไม่ได้',
                  message: userVisibleError(error),
                  action: AppButton(
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.sm,
                    onPressed: () => ref.invalidate(companyJobListProvider),
                    text: 'ลองอีกครั้ง',
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      icon: LucideIcons.briefcase,
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
                    separatorBuilder: (context, index) => const Gap(12),
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
    return AppCard(
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
          const Gap(8),
          Text(
            'ผู้สมัคร ${job.applicantCount} คน',
            style: textTheme.bodyMedium,
          ),
          const Gap(8),
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
    );
  }
}
