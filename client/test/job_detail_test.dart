import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/jobs/domain/entities/job.dart';
import 'package:client/features/jobs/domain/repositories/job_repository.dart';
import 'package:client/features/jobs/presentation/providers/jobs_controller.dart';
import 'package:client/features/jobs/presentation/screens/job_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('job detail shows the posting and the company', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          jobRepositoryProvider.overrideWithValue(_DetailJobRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const JobDetailScreen(jobId: 'job-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flutter Intern'), findsOneWidget);
    expect(find.text('InternFinder'), findsNWidgets(2));
    expect(find.text('ซอฟต์แวร์'), findsOneWidget);
    expect(find.text('ช่วยพัฒนาแอป'), findsOneWidget);
    expect(find.text('ใช้ Flutter ได้'), findsOneWidget);
    expect(find.text('สงขลา'), findsOneWidget);
    expect(find.text('On-site'), findsOneWidget);
    expect(find.text('เปิดรับ'), findsOneWidget);
    expect(find.text('สมัครงาน'), findsOneWidget);
    expect(find.text('ยังไม่มีข้อมูล'), findsNothing);
  });
}

class _DetailJobRepository implements JobRepository {
  @override
  Future<List<Job>> fetchFeed(JobFilter filter) async => const [];

  @override
  Future<JobDetail> fetchDetail(String jobId) async {
    return const JobDetail(
      id: 'job-1',
      title: 'Flutter Intern',
      description: 'ช่วยพัฒนาแอป',
      province: 'สงขลา',
      workMode: WorkMode.onSite,
      category: 'IT',
      hasAllowance: true,
      requirements: 'ใช้ Flutter ได้',
      status: JobStatus.open,
      companyName: 'InternFinder',
      businessType: 'ซอฟต์แวร์',
      companyDescription: 'แพลตฟอร์มฝึกงาน',
    );
  }

  @override
  Future<void> save(String jobId) async {}

  @override
  Future<void> unsave(String jobId) async {}
}
