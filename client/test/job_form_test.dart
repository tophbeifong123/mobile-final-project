import 'package:client/core/network/dio_client.dart';
import 'package:client/core/provinces/thai_province.dart';
import 'package:client/core/provinces/thai_provinces_provider.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/company_jobs/domain/entities/company_job.dart';
import 'package:client/features/company_jobs/domain/repositories/company_job_repository.dart';
import 'package:client/features/company_jobs/presentation/providers/company_jobs_controller.dart';
import 'package:client/features/company_jobs/presentation/screens/job_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  const provinces = [
    ThaiProvince(id: 90, nameTh: 'สงขลา'),
    ThaiProvince(
      id: 10,
      nameTh: 'กรุงเทพมหานคร',
      aliases: ['กรุงเทพฯ', 'กทม.'],
    ),
  ];

  testWidgets('company creates an open job posting', (tester) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeCompanyJobRepository();
    final router = GoRouter(
      initialLocation: '/company/jobs/new',
      routes: [
        GoRoute(
          path: '/company/jobs/new',
          builder: (context, state) => const JobFormScreen(),
        ),
        GoRoute(
          path: '/company/jobs',
          builder: (context, state) =>
              const Scaffold(body: Text('รายการประกาศ')),
        ),
        GoRoute(
          path: '/company/jobs/:jobId',
          builder: (context, state) => Scaffold(
            body: Text('รายละเอียด ${state.pathParameters['jobId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyJobRepositoryProvider.overrideWithValue(repository),
          thaiProvincesProvider.overrideWith((ref) async => provinces),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('job-title-field')),
      'Flutter Intern',
    );
    await tester.enterText(
      find.byKey(const Key('job-description-field')),
      'ช่วยพัฒนาแอป',
    );
    await tester.tap(find.byKey(const Key('job-province-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('province-90')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('job-category-picker')));
    await tester.tap(find.byKey(const Key('job-category-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-IT & Software')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('job-requirements-field')));
    await tester.enterText(
      find.byKey(const Key('job-requirements-field')),
      'ใช้ Flutter ได้',
    );
    await tester.ensureVisible(find.byKey(const Key('job-openings-field')));
    await tester.enterText(find.byKey(const Key('job-openings-field')), '0');
    await tester.ensureVisible(find.text('สร้างประกาศ').last);
    await tester.tap(find.text('สร้างประกาศ').last);
    await tester.pump();
    expect(repository.lastPosting, isNull);
    expect(find.text('ระบุจำนวนเต็มบวก ไม่เกิน 2147483647'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('job-openings-field')), '3');
    await tester.ensureVisible(find.text('สร้างประกาศ').last);
    await tester.tap(find.text('สร้างประกาศ').last);
    await tester.pumpAndSettle();

    expect(repository.lastPosting?.title, 'Flutter Intern');
    expect(repository.lastPosting?.province, 'สงขลา');
    expect(repository.lastPosting?.workMode, 'hybrid');
    expect(repository.lastPosting?.hasAllowance, isFalse);
    expect(repository.lastPosting?.allowanceAmount, isNull);
    expect(repository.lastPosting?.openings, 3);
    expect(repository.lastPosting?.category, 'IT & Software');
    expect(find.text('รายละเอียด job-1'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2800));
  });

  testWidgets('allowance requires an amount before the posting is saved', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeCompanyJobRepository();
    final router = GoRouter(
      initialLocation: '/company/jobs/new',
      routes: [
        GoRoute(
          path: '/company/jobs/new',
          builder: (context, state) => const JobFormScreen(),
        ),
        GoRoute(
          path: '/company/jobs/:jobId',
          builder: (context, state) => const Scaffold(body: Text('รายละเอียด')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyJobRepositoryProvider.overrideWithValue(repository),
          thaiProvincesProvider.overrideWith((ref) async => provinces),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('job-title-field')),
      'Flutter Intern',
    );
    await tester.enterText(
      find.byKey(const Key('job-description-field')),
      'ช่วยพัฒนาแอป',
    );
    await tester.tap(find.byKey(const Key('job-province-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('province-90')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('job-category-picker')));
    await tester.tap(find.byKey(const Key('job-category-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-IT & Software')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('มีเบี้ยเลี้ยง'));
    await tester.tap(find.text('มีเบี้ยเลี้ยง'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('job-requirements-field')));
    await tester.enterText(
      find.byKey(const Key('job-requirements-field')),
      'ใช้ Flutter ได้',
    );
    await tester.ensureVisible(find.text('สร้างประกาศ').last);
    await tester.tap(find.text('สร้างประกาศ').last);
    await tester.pump();

    expect(find.text('ระบุจำนวนเงินเป็นบาท'), findsOneWidget);
    expect(repository.lastPosting, isNull);

    await tester.enterText(
      find.byKey(const Key('job-allowance-amount')),
      '8000',
    );
    await tester.ensureVisible(find.text('สร้างประกาศ').last);
    await tester.tap(find.text('สร้างประกาศ').last);
    await tester.pumpAndSettle();

    expect(repository.lastPosting?.hasAllowance, isTrue);
    expect(repository.lastPosting?.allowanceAmount, 8000);
    await tester.pump(const Duration(milliseconds: 2800));
  });

  testWidgets('company edits and deletes its own posting', (tester) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeCompanyJobRepository();
    final router = GoRouter(
      initialLocation: '/company/jobs/job-1/edit',
      routes: [
        GoRoute(
          path: '/company/jobs/:jobId/edit',
          builder: (context, state) =>
              JobFormScreen(jobId: state.pathParameters['jobId']),
        ),
        GoRoute(
          path: '/company/jobs',
          builder: (context, state) =>
              const Scaffold(body: Text('รายการประกาศ')),
        ),
        GoRoute(
          path: '/company/jobs/:jobId',
          builder: (context, state) => Scaffold(
            body: Text('รายละเอียด ${state.pathParameters['jobId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyJobRepositoryProvider.overrideWithValue(repository),
          thaiProvincesProvider.overrideWith((ref) async => provinces),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flutter Intern'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('job-title-field')),
      'Backend Intern',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('job-openings-field')))
          .controller
          ?.text,
      '3',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('job-allowance-amount')))
          .controller
          ?.text,
      '8000',
    );
    await tester.enterText(find.byKey(const Key('job-openings-field')), '4');
    await tester.ensureVisible(find.text('มีเบี้ยเลี้ยง'));
    await tester.tap(find.text('มีเบี้ยเลี้ยง'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('job-allowance-amount')), findsNothing);
    await tester.ensureVisible(find.text('บันทึกประกาศ'));
    await tester.tap(find.text('บันทึกประกาศ'));
    await tester.pumpAndSettle();

    expect(repository.lastPosting?.title, 'Backend Intern');
    expect(repository.lastVersion, 1);
    expect(repository.lastPosting?.openings, 4);
    expect(repository.lastPosting?.allowanceAmount, isNull);
    expect(repository.lastPosting?.hasAllowance, isFalse);
    expect(find.text('รายละเอียด job-1'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2800));

    router.go('/company/jobs/job-1/edit');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ลบประกาศ'));
    await tester.tap(find.text('ลบประกาศ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ'));
    await tester.pumpAndSettle();

    expect(repository.removedId, 'job-1');
    expect(find.text('รายการประกาศ'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2800));
  });

  testWidgets('edit job form keeps fields and actions on a wide screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/company/jobs/job-1/edit',
      routes: [
        GoRoute(
          path: '/company/jobs/:jobId/edit',
          builder: (context, state) =>
              JobFormScreen(jobId: state.pathParameters['jobId']),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyJobRepositoryProvider.overrideWithValue(
            _FakeCompanyJobRepository(),
          ),
          thaiProvincesProvider.overrideWith((ref) async => provinces),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flutter Intern'), findsOneWidget);
    expect(find.text('บันทึกประกาศ'), findsOneWidget);
    expect(find.text('ลบประกาศ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeCompanyJobRepository implements CompanyJobRepository {
  JobPosting? lastPosting;
  int? lastVersion;
  String? removedId;

  @override
  Future<CreatedJob> create(JobPosting posting) async {
    lastPosting = posting;
    return const CreatedJob(id: 'job-1', status: 'open');
  }

  @override
  Future<EditableJob> fetchOne(String jobId) async {
    return const EditableJob(
      id: 'job-1',
      title: 'Flutter Intern',
      description: 'ช่วยพัฒนาแอป',
      province: 'สงขลา',
      workMode: 'hybrid',
      category: 'IT & Software',
      hasAllowance: true,
      openings: 3,
      allowanceAmount: 8000,
      requirements: 'ใช้ Flutter ได้',
      status: 'open',
      version: 1,
    );
  }

  @override
  Future<EditableJob> update({
    required String jobId,
    required JobPosting posting,
    required int version,
  }) async {
    lastPosting = posting;
    lastVersion = version;
    return EditableJob(
      id: jobId,
      title: posting.title,
      description: posting.description,
      province: posting.province,
      workMode: posting.workMode,
      category: posting.category,
      hasAllowance: posting.hasAllowance,
      openings: posting.openings,
      allowanceAmount: posting.allowanceAmount,
      requirements: posting.requirements,
      status: 'open',
      version: version + 1,
    );
  }

  @override
  Future<void> remove(String jobId) async {
    removedId = jobId;
  }

  @override
  Future<CompanyOwnedJob> fetchOwned(String jobId) {
    throw UnimplementedError();
  }

  @override
  Future<List<CompanyJob>> fetchMine() async => const [];

  @override
  Future<Applicant> fetchApplicant({
    required String jobId,
    required String applicationId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<Applicant>> fetchApplicants(String jobId) async => const [];

  @override
  Future<List<int>> downloadApplicantDocument({
    required String jobId,
    required String applicationId,
    required String documentId,
  }) async => throw UnimplementedError();

  @override
  Future<void> setStatus({
    required String jobId,
    required String status,
  }) async {}

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
