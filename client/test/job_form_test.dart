import 'package:client/core/network/dio_client.dart';
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
  testWidgets('company creates an open job posting', (tester) async {
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
      ],
    );
    addTearDown(router.dispose);

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

    await tester.enterText(
      find.widgetWithText(TextFormField, 'ชื่องาน'),
      'Flutter Intern',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'รายละเอียด'),
      'ช่วยพัฒนาแอป',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'จังหวัด'),
      'สงขลา',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'หมวดงาน'), 'IT');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'คุณสมบัติ'),
      'ใช้ Flutter ได้',
    );
    await tester.ensureVisible(find.text('สร้างประกาศ').last);
    await tester.tap(find.text('สร้างประกาศ').last);
    await tester.pumpAndSettle();

    expect(repository.lastPosting?.title, 'Flutter Intern');
    expect(repository.lastPosting?.workMode, 'hybrid');
    expect(repository.lastPosting?.hasAllowance, isFalse);
    expect(find.text('รายการประกาศ'), findsOneWidget);
  });
}

class _FakeCompanyJobRepository implements CompanyJobRepository {
  JobPosting? lastPosting;

  @override
  Future<CreatedJob> create(JobPosting posting) async {
    lastPosting = posting;
    return const CreatedJob(id: 'job-1', status: 'open');
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
}
