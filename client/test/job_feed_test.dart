import 'package:client/core/network/dio_client.dart';
import 'package:client/core/provinces/thai_province.dart';
import 'package:client/core/provinces/thai_provinces_provider.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/jobs/domain/entities/job.dart';
import 'package:client/features/jobs/domain/repositories/job_repository.dart';
import 'package:client/features/jobs/presentation/providers/jobs_controller.dart';
import 'package:client/features/jobs/presentation/screens/job_feed_screen.dart';
import 'package:client/core/widgets/job_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const provinces = [
    ThaiProvince(id: 90, nameTh: 'สงขลา'),
    ThaiProvince(
      id: 10,
      nameTh: 'กรุงเทพมหานคร',
      aliases: ['กรุงเทพฯ', 'กทม.'],
    ),
  ];

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
      province: 'กรุงเทพมหานคร',
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

  Widget buildScreen(WidgetTester tester, JobRepository repo) {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
        jobRepositoryProvider.overrideWithValue(repo),
        thaiProvincesProvider.overrideWith((ref) async => provinces),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const JobFeedScreen(),
      ),
    );
  }

  testWidgets('home lists open jobs and renders details', (tester) async {
    await tester.pumpWidget(
      buildScreen(tester, _FilteringJobRepository(sampleJobs)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flutter Intern'), findsOneWidget);
    expect(find.text('UI/UX Designer Intern'), findsOneWidget);
    expect(find.text('Marketing Trainee'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(JobCard), matching: find.text('On-site')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(JobCard), matching: find.text('Hybrid')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(JobCard), matching: find.text('Online')),
      findsOneWidget,
    );
  });

  testWidgets('search input filters jobs by keyword', (tester) async {
    await tester.pumpWidget(
      buildScreen(tester, _FilteringJobRepository(sampleJobs)),
    );
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'Flutter');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Flutter Intern'), findsOneWidget);
    expect(find.text('สัมภาษณ์ออนไลน์'), findsOneWidget);
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
    'tapping work mode chip filters jobs by work mode and unselecting clears it',
    (tester) async {
      await tester.pumpWidget(
        buildScreen(tester, _FilteringJobRepository(sampleJobs)),
      );
      await tester.pumpAndSettle();

      // Tap Online chip
      final onlineChip = find.widgetWithText(FilterChip, 'Online');
      expect(onlineChip, findsOneWidget);
      await tester.tap(onlineChip);
      await tester.pumpAndSettle();

      expect(find.text('Marketing Trainee'), findsOneWidget);
      expect(find.text('Flutter Intern'), findsNothing);
      expect(find.text('UI/UX Designer Intern'), findsNothing);

      // Untap Online chip
      await tester.tap(onlineChip);
      await tester.pumpAndSettle();

      expect(find.text('Flutter Intern'), findsOneWidget);
      expect(find.text('UI/UX Designer Intern'), findsOneWidget);
      expect(find.text('Marketing Trainee'), findsOneWidget);
    },
  );

  testWidgets(
    'filter button opens bottom sheet, applying filters updates the feed and badge',
    (tester) async {
      await tester.pumpWidget(
        buildScreen(tester, _FilteringJobRepository(sampleJobs)),
      );
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

      // Pick province from the same canonical list as the company profile.
      final provinceField = find.widgetWithText(TextField, 'จังหวัด');
      await tester.tap(provinceField);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('province-90')));
      await tester.pumpAndSettle();

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

  testWidgets('province alias search applies the canonical name', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildScreen(tester, _FilteringJobRepository(sampleJobs)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('ตัวกรอง'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextField, 'จังหวัด'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'ค้นหาจังหวัด'),
      'กทม',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('province-10')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('province-10')));
    await tester.pumpAndSettle();
    final applyButton = find.widgetWithText(FilledButton, 'ใช้ตัวกรอง');
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('UI/UX Designer Intern'), findsOneWidget);
    expect(find.text('Flutter Intern'), findsNothing);
    expect(find.text('Marketing Trainee'), findsNothing);
  });
}

class _FilteringJobRepository implements JobRepository {
  _FilteringJobRepository(this._allJobs);

  final List<Job> _allJobs;

  @override
  Future<JobPage> fetchFeed(JobFilter filter) async {
    final items = _allJobs.where((job) {
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
    return JobPage(
      items: items
          .skip((filter.page - 1) * filter.limit)
          .take(filter.limit)
          .toList(),
      total: items.length,
      page: filter.page,
      limit: filter.limit,
      totalPages: (items.length / filter.limit).ceil(),
    );
  }

  @override
  Future<JobDetail> fetchDetail(String jobId) => throw UnimplementedError();

  @override
  Future<void> save(String jobId) async {}

  @override
  Future<void> unsave(String jobId) async {}
}
