import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/router/company_shell.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/company_dashboard/domain/entities/company_dashboard_summary.dart';
import 'package:client/features/company_dashboard/domain/repositories/company_dashboard_repository.dart';
import 'package:client/features/company_dashboard/presentation/providers/company_dashboard_controller.dart';
import 'package:client/features/company_dashboard/presentation/screens/company_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:client/features/company_dashboard/data/models/company_dashboard_summary_model.dart';

void main() {
  testWidgets(
    'dashboard refreshes real counts after returning from job creation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            companyDashboardRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
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
    },
  );

  testWidgets(
    'dashboard tab returns after opening the jobs page from a shortcut',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            companyDashboardRepositoryProvider.overrideWithValue(
              _MockDashboardRepository(
                summary: const CompanyDashboardSummary(
                  totalJobs: 4,
                  openJobs: 2,
                  totalApplicants: 1,
                ),
              ),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('จัดการประกาศ'), 200);
      await tester.tap(find.text('จัดการประกาศ'));
      await tester.pumpAndSettle();
      expect(find.text('Manage Jobs Destination'), findsOneWidget);

      await tester.tap(find.text('Jobs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      expect(find.text('แดชบอร์ดบริษัท'), findsOneWidget);
      expect(find.text('Manage Jobs Destination'), findsNothing);
      expect(router.state.uri.path, '/company/dashboard');
    },
  );

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

  for (final label in [
    'ประกาศทั้งหมด',
    'ประกาศที่เปิดรับ',
    'ผู้สมัครทั้งหมด',
    'ใบสมัครที่รอตรวจ',
    'จัดการประกาศ',
    'สร้างประกาศ',
  ]) {
    testWidgets('zero-data dashboard routes $label to the correct page', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        initialLocation: '/company/dashboard',
        routes: [
          GoRoute(
            path: '/company/dashboard',
            builder: (_, _) => const CompanyDashboardScreen(),
          ),
          GoRoute(
            path: '/company/jobs',
            builder: (_, _) =>
                const Scaffold(body: Text('Manage Jobs Destination')),
          ),
          GoRoute(
            path: '/company/jobs/new',
            builder: (_, _) =>
                const Scaffold(body: Text('Create Job Destination')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            companyDashboardRepositoryProvider.overrideWithValue(
              _MockDashboardRepository(
                summary: const CompanyDashboardSummary(
                  totalJobs: 0,
                  openJobs: 0,
                  totalApplicants: 0,
                ),
              ),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0'), findsNWidgets(4));
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(
        find.text(
          label == 'สร้างประกาศ'
              ? 'Create Job Destination'
              : 'Manage Jobs Destination',
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('company dashboard displays summary statistics correctly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = _MockDashboardRepository(
      summary: const CompanyDashboardSummary(
        totalJobs: 5,
        openJobs: 3,
        totalApplicants: 12,
        pendingApplicants: 7,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyDashboardRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompanyDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('แดชบอร์ดบริษัท'), findsOneWidget);
    expect(find.text('ประกาศทั้งหมด'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('ประกาศที่เปิดรับ'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('ผู้สมัครทั้งหมด'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('ใบสมัครที่รอตรวจ'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsNothing);

    expect(find.text('สร้างประกาศ'), findsOneWidget);
    expect(find.text('จัดการประกาศ'), findsOneWidget);
  });

  testWidgets('company dashboard displays 0 applicants when empty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = _MockDashboardRepository(
      summary: const CompanyDashboardSummary(
        totalJobs: 0,
        openJobs: 0,
        totalApplicants: 0,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyDashboardRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompanyDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ประกาศทั้งหมด'), findsOneWidget);
    expect(find.text('ผู้สมัครทั้งหมด'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(4));
  });

  testWidgets('company dashboard shows error view and retries', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = _FailingDashboardRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyDashboardRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompanyDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดข้อมูลแดชบอร์ดไม่สำเร็จ'), findsOneWidget);
    expect(find.text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'), findsOneWidget);
    expect(find.text('ลองใหม่อีกครั้ง'), findsOneWidget);

    // Now make it succeed on retry
    mockRepo.shouldFail = false;
    await tester.tap(find.text('ลองใหม่อีกครั้ง'));
    await tester.pumpAndSettle();

    expect(find.text('แดชบอร์ดบริษัท'), findsOneWidget);
    expect(find.text('ประกาศทั้งหมด'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });
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
