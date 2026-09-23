import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/jobs/domain/entities/job.dart';
import 'package:client/features/jobs/domain/repositories/job_repository.dart';
import 'package:client/features/jobs/presentation/providers/jobs_controller.dart';
import 'package:client/features/jobs/presentation/screens/job_feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleJobs = [
    Job(
      id: 'job-1',
      title: 'Flutter Intern',
      companyName: 'InternFinder',
      province: 'สงขลา',
      workMode: WorkMode.onSite,
      category: 'IT & Software',
      hasAllowance: true,
      status: JobStatus.open,
    ),
    Job(
      id: 'job-2',
      title: 'UI/UX Designer Intern',
      companyName: 'Design Studio',
      province: 'กรุงเทพฯ',
      workMode: WorkMode.hybrid,
      category: 'Design & UX/UI',
      hasAllowance: false,
      status: JobStatus.open,
    ),
    Job(
      id: 'job-3',
      title: 'Marketing Trainee',
      companyName: 'MarketPros',
      province: 'เชียงใหม่',
      workMode: WorkMode.remote,
      category: 'Marketing',
      hasAllowance: true,
      status: JobStatus.open,
    ),
  ];

  Widget buildScreen(JobRepository repo) {
    return ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
        jobRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const JobFeedScreen(),
      ),
    );
  }

  testWidgets('home lists open jobs and renders details', (tester) async {
    await tester.pumpWidget(buildScreen(_FilteringJobRepository(sampleJobs)));
    await tester.pumpAndSettle();

    expect(find.text('Flutter Intern'), findsOneWidget);
    expect(find.text('UI/UX Designer Intern'), findsOneWidget);
    expect(find.text('Marketing Trainee'), findsOneWidget);
    expect(find.text('On-site'), findsOneWidget);
    expect(find.text('Hybrid'), findsOneWidget);
    expect(find.text('Remote'), findsOneWidget);
  });

  testWidgets('search input filters jobs by keyword', (tester) async {
    await tester.pumpWidget(buildScreen(_FilteringJobRepository(sampleJobs)));
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'Flutter');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Flutter Intern'), findsOneWidget);
    expect(find.text('UI/UX Designer Intern'), findsNothing);
    expect(find.text('Marketing Trainee'), findsNothing);

    // Clear search
    final clearButton = find.byTooltip('ล้างคำค้น');
    expect(clearButton, findsOneWidget);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    expect(find.text('Flutter Intern'), findsOneWidget);
    expect(find.text('UI/UX Designer Intern'), findsOneWidget);
    expect(find.text('Marketing Trainee'), findsOneWidget);
  });

  testWidgets(
    'tapping category chip filters jobs by category and unselecting clears it',
    (tester) async {
      await tester.pumpWidget(buildScreen(_FilteringJobRepository(sampleJobs)));
      await tester.pumpAndSettle();

      // Tap Marketing chip
      final marketingChip = find.widgetWithText(FilterChip, 'Marketing');
      expect(marketingChip, findsOneWidget);
      await tester.tap(marketingChip);
      await tester.pumpAndSettle();

      expect(find.text('Marketing Trainee'), findsOneWidget);
      expect(find.text('Flutter Intern'), findsNothing);
      expect(find.text('UI/UX Designer Intern'), findsNothing);

      // Untap Marketing chip
      await tester.tap(marketingChip);
      await tester.pumpAndSettle();

      expect(find.text('Flutter Intern'), findsOneWidget);
      expect(find.text('UI/UX Designer Intern'), findsOneWidget);
      expect(find.text('Marketing Trainee'), findsOneWidget);
    },
  );

  testWidgets(
    'filter button opens bottom sheet, applying filters updates the feed and badge',
    (tester) async {
      await tester.pumpWidget(buildScreen(_FilteringJobRepository(sampleJobs)));
      await tester.pumpAndSettle();

      // Open filter bottom sheet
      final filterButton = find.byTooltip('ตัวกรอง');
      expect(filterButton, findsOneWidget);
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Inside bottom sheet
      expect(find.text('ตัวกรอง'), findsOneWidget);
      expect(
        find.text('จังหวัด รูปแบบงาน หมวดงาน และเบี้ยเลี้ยง'),
        findsOneWidget,
      );

      // Enter province
      final provinceField = find.widgetWithText(TextField, 'จังหวัด');
      await tester.enterText(provinceField, 'สงขลา');

      // Tap "มีเบี้ยเลี้ยง"
      final allowanceChip = find.widgetWithText(FilterChip, 'มีเบี้ยเลี้ยง');
      await tester.tap(allowanceChip);
      await tester.pumpAndSettle();

      // Tap "ใช้ตัวกรอง"
      final applyButton = find.widgetWithText(FilledButton, 'ใช้ตัวกรอง');
      await tester.ensureVisible(applyButton);
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      // Feed should show only Flutter Intern (Songkhla + has allowance)
      expect(find.text('Flutter Intern'), findsOneWidget);
      expect(find.text('UI/UX Designer Intern'), findsNothing);
      expect(find.text('Marketing Trainee'), findsNothing);

      // Badge should show 2 active filters (province and allowance)
      expect(find.text('2'), findsOneWidget);

      // Open filter again and tap "ล้างตัวกรอง"
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      final clearFilterButton = find.widgetWithText(TextButton, 'ล้างตัวกรอง');
      await tester.ensureVisible(clearFilterButton);
      await tester.tap(clearFilterButton);
      await tester.pumpAndSettle();

      // All jobs should be back
      expect(find.text('Flutter Intern'), findsOneWidget);
      expect(find.text('UI/UX Designer Intern'), findsOneWidget);
      expect(find.text('Marketing Trainee'), findsOneWidget);
    },
  );
}

class _FilteringJobRepository implements JobRepository {
  _FilteringJobRepository(this._allJobs);

  final List<Job> _allJobs;

  @override
  Future<List<Job>> fetchFeed(JobFilter filter) async {
    return _allJobs.where((job) {
      if (filter.search.trim().isNotEmpty) {
        final query = filter.search.trim().toLowerCase();
        final matchesTitle = job.title.toLowerCase().contains(query);
        final matchesCompany = job.companyName.toLowerCase().contains(query);
        final matchesProvince = job.province.toLowerCase().contains(query);
        if (!matchesTitle && !matchesCompany && !matchesProvince) {
          return false;
        }
      }
      if (filter.province != null && filter.province!.trim().isNotEmpty) {
        if (job.province.trim().toLowerCase() !=
            filter.province!.trim().toLowerCase()) {
          return false;
        }
      }
      if (filter.workMode != null && job.workMode != filter.workMode) {
        return false;
      }
      if (filter.category != null && filter.category!.trim().isNotEmpty) {
        if (job.category.trim().toLowerCase() !=
            filter.category!.trim().toLowerCase()) {
          return false;
        }
      }
      if (filter.hasAllowance != null &&
          job.hasAllowance != filter.hasAllowance) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<JobDetail> fetchDetail(String jobId) => throw UnimplementedError();

  @override
  Future<void> save(String jobId) async {}

  @override
  Future<void> unsave(String jobId) async {}
}
