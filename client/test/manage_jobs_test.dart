import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/company_jobs/domain/entities/company_job.dart';
import 'package:client/features/company_jobs/domain/repositories/company_job_repository.dart';
import 'package:client/features/company_jobs/presentation/providers/company_jobs_controller.dart';
import 'package:client/features/company_jobs/presentation/screens/manage_jobs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('manage jobs shows open and closed postings', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyJobRepositoryProvider.overrideWithValue(_CompanyJobs()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManageJobsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flutter Intern'), findsOneWidget);
    expect(find.text('เปิดรับ'), findsOneWidget);
    expect(find.text('งานที่ปิดแล้ว'), findsOneWidget);
    expect(find.text('ปิดรับ'), findsOneWidget);
    expect(find.text('ผู้สมัคร 0 คน'), findsNWidgets(2));
    expect(find.text('แก้ไข'), findsNWidgets(2));
    expect(find.text('ผู้สมัคร'), findsNWidgets(2));
  });
}

class _CompanyJobs implements CompanyJobRepository {
  @override
  Future<List<CompanyJob>> fetchMine() async {
    return const [
      CompanyJob(
        id: 'job-1',
        title: 'Flutter Intern',
        status: 'open',
        applicantCount: 0,
      ),
      CompanyJob(
        id: 'job-2',
        title: 'งานที่ปิดแล้ว',
        status: 'closed',
        applicantCount: 0,
      ),
    ];
  }

  @override
  Future<EditableJob> fetchOne(String jobId) {
    throw UnimplementedError();
  }

  @override
  Future<CreatedJob> create(JobPosting posting) {
    throw UnimplementedError();
  }

  @override
  Future<EditableJob> update({
    required String jobId,
    required JobPosting posting,
    required int version,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> remove(String jobId) {
    throw UnimplementedError();
  }

  @override
  Future<void> setStatus({required String jobId, required String status}) {
    throw UnimplementedError();
  }

  @override
  Future<List<Applicant>> fetchApplicants(String jobId) {
    throw UnimplementedError();
  }

  @override
  Future<Applicant> fetchApplicant({
    required String jobId,
    required String applicationId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateApplicantStatus({
    required String jobId,
    required String applicationId,
    required String status,
  }) {
    throw UnimplementedError();
  }
}
