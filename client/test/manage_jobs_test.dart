import 'package:client/core/error/app_exception.dart';
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

  testWidgets('toggling switch calls setStatus with new status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = _CompanyJobs();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyJobRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManageJobsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Toggle job-1 from open to closed
    final switch1 = find.byKey(const ValueKey('toggle-job-job-1'));
    expect(switch1, findsOneWidget);
    expect(tester.widget<Switch>(switch1).value, isTrue);

    await tester.tap(switch1);
    await tester.pumpAndSettle();

    expect(mockRepo.lastSetStatusJobId, 'job-1');
    expect(mockRepo.lastSetStatusValue, 'closed');

    // Toggle job-2 from closed to open
    final switch2 = find.byKey(const ValueKey('toggle-job-job-2'));
    expect(switch2, findsOneWidget);
    expect(tester.widget<Switch>(switch2).value, isFalse);

    await tester.tap(switch2);
    await tester.pumpAndSettle();

    expect(mockRepo.lastSetStatusJobId, 'job-2');
    expect(mockRepo.lastSetStatusValue, 'open');
  });

  testWidgets('shows snackbar when toggle status fails', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = _FailingCompanyJobs();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyJobRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManageJobsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final switch1 = find.byKey(const ValueKey('toggle-job-job-1'));
    await tester.tap(switch1);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('เปลี่ยนสถานะไม่สำเร็จ'), findsOneWidget);
  });
}

class _CompanyJobs implements CompanyJobRepository {
  String? lastSetStatusJobId;
  String? lastSetStatusValue;

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
  Future<void> setStatus({
    required String jobId,
    required String status,
  }) async {
    lastSetStatusJobId = jobId;
    lastSetStatusValue = status;
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

class _FailingCompanyJobs extends _CompanyJobs {
  @override
  Future<void> setStatus({
    required String jobId,
    required String status,
  }) async {
    throw const AppException('เปลี่ยนสถานะไม่สำเร็จ');
  }
}
