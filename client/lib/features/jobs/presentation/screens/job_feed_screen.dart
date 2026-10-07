import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/job_card.dart';
import '../../../saved_jobs/presentation/providers/saved_jobs_controller.dart';
import '../../../student_profile/presentation/providers/student_profile_controller.dart';
import '../../domain/entities/job.dart';
import '../job_labels.dart';
import '../providers/jobs_controller.dart';
import '../widgets/feed_greeting_header.dart';
import '../widgets/feed_pagination_bar.dart';
import '../widgets/feed_search_bar.dart';
import '../widgets/feed_top_bar.dart';
import '../widgets/job_filter_sheet.dart';
import '../widgets/student_job_card.dart';

class JobFeedScreen extends ConsumerStatefulWidget {
  const JobFeedScreen({super.key});

  @override
  ConsumerState<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends ConsumerState<JobFeedScreen> {
  static final _filterModes = <({WorkMode? mode, String label})>[
    (mode: null, label: 'ทั้งหมด'),
    (mode: WorkMode.remote, label: workModeLabel(WorkMode.remote)),
    (mode: WorkMode.onSite, label: workModeLabel(WorkMode.onSite)),
    (mode: WorkMode.hybrid, label: workModeLabel(WorkMode.hybrid)),
  ];

  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(jobsControllerProvider);
    final feed = ref.watch(jobFeedProvider);
    final studentProfile = ref
        .watch(studentProfileControllerProvider)
        .asData
        ?.value;

    return Scaffold(
      backgroundColor: NeoColors.paperCanvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top App Bar
            const FeedTopBar(),

            // Greeting Header (Dynamic from student profile)
            FeedGreetingHeader(
              name: studentProfile?.fullName,
              university: studentProfile?.university,
              avatarKey: studentProfile?.avatarObjectKey,
            ),
            const Gap(2),

            // Search Bar & Filter Button
            FeedSearchBar(
              controller: _searchController,
              onChanged: _queueSearch,
              onSubmitted: _applySearchNow,
              onClear: () {
                _searchDebounce?.cancel();
                _searchController.clear();
                _applySearchNow('');
              },
              onFilterTap: () => _openFilter(filter),
              hasActiveFilters: filter.hasFilters,
              badgeCount: filter.filterCount,
            ),
            const Gap(8),

            // Horizontal WorkMode Filter Pills
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filterModes.length,
                separatorBuilder: (context, index) => const Gap(8),
                itemBuilder: (context, index) {
                  final item = _filterModes[index];
                  final isAll = item.mode == null;
                  final isSelected = isAll
                      ? filter.workMode == null
                      : filter.workMode == item.mode;

                  return FilterChip(
                    label: Text(item.label),
                    selected: isSelected,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w700,
                      color: isSelected ? Colors.white : NeoColors.inkSolid,
                    ),
                    backgroundColor: NeoColors.pureWhite,
                    selectedColor: NeoColors.inkSolid,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: const BorderSide(
                        color: NeoColors.inkSolid,
                        width: 1.8,
                      ),
                    ),
                    elevation: 1.5,
                    pressElevation: 1,
                    shadowColor: NeoColors.inkSolid,
                    onSelected: (selected) {
                      if (isAll) {
                        _replaceFilter(clearWorkMode: true);
                      } else {
                        _replaceFilter(
                          workMode: selected ? item.mode : null,
                          clearWorkMode: !selected,
                        );
                      }
                    },
                  );
                },
              ),
            ),
            const Gap(8),

            // Feed Section Header
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       Flexible(
            //         child: Row(
            //           mainAxisSize: MainAxisSize.min,
            //           children: [
            //             const Flexible(
            //               child: Text(
            //                 'งานฝึกงานมาใหม่',
            //                 maxLines: 1,
            //                 overflow: TextOverflow.ellipsis,
            //                 style: TextStyle(
            //                   fontSize: 16,
            //                   fontWeight: FontWeight.w900,
            //                   color: NeoColors.inkSolid,
            //                   letterSpacing: -0.3,
            //                 ),
            //               ),
            //             ),
            //             const Gap(6),
            //             Container(
            //               padding: const EdgeInsets.symmetric(
            //                 horizontal: 7,
            //                 vertical: 2,
            //               ),
            //               decoration: BoxDecoration(
            //                 color: NeoColors.freshMint,
            //                 borderRadius: BorderRadius.circular(999),
            //                 border: Border.all(
            //                   color: NeoColors.inkSolid,
            //                   width: 1.5,
            //                 ),
            //               ),
            //               child: const Text(
            //                 'อัปเดตวันนี้',
            //                 style: TextStyle(
            //                   fontSize: 10,
            //                   fontWeight: FontWeight.w800,
            //                   color: NeoColors.inkSolid,
            //                 ),
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //       const Gap(8),
            //       GestureDetector(
            //         onTap: () {
            //           _searchDebounce?.cancel();
            //           _searchController.clear();
            //           ref
            //               .read(jobsControllerProvider.notifier)
            //               .apply(const JobFilter());
            //         },
            //         child: const Row(
            //           mainAxisSize: MainAxisSize.min,
            //           children: [
            //             Text(
            //               'ดูทั้งหมด',
            //               style: TextStyle(
            //                 fontSize: 12.5,
            //                 fontWeight: FontWeight.w800,
            //                 color: NeoColors.electricIndigo,
            //               ),
            //             ),
            //             Gap(2),
            //             Icon(
            //               Icons.arrow_forward_rounded,
            //               size: 14,
            //               color: NeoColors.electricIndigo,
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            const Gap(8),

            // Job Cards Stream
            Expanded(
              child: _FeedList(
                feed: feed,
                filter: filter,
                onClear: () {
                  _searchDebounce?.cancel();
                  _searchController.clear();
                  ref
                      .read(jobsControllerProvider.notifier)
                      .apply(const JobFilter());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _queueSearch(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _replaceFilter(search: value.trim());
    });
  }

  void _applySearchNow(String value) {
    _searchDebounce?.cancel();
    _replaceFilter(search: value.trim());
    setState(() {});
  }

  void _replaceFilter({
    String? search,
    WorkMode? workMode,
    bool clearWorkMode = false,
    String? category,
    bool clearCategory = false,
    int? page,
  }) {
    final current = ref.read(jobsControllerProvider);
    ref
        .read(jobsControllerProvider.notifier)
        .apply(
          current.copyWith(
            search: search ?? current.search,
            workMode: workMode,
            clearWorkMode: clearWorkMode,
            category: category,
            clearCategory: clearCategory,
            page: page ?? current.page,
          ),
        );
  }

  void _openFilter(JobFilter filter) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return JobFilterSheet(
          initial: filter,
          onApply: (value) {
            ref.read(jobsControllerProvider.notifier).apply(value);
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }
}

class _FeedList extends ConsumerWidget {
  const _FeedList({
    required this.feed,
    required this.filter,
    required this.onClear,
  });

  final AsyncValue<JobPage> feed;
  final JobFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedJobs = ref.watch(savedJobsProvider).asData?.value ?? [];
    final savedJobIds = savedJobs.map((s) => s.id).toSet();

    return feed.when(
      skipLoadingOnReload: false,
      loading: () => Skeletonizer(
        enabled: true,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: 4,
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
        icon: LucideIcons.briefcase,
        title: 'โหลดงานไม่ได้',
        message: userVisibleError(error),
        action: AppButton(
          variant: AppButtonVariant.outline,
          size: AppButtonSize.sm,
          onPressed: () => ref.invalidate(jobFeedProvider),
          text: 'ลองอีกครั้ง',
        ),
      ),
      data: (page) {
        final jobs = page.items;
        if (jobs.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(jobFeedProvider);
              try {
                await ref.read(jobFeedProvider.future);
              } catch (_) {
                /* Provider displays the error. */
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                EmptyState(
                  icon: LucideIcons.briefcase,
                  title: filter.hasCriteria
                      ? 'ไม่พบงานที่ตรงกับตัวกรอง'
                      : 'ยังไม่มีงานที่เปิดรับ',
                  message: filter.hasCriteria
                      ? 'ลองล้างตัวกรอง หรือเปลี่ยนคำค้น'
                      : 'เมื่อมีประกาศสถานะ Open จะเห็นชื่องาน บริษัท จังหวัด รูปแบบงาน หมวดงาน และเบี้ยเลี้ยง',
                  action: filter.hasCriteria
                      ? AppButton(text: 'ล้างตัวกรอง', onPressed: onClear)
                      : null,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(jobFeedProvider);
            try {
              await ref.read(jobFeedProvider.future);
            } catch (_) {
              /* Provider displays the error. */
            }
          },
          child: ListView(
            key: ValueKey(filter),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              Text(
                'พบ ${page.total} ตำแหน่ง',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Gap(8),
              for (int i = 0; i < jobs.length; i++) ...[
                if (i > 0) const Gap(12),
                Builder(
                  builder: (context) {
                    final job = jobs[i];
                    final isSaved = savedJobIds.contains(job.id);
                    return StudentJobCard(
                      key: ValueKey(job.id),
                      job: job,
                      isSaved: isSaved,
                      onBookmarkTap: () async {
                        final repository = ref.read(jobRepositoryProvider);
                        try {
                          if (isSaved) {
                            await repository.unsave(job.id);
                            ref.invalidate(savedJobsProvider);
                            if (context.mounted) {
                              AppToast.info(
                                context,
                                'ลบ "${job.title}" ออกจากรายการแล้ว',
                              );
                            }
                          } else {
                            await repository.save(job.id);
                            ref.invalidate(savedJobsProvider);
                            if (context.mounted) {
                              AppToast.success(
                                context,
                                'บันทึก "${job.title}" แล้ว',
                              );
                            }
                          }
                        } catch (_) {
                          if (context.mounted) {
                            AppToast.error(
                              context,
                              'เกิดข้อผิดพลาด กรุณาลองอีกครั้ง',
                            );
                          }
                        }
                      },
                      onTap: () => context.push('/student/jobs/${job.id}'),
                    );
                  },
                ),
              ],
              // Pagination Bar
              FeedPaginationBar(
                currentPage: page.page,
                totalItems: page.total,
                totalPages: page.totalPages,
                pageSize: page.limit,
                onPageSelected: (page) {
                  ref
                      .read(jobsControllerProvider.notifier)
                      .apply(filter.copyWith(page: page));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
