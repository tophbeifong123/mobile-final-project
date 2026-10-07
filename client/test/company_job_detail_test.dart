import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/company_jobs/data/models/company_job_model.dart';
import 'package:client/features/company_jobs/domain/entities/company_job.dart';
import 'package:client/features/company_jobs/domain/repositories/company_job_repository.dart';
import 'package:client/features/company_jobs/presentation/providers/company_jobs_controller.dart';
import 'package:client/features/company_jobs/presentation/screens/company_job_detail_screen.dart';
import 'package:client/features/company_jobs/presentation/screens/manage_jobs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('owned job json keeps counts and deadline', () {
    final model = CompanyOwnedJobModel.fromJson({
      'id': 'job-1',
      'title': 'Flutter Intern',
      'description': 'ช่วยพัฒนาแอป',
      'province': 'สงขลา',
      'workMode': 'hybrid',
      'category': 'IT',
      'hasAllowance': true,
      'requirements': 'ใช้ Flutter ได้',
      'skills': ['Flutter'],
      'status': 'closed',
      'version': 3,
      'applicantCount': 4,
      'pendingApplicantCount': 2,
      'deadline': '2026-12-31T00:00:00.000Z',
    });

    final job = model.toEntity();
    expect(job.applicantCount, 4);
    expect(job.pendingApplicantCount, 2);
    expect(job.deadline, DateTime.parse('2026-12-31T00:00:00.000Z'));
    expect(job.skills, ['Flutter']);
  });

  testWidgets('company job detail shows the posting and applicant counts', (
    tester,
  ) async {
    await _pumpDetail(tester, const Size(390, 900));

    expect(find.text('Flutter Intern'), findsOneWidget);
    expect(find.text('สงขลา'), findsOneWidget);
    expect(find.text('Hybrid'), findsOneWidget);
    expect(find.text('IT & Software'), findsOneWidget);
    expect(find.text('มีเบี้ยเลี้ยง'), findsOneWidget);
    expect(find.text('ช่วยพัฒนาแอป'), findsOneWidget);
    expect(find.text('ใช้ Flutter ได้'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Flutter'), 200);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('ผู้สมัครทั้งหมด 4 คน'), findsOneWidget);
    expect(find.text('2 ใบรอตรวจ'), findsOneWidget);
    expect(find.text('ปิดรับสมัคร'), findsOneWidget);
    expect(
      find.text('ปิดรับสมัครแล้ว นักศึกษาไม่เห็นประกาศนี้ในหน้าแรก'),
      findsOneWidget,
    );
    expect(find.text('ดูผู้สมัคร'), findsOneWidget);
    expect(find.text('แก้ไขประกาศ'), findsOneWidget);
  });

  testWidgets('wide company job detail keeps the posting and actions', (
    tester,
  ) async {
    await _pumpDetail(tester, const Size(1280, 800));

    expect(find.text('ช่วยพัฒนาแอป'), findsOneWidget);
    expect(find.text('ดูผู้สมัคร'), findsOneWidget);
    expect(find.text('แก้ไขประกาศ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail actions open applicants, edit, and change status', (
    tester,
  ) async {
    final repository = _Jobs();
    final router = _router();
    addTearDown(router.dispose);
    await _mount(tester, router, repository, const Size(390, 900));

    await tester.tap(find.text('ดูผู้สมัคร'));
    await tester.pumpAndSettle();
    expect(find.text('applicants-page'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('แก้ไขประกาศ'));
    await tester.pumpAndSettle();
    expect(find.text('edit-page'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('เปิดรับสมัครอีกครั้ง'));
    await tester.pump();
    await tester.pump();

    expect(repository.lastStatus, 'open');
    expect(find.text('เปิดรับสมัคร'), findsWidgets);
    expect(
      find.text('ปิดรับสมัครแล้ว นักศึกษาไม่เห็นประกาศนี้ในหน้าแรก'),
      findsNothing,
    );
    await tester.pump(const Duration(milliseconds: 2800));
  });

  testWidgets('detail shows an error and retries', (tester) async {
    final repository = _Jobs()..fail = true;
    final router = _router();
    addTearDown(router.dispose);
    await _mount(tester, router, repository, const Size(390, 900));

    expect(find.text('โหลดประกาศไม่ได้'), findsWidgets);
    repository.fail = false;
    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();
    expect(find.text('Flutter Intern'), findsOneWidget);
  });

  testWidgets('tapping a posting opens its detail', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/company/jobs',
      routes: [
        GoRoute(
          path: '/company/jobs',
          builder: (context, state) => const ManageJobsScreen(),
          routes: [
            GoRoute(
              path: ':jobId',
              builder: (context, state) =>
                  Text('detail-${state.pathParameters['jobId']}'),
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
          companyJobRepositoryProvider.overrideWithValue(_Jobs()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Flutter Intern'));
    await tester.pumpAndSettle();
    expect(find.text('detail-job-1'), findsOneWidget);
  });
}

Future<void> _pumpDetail(WidgetTester tester, Size size) async {
  final repository = _Jobs();
  final router = _router();
  addTearDown(router.dispose);
  await _mount(tester, router, repository, size);
}

Future<void> _mount(
  WidgetTester tester,
  GoRouter router,
  _Jobs repository,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
        companyJobRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter _router() {
  return GoRouter(
    initialLocation: '/company/jobs/job-1',
    routes: [
      GoRoute(
        path: '/company/jobs/:jobId',
        builder: (context, state) =>
            CompanyJobDetailScreen(jobId: state.pathParameters['jobId']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const Text('edit-page'),
          ),
          GoRoute(
            path: 'applicants',
            builder: (context, state) => const Text('applicants-page'),
          ),
        ],
      ),
    ],
  );
}

class _Jobs implements CompanyJobRepository {
  bool fail = false;
  String status = 'closed';
  String? lastStatus;

  CompanyOwnedJob get current => CompanyOwnedJob(
    id: 'job-1',
    title: 'Flutter Intern',
    description: 'ช่วยพัฒนาแอป',
    province: 'สงขลา',
    workMode: 'hybrid',
    category: 'IT & Software',
    hasAllowance: true,
    requirements: 'ใช้ Flutter ได้',
    status: status,
    version: 1,
    applicantCount: 4,
    pendingApplicantCount: 2,
    skills: const ['Flutter'],
    deadline: DateTime.utc(2026, 12, 31),
  );

  @override
  Future<CompanyOwnedJob> fetchOwned(String jobId) async {
    if (fail) throw const AppException('โหลดประกาศไม่ได้');
    return current;
  }

  @override
  Future<void> setStatus({
    required String jobId,
    required String status,
  }) async {
    lastStatus = status;
    this.status = status;
  }

  @override
  Future<List<CompanyJob>> fetchMine() async => [
    CompanyJob(
      id: 'job-1',
      title: 'Flutter Intern',
      status: 'open',
      workMode: 'hybrid',
      applicantCount: 4,
      pendingApplicantCount: 2,
    ),
  ];

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
  Future<List<Applicant>> fetchApplicants(String jobId) async => [];

  @override
  Future<Applicant> fetchApplicant({
    required String jobId,
    required String applicationId,
  }) async => throw UnimplementedError();

  @override
  Future<List<int>> downloadApplicantDocument({
    required String jobId,
    required String applicationId,
    required String documentId,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateApplicantStatus({
    required String jobId,
    required String applicationId,
    required String status,
  }) async {}

  @override
  Future<void> setExamLink({
    required String jobId,
    required String applicationId,
    required String url,
    required DateTime deadline,
  }) async {}

  @override
  Future<void> passExam({
    required String jobId,
    required String applicationId,
  }) async {}

  @override
  Future<void> setInterviewLink({
    required String jobId,
    required String applicationId,
    required String url,
    required DateTime startsAt,
  }) async {}
}
