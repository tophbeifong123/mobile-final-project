import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/job_card.dart';
import '../../../jobs/domain/entities/job.dart';
import '../../../jobs/presentation/job_labels.dart';
import '../../../jobs/presentation/providers/jobs_controller.dart';
import '../../../jobs/presentation/widgets/feed_top_bar.dart';
import '../../domain/entities/saved_job.dart';
import '../providers/saved_jobs_controller.dart';
import '../widgets/saved_jobs_empty_view.dart';
import '../widgets/saved_jobs_filter_chips.dart';
import '../widgets/saved_jobs_header.dart';
import '../widgets/saved_jobs_pro_tip_banner.dart';

/// Neo-Brutalist Saved Jobs Screen matching Stitch specification
class SavedJobsScreen extends ConsumerStatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  ConsumerState<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends ConsumerState<SavedJobsScreen> {
  WorkMode? _selectedMode;

  @override
  Widget build(BuildContext context) {
    final savedAsync = ref.watch(savedJobsProvider);

    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top App Bar with Subtitle
            const FeedTopBar(subtitle: 'งานที่บันทึกไว้ (Saved Jobs)'),

            // Content Area
            Expanded(
              child: savedAsync.when(
                skipLoadingOnReload: true,
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(error),
                data: (jobs) => _buildDataState(jobs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: const [
          SavedJobsHeader(count: 3),
          Gap(12),
          SavedJobsProTipBanner(),
          Gap(12),
          JobCard(
            title: 'ตำแหน่งงานกำลังโหลด',
            companyName: 'บริษัทตัวอย่าง จำกัด',
            province: 'กรุงเทพฯ',
            details: ['On-site', 'IT & Software', 'มีเบี้ยเลี้ยง'],
          ),
          Gap(12),
          JobCard(
            title: 'ตำแหน่งงานกำลังโหลด',
            companyName: 'บริษัทตัวอย่าง จำกัด',
            province: 'กรุงเทพฯ',
            details: ['Hybrid', 'Design & UX/UI', 'มีเบี้ยเลี้ยง'],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: EmptyState(
        icon: Icons.bookmark_border_rounded,
        title: 'โหลดงานที่บันทึกไม่ได้',
        message: userVisibleError(error),
        action: AppButton(
          variant: AppButtonVariant.outline,
          size: AppButtonSize.sm,
          onPressed: () => ref.invalidate(savedJobsProvider),
          text: 'ลองอีกครั้ง',
        ),
      ),
    );
  }

  Widget _buildDataState(List<SavedJob> allJobs) {
    if (allJobs.isEmpty) {
      return ListView(
        children: const [
          SavedJobsHeader(count: 0),
          Gap(12),
          SavedJobsProTipBanner(),
          Gap(24),
          SavedJobsEmptyView(),
        ],
      );
    }

    // Filter by workMode if active
    final filteredJobs = _selectedMode == null
        ? allJobs
        : allJobs.where((j) => j.workMode == _selectedMode).toList();

    // Compute filter pill item counts
    final onlineCount = allJobs
        .where((j) => j.workMode == WorkMode.remote)
        .length;
    final onSiteCount = allJobs
        .where((j) => j.workMode == WorkMode.onSite)
        .length;
    final hybridCount = allJobs
        .where((j) => j.workMode == WorkMode.hybrid)
        .length;

    final filterItems = [
      WorkModeFilterItem(mode: null, label: 'ทั้งหมด', count: allJobs.length),
      WorkModeFilterItem(
        mode: WorkMode.remote,
        label: 'Online',
        count: onlineCount,
      ),
      WorkModeFilterItem(
        mode: WorkMode.onSite,
        label: 'Onsite',
        count: onSiteCount,
      ),
      WorkModeFilterItem(
        mode: WorkMode.hybrid,
        label: 'Hybrid',
        count: hybridCount,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Hero Header Block
        SavedJobsHeader(count: allJobs.length),
        const Gap(6),

        // Filter Pills Carousel
        SavedJobsFilterChips(
          selectedMode: _selectedMode,
          items: filterItems,
          onSelected: (mode) => setState(() => _selectedMode = mode),
        ),
        const Gap(10),

        // Pro Tip Banner
        const SavedJobsProTipBanner(),
        const Gap(12),

        // Job Cards Stream
        if (filteredJobs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: SavedJobsEmptyView(
              title: 'ไม่พบงานที่ตรงกับรูปแบบที่เลือก',
              message: 'ลองเลือกตัวกรองอื่นเพื่อดูงานที่คุณบันทึกไว้',
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (int i = 0; i < filteredJobs.length; i++) ...[
                  if (i > 0) const Gap(12),
                  Builder(
                    builder: (cardContext) {
                      final job = filteredJobs[i];
                      return JobCard(
                        title: job.title,
                        companyName: job.companyName,
                        province: job.province,
                        details: [
                          workModeLabel(job.workMode),
                          job.category,
                          allowanceLabel(job.hasAllowance),
                        ],
                        skills: job.skills,
                        hasAllowance: job.hasAllowance,
                        isSaved: true,
                        onBookmarkTap: () => _handleRemoveJob(job),
                        onTap: () => context.push('/student/jobs/${job.id}'),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _handleRemoveJob(SavedJob job) async {
    final repository = ref.read(jobRepositoryProvider);
    try {
      await repository.unsave(job.id);
      ref.invalidate(savedJobsProvider);
      if (mounted) {
        AppToast.info(context, 'ลบ "${job.title}" ออกจากรายการแล้ว');
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'เกิดข้อผิดพลาด ไม่สามารถลบงานได้');
      }
    }
  }
}
