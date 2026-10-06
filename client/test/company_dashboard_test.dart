import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/router/company_shell.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/company_dashboard/data/models/company_dashboard_summary_model.dart';
import 'package:client/features/company_dashboard/domain/entities/company_dashboard_summary.dart';
import 'package:client/features/company_dashboard/domain/repositories/company_dashboard_repository.dart';
import 'package:client/features/company_dashboard/presentation/providers/company_dashboard_controller.dart';
import 'package:client/features/company_dashboard/presentation/screens/company_dashboard_screen.dart';
import 'package:client/features/company_jobs/domain/entities/company_job.dart';
import 'package:client/features/company_jobs/presentation/providers/company_jobs_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'dashboard refreshes real counts after returning from job creation',
    (tester) async {
      final repo = _MockDashboardRepository(
        summary: const CompanyDashboardSummary(
          totalJobs: 0,
          openJobs: 0,
          totalApplicants: 0,
        ),
      );
      final router = GoRouter(
        initialLocation: '/company/dashboard',
        routes: [
          GoRoute(
            path: '/company/dashboard',
            builder: (_, _) => const CompanyDashboardScreen(),
          ),
          GoRoute(
            path: '/company/jobs/new',
            builder: (_, _) =>
                const Scaffold(body: Text('Create Job Destination')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await _pumpDashboard(
        tester,
        router: router,
        repository: repo,
        jobs: const [],
      );
      await tester.ensureVisible(find.text('สร้างประกาศ'));
      await tester.tap(find.text('สร้างประกาศ'));
      await tester.pumpAndSettle();
      repo.summary = const CompanyDashboardSummary(
        totalJobs: 19,
        openJobs: 11,
        totalApplicants: 37,
        pendingApplicants: 23,
      );
      router.pop();
      await tester.pumpAndSettle();
      for (final count in ['19', '11', '37', '23']) {
        expect(find.text(count), findsOneWidget);
      }
      expect(find.text('ไม่มีใบสมัครที่ต้องตรวจ'), findsOneWidget);
      expect(find.text('สร้างประกาศ'), findsNothing);
      expect(find.text('จัดการประกาศ'), findsNothing);
    },
  );

  testWidgets('an empty company can create its first job', (tester) async {
    final router = _pageRouter();
    addTearDown(router.dispose);
    await _pumpDashboard(
      tester,
      router: router,
      repository: _MockDashboardRepository(
        summary: const CompanyDashboardSummary(
          totalJobs: 0,
          openJobs: 0,
          totalApplicants: 0,
        ),
      ),
      jobs: const [],
    );
    expect(find.text('0'), findsNWidgets(4));
    expect(find.text('จัดการประกาศ'), findsNothing);
    await tester.tap(find.text('ประกาศทั้งหมด'));
    await tester.pumpAndSettle();
    expect(find.text('แดชบอร์ดบริษัท'), findsOneWidget);
    await tester.tap(find.text('สร้างประกาศ'));
    await tester.pumpAndSettle();
    expect(find.text('Create Job Destination'), findsOneWidget);
  });

  testWidgets('a pending job opens its applicant list', (tester) async {
    final router = _pageRouter();
    addTearDown(router.dispose);
    await _pumpDashboard(
      tester,
      router: router,
      repository: _MockDashboardRepository(
        summary: const CompanyDashboardSummary(
          totalJobs: 1,
          openJobs: 1,
          totalApplicants: 2,
          pendingApplicants: 2,
        ),
      ),
      jobs: [_job(id: 'job-1', title: 'การตลาดดิจิทัล', pending: 2)],
    );
    await tester.tap(find.text('การตลาดดิจิทัล'));
    await tester.pumpAndSettle();
    expect(find.text('Applicants Destination'), findsOneWidget);
  });

  testWidgets('a draft and an overdue job open the edit form', (tester) async {
    final router = _pageRouter();
    addTearDown(router.dispose);
    await _pumpDashboard(
      tester,
      router: router,
      repository: _MockDashboardRepository(
        summary: const CompanyDashboardSummary(
          totalJobs: 2,
          openJobs: 1,
          totalApplicants: 0,
        ),
      ),
      jobs: [
        _job(id: 'draft-1', title: 'ฉบับที่ยังไม่เปิด', status: 'draft'),
        _job(
          id: 'late-1',
          title: 'ประกาศเลยกำหนด',
          deadline: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    );
    expect(find.text('ไม่มีใบสมัครที่ต้องตรวจ'), findsOneWidget);
    await tester.tap(find.text('ฉบับที่ยังไม่เปิด'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Destination'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('ประกาศเลยกำหนด'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Destination'), findsOneWidget);
  });

  testWidgets('dashboard tab returns after opening the rest of the jobs', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/company/dashboard',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return CompanyShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/company/dashboard',
                  builder: (_, _) => const CompanyDashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/company/jobs',
                  builder: (_, _) =>
                      const Scaffold(body: Text('Manage Jobs Destination')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/company/profile',
                  builder: (_, _) => const Scaffold(body: Text('Profile')),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await _pumpDashboard(
      tester,
      router: router,
      repository: _MockDashboardRepository(
        summary: const CompanyDashboardSummary(
          totalJobs: 6,
          openJobs: 6,
          totalApplicants: 21,
          pendingApplicants: 21,
        ),
      ),
      jobs: [
        for (var index = 0; index < 6; index++)
          _job(id: 'job-$index', title: 'ประกาศ $index', pending: index + 1),
      ],
    );
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('ดูอีก 1 ประกาศ'));
      await tester.tap(find.text('ดูอีก 1 ประกาศ'));
    await tester.pumpAndSettle();
    expect(find.text('Manage Jobs Destination'), findsOneWidget);
    await tester.tap(find.text('Jobs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('แดชบอร์ดบริษัท'), findsOneWidget);
    expect(find.text('Manage Jobs Destination'), findsNothing);
    expect(router.state.uri.path, '/company/dashboard');
  });

  test('dashboard model keeps all four API counts', () {
    final summary = CompanyDashboardSummaryModel.fromJson({
      'totalJobs': 5,
      'openJobs': 3,
      'totalApplicants': 12,
      'pendingApplicants': 7,
    }).toEntity();
    expect(summary.totalJobs, 5);
    expect(summary.openJobs, 3);
    expect(summary.totalApplicants, 12);
    expect(summary.pendingApplicants, 7);
  });

  testWidgets('company dashboard displays summary statistics correctly', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      repository: _MockDashboardRepository(
        summary: const CompanyDashboardSummary(
          totalJobs: 5,
          openJobs: 3,
          totalApplicants: 12,
          pendingApplicants: 7,
        ),
      ),
      jobs: const [],
    );

    expect(find.text('แดชบอร์ดบริษัท'), findsOneWidget);
    expect(find.text('ประกาศทั้งหมด'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('ประกาศที่เปิดรับ'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('ผู้สมัครทั้งหมด'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('ใบสมัครที่รอตรวจ'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('ไม่มีใบสมัครที่ต้องตรวจ'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsNothing);
    expect(find.text('จัดการประกาศ'), findsNothing);
    expect(find.text('สร้างประกาศ'), findsNothing);
  });

  testWidgets('company dashboard shows error view and retries', (tester) async {
    final mockRepo = _FailingDashboardRepository();
    await _pumpDashboard(tester, repository: mockRepo, jobs: const []);

    expect(find.text('โหลดข้อมูลแดชบอร์ดไม่สำเร็จ'), findsOneWidget);
    expect(find.text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'), findsOneWidget);
    expect(find.text('ลองใหม่อีกครั้ง'), findsOneWidget);

    mockRepo.shouldFail = false;
    await tester.tap(find.text('ลองใหม่อีกครั้ง'));
    await tester.pumpAndSettle();

    expect(find.text('แดชบอร์ดบริษัท'), findsOneWidget);
    expect(find.text('ประกาศทั้งหมด'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  GoRouter? router,
  required CompanyDashboardRepository repository,
  required List<CompanyJob> jobs,
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final ownedRouter = router == null;
  final activeRouter = router ?? _pageRouter();
  if (ownedRouter) addTearDown(activeRouter.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
        companyDashboardRepositoryProvider.overrideWithValue(repository),
        companyJobListProvider.overrideWith((ref) async => jobs),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: activeRouter,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter _pageRouter() {
  return GoRouter(
    initialLocation: '/company/dashboard',
    routes: [
      GoRoute(
        path: '/company/dashboard',
        builder: (_, _) => const CompanyDashboardScreen(),
      ),
      GoRoute(
        path: '/company/jobs/new',
        builder: (_, _) => const Scaffold(body: Text('Create Job Destination')),
      ),
      GoRoute(
        path: '/company/jobs/:jobId/edit',
        builder: (_, _) => const Scaffold(body: Text('Edit Destination')),
      ),
      GoRoute(
        path: '/company/jobs/:jobId/applicants',
        builder: (_, _) => const Scaffold(body: Text('Applicants Destination')),
      ),
    ],
  );
}

CompanyJob _job({
  required String id,
  required String title,
  String status = 'open',
  int pending = 0,
  DateTime? deadline,
}) {
  return CompanyJob(
    id: id,
    title: title,
    status: status,
    workMode: 'hybrid',
    applicantCount: pending,
    pendingApplicantCount: pending,
    deadline: deadline,
  );
}

class _MockDashboardRepository implements CompanyDashboardRepository {
  _MockDashboardRepository({required this.summary});

  CompanyDashboardSummary summary;

  @override
  Future<CompanyDashboardSummary> fetchSummary() async {
    return summary;
  }
}

class _FailingDashboardRepository implements CompanyDashboardRepository {
  bool shouldFail = true;

  @override
  Future<CompanyDashboardSummary> fetchSummary() async {
    if (shouldFail) {
      throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
    }
    return const CompanyDashboardSummary(
      totalJobs: 4,
      openJobs: 2,
      totalApplicants: 8,
    );
  }
}
