import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/applications/domain/entities/job_application.dart';
import 'package:client/features/applications/domain/repositories/application_repository.dart';
import 'package:client/features/applications/presentation/providers/applications_controller.dart';
import 'package:client/features/applications/presentation/screens/my_applications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('my applications shows empty state when list is empty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/student/applications',
      routes: [
        GoRoute(
          path: '/student/applications',
          builder: (context, state) => const MyApplicationsScreen(),
        ),
        GoRoute(
          path: '/student/home',
          builder: (context, state) => const Scaffold(body: Text('หน้าแรก')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          applicationRepositoryProvider.overrideWithValue(
            _FakeApplicationRepository(applications: const []),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีใบสมัคร'), findsOneWidget);
    expect(find.text('ค้นหางานเพื่อสมัคร'), findsOneWidget);

    await tester.tap(find.text('ค้นหางานเพื่อสมัคร'));
    await tester.pumpAndSettle();
    expect(find.text('หน้าแรก'), findsOneWidget);
  });

  testWidgets('my applications lists submitted applications with details and navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final apps = [
      JobApplication(
        id: 'app-1',
        jobTitle: 'Flutter Developer Intern',
        companyName: 'TechCorp Co., Ltd.',
        status: ApplicationStatus.submitted,
        coverLetter: 'Interested in Flutter',
        createdAt: DateTime(2026, 9, 23, 10, 0),
      ),
      JobApplication(
        id: 'app-2',
        jobTitle: 'Backend Engineer Intern',
        companyName: 'DevHub Inc.',
        status: ApplicationStatus.reviewing,
        coverLetter: 'Interested in NestJS',
        createdAt: DateTime(2026, 9, 20, 14, 30),
      ),
    ];

    final router = GoRouter(
      initialLocation: '/student/applications',
      routes: [
        GoRoute(
          path: '/student/applications',
          builder: (context, state) => const MyApplicationsScreen(),
          routes: [
            GoRoute(
              path: ':applicationId',
              builder: (context, state) => Scaffold(
                body: Text('รายละเอียดใบสมัคร ${state.pathParameters['applicationId']}'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          applicationRepositoryProvider.overrideWithValue(
            _FakeApplicationRepository(applications: apps),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flutter Developer Intern'), findsOneWidget);
    expect(find.text('TechCorp Co., Ltd.'), findsOneWidget);
    expect(find.text('ยื่นใบสมัครแล้ว'), findsOneWidget);
    expect(find.text('สมัครเมื่อ 23/09/2026'), findsOneWidget);

    expect(find.text('Backend Engineer Intern'), findsOneWidget);
    expect(find.text('DevHub Inc.'), findsOneWidget);
    expect(find.text('กำลังพิจารณา'), findsOneWidget);
    expect(find.text('สมัครเมื่อ 20/09/2026'), findsOneWidget);

    await tester.tap(find.text('Flutter Developer Intern'));
    await tester.pumpAndSettle();
    expect(find.text('รายละเอียดใบสมัคร app-1'), findsOneWidget);
  });

  testWidgets('my applications shows error state and retries on press', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeApplicationRepository(
      error: const AppException('เครือข่ายขัดข้อง'),
    );

    final router = GoRouter(
      initialLocation: '/student/applications',
      routes: [
        GoRoute(
          path: '/student/applications',
          builder: (context, state) => const MyApplicationsScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          applicationRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดรายการใบสมัครไม่ได้'), findsOneWidget);
    expect(find.text('เครือข่ายขัดข้อง'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);

    repo.error = null;
    repo.applications = [
      JobApplication(
        id: 'app-retry',
        jobTitle: 'UX Designer Intern',
        companyName: 'Creative Studio',
        status: ApplicationStatus.accepted,
        coverLetter: 'UI/UX passion',
      ),
    ];

    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();

    expect(find.text('UX Designer Intern'), findsOneWidget);
    expect(find.text('ผ่านการคัดเลือก'), findsOneWidget);
  });
}

class _FakeApplicationRepository implements ApplicationRepository {
  _FakeApplicationRepository({
    this.applications = const [],
    this.error,
  });

  List<JobApplication> applications;
  AppException? error;

  @override
  Future<List<JobApplication>> fetchMine() async {
    if (error != null) {
      throw error!;
    }
    return applications;
  }

  @override
  Future<JobApplication> fetchDetail(String applicationId) async {
    throw UnimplementedError();
  }

  @override
  Future<JobApplication> apply({
    required String jobId,
    required String coverLetter,
  }) async {
    throw UnimplementedError();
  }
}
