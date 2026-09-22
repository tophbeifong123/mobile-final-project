import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/jobs/domain/entities/job.dart';
import 'package:client/features/jobs/domain/repositories/job_repository.dart';
import 'package:client/features/jobs/presentation/providers/jobs_controller.dart';
import 'package:client/features/jobs/presentation/screens/job_feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'home lists an open job and hides jobs the feed does not return',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            jobRepositoryProvider.overrideWithValue(_OpenJobRepository()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const JobFeedScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

    expect(find.text('Flutter Intern'), findsOneWidget);
    expect(find.text('InternFinder'), findsNWidgets(2));
    expect(find.text('งานที่ปิดแล้ว'), findsNothing);
    expect(find.text('On-site'), findsOneWidget);
    },
  );
}

class _OpenJobRepository implements JobRepository {
  @override
  Future<List<Job>> fetchFeed(JobFilter filter) async {
    return const [
      Job(
        id: 'job-1',
        title: 'Flutter Intern',
        companyName: 'InternFinder',
        province: 'สงขลา',
        workMode: WorkMode.onSite,
        category: 'IT',
        hasAllowance: true,
        status: JobStatus.open,
      ),
    ];
  }

  @override
  Future<JobDetail> fetchDetail(String jobId) => throw UnimplementedError();

  @override
  Future<void> save(String jobId) async {}

  @override
  Future<void> unsave(String jobId) async {}
}
