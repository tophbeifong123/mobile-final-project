import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/applications/domain/entities/job_application.dart';
import 'package:client/features/applications/domain/repositories/application_repository.dart';
import 'package:client/features/applications/presentation/providers/applications_controller.dart';
import 'package:client/features/applications/presentation/screens/application_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('application detail renders job, timeline, cover letter and resume', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final app = JobApplication(
      id: 'app-1',
      jobId: 'job-100',
      jobTitle: 'Senior Flutter Developer Intern',
      companyName: 'Acme Software',
      province: 'สงขลา',
      workMode: 'hybrid',
      category: 'Mobile Dev',
      hasAllowance: true,
      status: ApplicationStatus.submitted,
      coverLetter: 'ฉันตั้งใจจะฝึกงานตำแหน่งนี้มากๆ ครับ',
      resumeObjectKey: 'resumes/student-1/cv.pdf',
      createdAt: DateTime(2026, 9, 23, 10, 0),
      timeline: [
        TimelineEvent(
          id: 'event-1',
          fromStatus: null,
          toStatus: ApplicationStatus.submitted,
          createdAt: DateTime(2026, 9, 23, 10, 0),
        ),
      ],
    );

    final router = GoRouter(
      initialLocation: '/student/applications/app-1',
      routes: [
        GoRoute(
          path: '/student/applications/:applicationId',
          builder: (context, state) => ApplicationDetailScreen(
            applicationId: state.pathParameters['applicationId']!,
          ),
        ),
        GoRoute(
          path: '/student/jobs/:jobId',
          builder: (context, state) => const Scaffold(body: Text('หน้ารายละเอียดงาน')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          applicationRepositoryProvider.overrideWithValue(
            _FakeApplicationRepository(detail: app),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Senior Flutter Developer Intern'), findsOneWidget);
    expect(find.text('Acme Software'), findsOneWidget);
    expect(find.text('สงขลา'), findsOneWidget);
    expect(find.text('Hybrid'), findsOneWidget);
    expect(find.text('Mobile Dev'), findsOneWidget);
    expect(find.text('มีเบี้ยเลี้ยง'), findsOneWidget);
    expect(find.text('สถานะการสมัคร'), findsOneWidget);
    expect(find.text('ยื่นใบสมัครแล้ว'), findsNWidgets(2)); // StatusChip + Timeline step
    expect(find.text('กำลังพิจารณา'), findsOneWidget);
    expect(find.text('ผลการคัดเลือก'), findsOneWidget);
    expect(find.text('ฉันตั้งใจจะฝึกงานตำแหน่งนี้มากๆ ครับ'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Resume ที่ใช้สมัคร'), 200);
    expect(find.text('Resume ที่ใช้สมัคร'), findsOneWidget);
    expect(find.text('สำเนา Resume ในระบบ ณ วันที่ยื่นใบสมัคร'), findsOneWidget);

    // Scroll back up to tap 'ดูประกาศงาน'
    await tester.scrollUntilVisible(find.text('ดูประกาศงาน'), -200);
    await tester.tap(find.text('ดูประกาศงาน'));
    await tester.pumpAndSettle();
    expect(find.text('หน้ารายละเอียดงาน'), findsOneWidget);
  });

  testWidgets('application detail renders accepted timeline when application is accepted', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final app = JobApplication(
      id: 'app-accepted',
      jobId: 'job-100',
      jobTitle: 'Backend Engineer Intern',
      companyName: 'CloudCorp',
      status: ApplicationStatus.accepted,
      coverLetter: 'Interested in backend',
      createdAt: DateTime(2026, 9, 20, 9, 0),
      timeline: [
        TimelineEvent(
          id: 'event-1',
          fromStatus: null,
          toStatus: ApplicationStatus.submitted,
          createdAt: DateTime(2026, 9, 20, 9, 0),
        ),
        TimelineEvent(
          id: 'event-2',
          fromStatus: ApplicationStatus.submitted,
          toStatus: ApplicationStatus.reviewing,
          createdAt: DateTime(2026, 9, 21, 11, 0),
        ),
        TimelineEvent(
          id: 'event-3',
          fromStatus: ApplicationStatus.reviewing,
          toStatus: ApplicationStatus.accepted,
          createdAt: DateTime(2026, 9, 22, 16, 0),
        ),
      ],
    );

    final router = GoRouter(
      initialLocation: '/student/applications/app-accepted',
      routes: [
        GoRoute(
          path: '/student/applications/:applicationId',
          builder: (context, state) => ApplicationDetailScreen(
            applicationId: state.pathParameters['applicationId']!,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          applicationRepositoryProvider.overrideWithValue(
            _FakeApplicationRepository(detail: app),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ผ่านการคัดเลือก'), findsNWidgets(2)); // StatusChip + Timeline step
    expect(find.text('ยินดีด้วย คุณผ่านการคัดเลือกสำหรับตำแหน่งนี้'), findsOneWidget);
  });

  testWidgets('application detail renders error and allows retry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeApplicationRepository(error: const AppException('ไม่พบใบสมัคร'));

    final router = GoRouter(
      initialLocation: '/student/applications/app-err',
      routes: [
        GoRoute(
          path: '/student/applications/:applicationId',
          builder: (context, state) => ApplicationDetailScreen(
            applicationId: state.pathParameters['applicationId']!,
          ),
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

    expect(find.text('โหลดรายละเอียดใบสมัครไม่ได้'), findsOneWidget);
    expect(find.text('ไม่พบใบสมัคร'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);

    repo.error = null;
    repo.detail = JobApplication(
      id: 'app-err',
      jobTitle: 'Recovered Job',
      companyName: 'Acme',
      status: ApplicationStatus.submitted,
      coverLetter: 'Fixed',
    );

    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered Job'), findsOneWidget);
  });
}

class _FakeApplicationRepository implements ApplicationRepository {
  _FakeApplicationRepository({
    this.detail,
    this.error,
  });

  JobApplication? detail;
  AppException? error;

  @override
  Future<JobApplication> fetchDetail(String applicationId) async {
    if (error != null) {
      throw error!;
    }
    return detail!;
  }

  @override
  Future<List<JobApplication>> fetchMine() async {
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
