import 'dart:async';

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
import '../../domain/entities/job.dart';
import '../job_labels.dart';
import '../providers/jobs_controller.dart';
import '../widgets/job_filter_sheet.dart';

class JobFeedScreen extends ConsumerStatefulWidget {
  const JobFeedScreen({super.key});

  @override
  ConsumerState<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends ConsumerState<JobFeedScreen> {
  static const _categories = [
    'IT & Software',
    'Design & UX/UI',
    'Marketing',
    'Data',
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kPagePadding,
                8,
                kPagePadding,
                0,
              ),
              child: PageHeading(
                eyebrow: 'InternFinder',
                title: 'สวัสดี',
                subtitle: 'ค้นหาที่ฝึกงานที่เปิดรับ',
                trailing: IconButton(
                  tooltip: 'การแจ้งเตือน',
                  onPressed: () => context.push('/student/notifications'),
                  icon: const Icon(Icons.notifications_outlined),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kPagePadding,
                16,
                kPagePadding,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: _queueSearch,
                      onSubmitted: _applySearchNow,
                      decoration: InputDecoration(
                        hintText: 'ค้นหางาน บริษัท หรือจังหวัด',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'ล้างคำค้น',
                                onPressed: () {
                                  _searchDebounce?.cancel();
                                  _searchController.clear();
                                  _applySearchNow('');
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    active: filter.hasCriteria,
                    onPressed: () => _openFilter(filter),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: kPagePadding),
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return _CategoryChip(
                    label: category,
                    selected: filter.category == category,
                    onSelected: (selected) {
                      _replaceFilter(
                        category: selected ? category : null,
                        clearCategory: !selected,
                      );
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: _FeedList(feed: feed, filter: filter),
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
    String? category,
    bool clearCategory = false,
  }) {
    final current = ref.read(jobsControllerProvider);
    ref
        .read(jobsControllerProvider.notifier)
        .apply(
          JobFilter(
            search: search ?? current.search,
            province: current.province,
            workMode: current.workMode,
            category: clearCategory ? null : category ?? current.category,
            hasAllowance: current.hasAllowance,
          ),
        );
  }

  void _openFilter(JobFilter filter) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onPressed});

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: active ? AppColors.primary : AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: 'ตัวกรอง',
        onPressed: onPressed,
        icon: Icon(
          Icons.tune,
          color: active ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: selected ? scheme.onPrimary : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.surface;
      }),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.line),
      onSelected: onSelected,
    );
  }
}

class _FeedList extends ConsumerWidget {
  const _FeedList({required this.feed, required this.filter});

  final AsyncValue<List<Job>> feed;
  final JobFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return feed.when(
      skipLoadingOnReload: true,
      loading: () => const LoadingView(label: 'กำลังโหลดงาน'),
      error: (error, _) => EmptyState(
        icon: Icons.work_outline,
        title: 'โหลดงานไม่ได้',
        message: userVisibleError(error),
        action: AppPrimaryButton(
          onPressed: () => ref.invalidate(jobFeedProvider),
          child: const Text('ลองอีกครั้ง'),
        ),
      ),
      data: (jobs) {
        if (jobs.isEmpty) {
          return EmptyState(
            icon: Icons.work_outline,
            title: filter.hasCriteria
                ? 'ไม่พบงานที่ตรงกับตัวกรอง'
                : 'ยังไม่มีงานที่เปิดรับ',
            message: filter.hasCriteria
                ? 'ลองล้างตัวกรอง หรือเปลี่ยนคำค้น'
                : 'เมื่อมีประกาศสถานะ Open จะเห็นชื่องาน บริษัท จังหวัด รูปแบบงาน หมวดงาน และเบี้ยเลี้ยง',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(kPagePadding, 8, kPagePadding, 16),
          itemCount: jobs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
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
    );
  }
}
