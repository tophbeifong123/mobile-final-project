import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/jobs/domain/entities/job.dart';
import 'package:client/features/saved_jobs/domain/entities/saved_job.dart';
import 'package:client/features/saved_jobs/domain/repositories/saved_job_repository.dart';
import 'package:client/features/saved_jobs/presentation/providers/saved_jobs_controller.dart';
import 'package:client/features/saved_jobs/presentation/screens/saved_jobs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('saved jobs lists only the jobs the student saved', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/student/saved',
      routes: [
        GoRoute(
          path: '/student/saved',
          builder: (context, state) => const SavedJobsScreen(),
        ),
        GoRoute(
          path: '/student/jobs/:jobId',
          builder: (context, state) => const Scaffold(body: Text('รายละเอียด')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          savedJobRepositoryProvider.overrideWithValue(_SavedRepository()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flutter Intern'), findsOneWidget);
    expect(find.text('InternFinder'), findsOneWidget);
    expect(find.text('งานที่ปิดแล้ว'), findsNothing);

    await tester.tap(find.text('Flutter Intern'));
    await tester.pumpAndSettle();
    expect(find.text('รายละเอียด'), findsOneWidget);
  });
}

class _SavedRepository implements SavedJobRepository {
  @override
  Future<List<SavedJob>> fetchSaved() async {
    return const [
      SavedJob(
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
}
