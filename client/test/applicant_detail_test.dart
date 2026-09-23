import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/company_jobs/domain/entities/company_job.dart';
import 'package:client/features/company_jobs/domain/repositories/company_job_repository.dart';
import 'package:client/features/company_jobs/presentation/providers/company_jobs_controller.dart';
import 'package:client/features/company_jobs/presentation/screens/applicant_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'applicant detail renders student profile, skills, portfolio, resume, and cover letter',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final applicant = Applicant(
        applicationId: 'app-1',
        fullName: 'สมชาย ใจดี',
        university: 'มหาวิทยาลัยเกษตรศาสตร์',
        major: 'วิทยาการคอมพิวเตอร์',
        status: 'submitted',
        coverLetter: 'มีความสนใจและพร้อมจะเรียนรู้งานอย่างเต็มที่ครับ',
        skills: const ['Flutter', 'Dart', 'Node.js'],
        portfolioUrl: 'https://github.com/somchai',
        resumeFileName: 'somchai-resume.pdf',
        resumeObjectKey: 'resumes/somchai.pdf',
        createdAt: DateTime(2026, 9, 23, 14, 0),
      );

      final fakeRepo = _FakeCompanyJobRepository(applicant: applicant);

      final router = GoRouter(
        initialLocation: '/company/jobs/job-1/applicants/app-1',
        routes: [
          GoRoute(
            path: '/company/jobs/:jobId/applicants/:applicationId',
            builder: (context, state) => ApplicantDetailScreen(
              jobId: state.pathParameters['jobId']!,
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
            companyJobRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('รายละเอียดผู้สมัคร'), findsOneWidget);
      expect(find.text('สมชาย ใจดี'), findsOneWidget);
      expect(
        find.text('มหาวิทยาลัยเกษตรศาสตร์ • วิทยาการคอมพิวเตอร์'),
        findsOneWidget,
      );
      expect(find.text('ยื่นใบสมัครแล้ว'), findsOneWidget);
      expect(find.text('ยื่นเมื่อ 23/09/2026'), findsOneWidget);

      expect(find.text('ทักษะความสามารถ'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('Node.js'), findsOneWidget);

      expect(find.text('Portfolio / ผลงาน'), findsOneWidget);
      expect(find.text('https://github.com/somchai'), findsOneWidget);

      expect(find.text('Resume ที่ใช้สมัคร'), findsOneWidget);
      expect(find.text('somchai-resume.pdf'), findsOneWidget);
      expect(find.text('สำเนา Resume ในระบบ ณ วันที่ยื่นใบสมัคร'), findsOneWidget);

      expect(find.text('Cover Letter'), findsOneWidget);
      expect(
        find.text('มีความสนใจและพร้อมจะเรียนรู้งานอย่างเต็มที่ครับ'),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows error state when fetching applicant detail fails and retry works', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeRepo = _FakeCompanyJobRepository(
      error: const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'),
    );

    final router = GoRouter(
      initialLocation: '/company/jobs/job-1/applicants/app-1',
      routes: [
        GoRoute(
          path: '/company/jobs/:jobId/applicants/:applicationId',
          builder: (context, state) => ApplicantDetailScreen(
            jobId: state.pathParameters['jobId']!,
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
          companyJobRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดข้อมูลผู้สมัครไม่ได้'), findsOneWidget);
    expect(find.text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);

    fakeRepo.error = null;
    fakeRepo.applicant = const Applicant(
      applicationId: 'app-1',
      fullName: 'สุดา ขยันดี',
      university: 'มหิดล',
      major: 'เทคโนโลยีสารสนเทศ',
      status: 'reviewing',
      coverLetter: 'ขอโอกาสฝึกงานด้วยค่ะ',
    );

    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();

    expect(find.text('สุดา ขยันดี'), findsOneWidget);
    expect(find.text('กำลังพิจารณา'), findsOneWidget);
  });

  testWidgets(
    'shows action button when status is submitted and transitions to reviewing upon tap',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final applicant = Applicant(
        applicationId: 'app-1',
        fullName: 'สมชาย ใจดี',
        university: 'มหาวิทยาลัยเกษตรศาสตร์',
        major: 'วิทยาการคอมพิวเตอร์',
        status: 'submitted',
        coverLetter: 'มีความสนใจและพร้อมจะเรียนรู้งานอย่างเต็มที่ครับ',
        skills: const ['Flutter'],
        createdAt: DateTime(2026, 9, 23, 14, 0),
      );

      final fakeRepo = _FakeCompanyJobRepository(applicant: applicant);

      final router = GoRouter(
        initialLocation: '/company/jobs/job-1/applicants/app-1',
        routes: [
          GoRoute(
            path: '/company/jobs/:jobId/applicants/:applicationId',
            builder: (context, state) => ApplicantDetailScreen(
              jobId: state.pathParameters['jobId']!,
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
            companyJobRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('เปลี่ยนสถานะเป็น Reviewing'), findsOneWidget);

      await tester.tap(find.text('เปลี่ยนสถานะเป็น Reviewing'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(fakeRepo.updateCallCount, 1);
      expect(fakeRepo.updatedJobId, 'job-1');
      expect(fakeRepo.updatedApplicationId, 'app-1');
      expect(fakeRepo.updatedStatus, 'reviewing');

      expect(find.text('เปลี่ยนสถานะเป็น Reviewing แล้ว'), findsOneWidget);
      expect(find.text('กำลังพิจารณา'), findsOneWidget);
      expect(find.text('เปลี่ยนสถานะเป็น Reviewing'), findsNothing);
    },
  );

  testWidgets(
    'shows error snackbar when changing status to reviewing fails',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final applicant = Applicant(
        applicationId: 'app-1',
        fullName: 'สมชาย ใจดี',
        university: 'มหาวิทยาลัยเกษตรศาสตร์',
        major: 'วิทยาการคอมพิวเตอร์',
        status: 'submitted',
        coverLetter: 'มีความสนใจและพร้อมจะเรียนรู้งานอย่างเต็มที่ครับ',
        skills: const ['Flutter'],
        createdAt: DateTime(2026, 9, 23, 14, 0),
      );

      final fakeRepo = _FakeCompanyJobRepository(
        applicant: applicant,
        updateError: const AppException('เกิดข้อผิดพลาดในการเปลี่ยนสถานะ'),
      );

      final router = GoRouter(
        initialLocation: '/company/jobs/job-1/applicants/app-1',
        routes: [
          GoRoute(
            path: '/company/jobs/:jobId/applicants/:applicationId',
            builder: (context, state) => ApplicantDetailScreen(
              jobId: state.pathParameters['jobId']!,
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
            companyJobRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('เปลี่ยนสถานะเป็น Reviewing'), findsOneWidget);

      await tester.tap(find.text('เปลี่ยนสถานะเป็น Reviewing'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('เกิดข้อผิดพลาดในการเปลี่ยนสถานะ'), findsOneWidget);
      expect(find.text('เปลี่ยนสถานะเป็น Reviewing'), findsOneWidget);
    },
  );
}

class _FakeCompanyJobRepository implements CompanyJobRepository {
  _FakeCompanyJobRepository({
    this.applicant,
    this.error,
    this.updateError,
  });

  Applicant? applicant;
  AppException? error;
  AppException? updateError;
  int updateCallCount = 0;
  String? updatedJobId;
  String? updatedApplicationId;
  String? updatedStatus;

  @override
  Future<Applicant> fetchApplicant({
    required String jobId,
    required String applicationId,
  }) async {
    if (error != null) throw error!;
    return applicant!;
  }

  @override
  Future<List<Applicant>> fetchApplicants(String jobId) async => [];

  @override
  Future<List<CompanyJob>> fetchMine() async => [];

  @override
  Future<EditableJob> fetchOne(String jobId) async => throw UnimplementedError();

  @override
  Future<CreatedJob> create(JobPosting posting) async =>
      throw UnimplementedError();

  @override
  Future<EditableJob> update({
    required String jobId,
    required JobPosting posting,
    required int version,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> remove(String jobId) async {}

  @override
  Future<void> setStatus({required String jobId, required String status}) async {}

  @override
  Future<void> updateApplicantStatus({
    required String jobId,
    required String applicationId,
    required String status,
  }) async {
    if (updateError != null) throw updateError!;
    updateCallCount++;
    updatedJobId = jobId;
    updatedApplicationId = applicationId;
    updatedStatus = status;
    if (applicant != null) {
      applicant = Applicant(
        applicationId: applicant!.applicationId,
        fullName: applicant!.fullName,
        university: applicant!.university,
        major: applicant!.major,
        status: status,
        coverLetter: applicant!.coverLetter,
        skills: applicant!.skills,
        portfolioUrl: applicant!.portfolioUrl,
        resumeFileName: applicant!.resumeFileName,
        resumeObjectKey: applicant!.resumeObjectKey,
        createdAt: applicant!.createdAt,
      );
    }
  }
}

