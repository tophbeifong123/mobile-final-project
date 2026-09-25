import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/company_jobs/domain/entities/company_job.dart';
import 'package:client/features/company_jobs/domain/repositories/company_job_repository.dart';
import 'package:client/features/company_jobs/presentation/providers/company_jobs_controller.dart';
import 'package:client/features/company_jobs/presentation/screens/applicants_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('applicants screen shows empty state when list is empty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/company/jobs/job-1/applicants',
      routes: [
        GoRoute(
          path: '/company/jobs/:jobId/applicants',
          builder: (context, state) =>
              ApplicantsScreen(jobId: state.pathParameters['jobId']!),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyJobRepositoryProvider.overrideWithValue(
            _FakeCompanyJobRepository(applicants: const []),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('รายชื่อผู้สมัคร'), findsOneWidget);
    expect(find.text('ยังไม่มีผู้สมัคร'), findsOneWidget);
    expect(find.text('ยังไม่มีนักศึกษาสมัครในตำแหน่งงานนี้'), findsOneWidget);
  });

  testWidgets(
    'applicants screen displays applicants with name, university, major, and status',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final applicants = [
        const Applicant(
          applicationId: 'app-1',
          fullName: 'สมชาย ใจดี',
          university: 'จุฬาลงกรณ์มหาวิทยาลัย',
          major: 'วิทยาการคอมพิวเตอร์',
          status: 'submitted',
          coverLetter: 'อยากฝึกงานครับ',
        ),
        const Applicant(
          applicationId: 'app-2',
          fullName: 'สมหญิง จริงใจ',
          university: 'มหาวิทยาลัยเกษตรศาสตร์',
          major: 'เทคโนโลยีสารสนเทศ',
          status: 'reviewing',
          coverLetter: 'พร้อมเรียนรู้งานค่ะ',
        ),
      ];

      final router = GoRouter(
        initialLocation: '/company/jobs/job-1/applicants',
        routes: [
          GoRoute(
            path: '/company/jobs/:jobId/applicants',
            builder: (context, state) =>
                ApplicantsScreen(jobId: state.pathParameters['jobId']!),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            companyJobRepositoryProvider.overrideWithValue(
              _FakeCompanyJobRepository(applicants: applicants),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('สมชาย ใจดี'), findsOneWidget);
      expect(
        find.text('จุฬาลงกรณ์มหาวิทยาลัย • วิทยาการคอมพิวเตอร์'),
        findsOneWidget,
      );
      expect(find.text('ยื่นใบสมัครแล้ว'), findsOneWidget);

      expect(find.text('สมหญิง จริงใจ'), findsOneWidget);
      expect(
        find.text('มหาวิทยาลัยเกษตรศาสตร์ • เทคโนโลยีสารสนเทศ'),
        findsOneWidget,
      );
      expect(find.text('กำลังพิจารณา'), findsOneWidget);
    },
  );

  testWidgets('tapping applicant navigates to applicant detail screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final applicants = [
      const Applicant(
        applicationId: 'app-123',
        fullName: 'สมบูรณ์ มุ่งมั่น',
        university: 'ธรรมศาสตร์',
        major: 'วิศวกรรมคอมพิวเตอร์',
        status: 'submitted',
        coverLetter: 'สนใจตำแหน่งนี้ครับ',
      ),
    ];

    final router = GoRouter(
      initialLocation: '/company/jobs/job-99/applicants',
      routes: [
        GoRoute(
          path: '/company/jobs/:jobId/applicants',
          builder: (context, state) =>
              ApplicantsScreen(jobId: state.pathParameters['jobId']!),
          routes: [
            GoRoute(
              path: ':applicationId',
              builder: (context, state) => Scaffold(
                body: Text(
                  'Applicant Detail: ${state.pathParameters['jobId']} / ${state.pathParameters['applicationId']}',
                ),
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
          companyJobRepositoryProvider.overrideWithValue(
            _FakeCompanyJobRepository(applicants: applicants),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('สมบูรณ์ มุ่งมั่น'), findsOneWidget);

    await tester.tap(find.text('สมบูรณ์ มุ่งมั่น'));
    await tester.pumpAndSettle();

    expect(find.text('Applicant Detail: job-99 / app-123'), findsOneWidget);
  });

  testWidgets(
    'shows error state when fetching applicants fails and retry works',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeCompanyJobRepository(
        error: const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'),
      );

      final router = GoRouter(
        initialLocation: '/company/jobs/job-1/applicants',
        routes: [
          GoRoute(
            path: '/company/jobs/:jobId/applicants',
            builder: (context, state) =>
                ApplicantsScreen(jobId: state.pathParameters['jobId']!),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            companyJobRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('โหลดรายชื่อผู้สมัครไม่ได้'), findsOneWidget);
      expect(find.text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'), findsOneWidget);
      expect(find.text('ลองอีกครั้ง'), findsOneWidget);

      fakeRepo.error = null;
      fakeRepo.applicants = [
        const Applicant(
          applicationId: 'app-recovered',
          fullName: 'กิตติศักดิ์ ชัยชนะ',
          university: 'สจล.',
          major: 'ไอที',
          status: 'accepted',
          coverLetter: 'สำเร็จแล้วครับ',
        ),
      ];

      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pumpAndSettle();

      expect(find.text('กิตติศักดิ์ ชัยชนะ'), findsOneWidget);
      expect(find.text('ผ่านการคัดเลือก'), findsOneWidget);
    },
  );
}

class _FakeCompanyJobRepository implements CompanyJobRepository {
  _FakeCompanyJobRepository({this.applicants = const [], this.error});

  List<Applicant> applicants;
  AppException? error;

  @override
  Future<List<Applicant>> fetchApplicants(String jobId) async {
    if (error != null) throw error!;
    return applicants;
  }

  @override
  Future<List<CompanyJob>> fetchMine() async => [];

  @override
  Future<EditableJob> fetchOne(String jobId) async =>
      throw UnimplementedError();

  @override
  Future<CreatedJob> create(JobPosting posting) async =>
      throw UnimplementedError();

  @override
  Future<EditableJob> update({
    required String jobId,
    required JobPosting posting,
    required int version,
  }) async => throw UnimplementedError();

  @override
  Future<void> remove(String jobId) async {}

  @override
  Future<void> setStatus({
    required String jobId,
    required String status,
  }) async {}

  @override
  Future<Applicant> fetchApplicant({
    required String jobId,
    required String applicationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateApplicantStatus({
    required String jobId,
    required String applicationId,
    required String status,
  }) async {}
}
