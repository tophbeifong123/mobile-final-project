import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/jobs/data/models/job_model.dart';
import 'package:client/features/jobs/presentation/job_labels.dart';
import 'package:client/features/jobs/presentation/providers/jobs_controller.dart';
import 'package:client/features/jobs/presentation/screens/job_feed_screen.dart';
import 'package:client/features/jobs/presentation/screens/job_detail_screen.dart';
import 'package:client/features/saved_jobs/data/models/saved_job_model.dart';
import 'package:client/features/saved_jobs/presentation/providers/saved_jobs_controller.dart';
import 'package:client/features/saved_jobs/presentation/screens/saved_jobs_screen.dart';
import 'package:client/features/company_jobs/data/models/company_job_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> payload({bool numbers = true, bool paid = true}) => {
  'id': 'job-1',
  'title': 'Intern',
  'companyName': 'Company',
  'province': 'สงขลา',
  'workMode': 'remote',
  'category': 'IT',
  'hasAllowance': paid,
  'status': 'open',
  'description': 'Description',
  'requirements': 'None',
  'version': 1,
  'saved': true,
  if (numbers) ...{'openings': 3, 'allowanceAmount': 8000.25},
};

void main() {
  test(
    'feed, saved, detail and company edit preserve the same real numbers',
    () {
      final json = payload();
      final feed = JobModel.fromJson(json).toEntity();
      final saved = SavedJobModel.fromJson(json).toEntity();
      final detail = JobDetailModel.fromJson(json).toEntity();
      final edit = EditableJobModel.fromJson(json).toEntity();
      expect(
        [feed.openings, saved.openings, detail.openings, edit.openings],
        [3, 3, 3, 3],
      );
      expect(
        [
          feed.allowanceAmount,
          saved.allowanceAmount,
          detail.allowanceAmount,
          edit.allowanceAmount,
        ],
        [8000.25, 8000.25, 8000.25, 8000.25],
      );
      final legacy = JobModel.fromJson(payload(numbers: false)).toEntity();
      expect(legacy.openings, isNull);
      expect(legacy.allowanceAmount, isNull);
    },
  );
  test('allowance labels show only known money and retain yes/no fallback', () {
    expect(allowanceLabel(true, 8000), '8,000 บาท');
    expect(allowanceLabel(true, 8000.25), '8,000.25 บาท');
    expect(allowanceLabel(true, 0), '0 บาท');
    expect(allowanceLabel(true), 'มีเบี้ยเลี้ยง');
    expect(allowanceLabel(false, 8000), 'ไม่มีเบี้ยเลี้ยง');
  });
  for (final saved in [false, true]) {
    for (final numbers in [false, true]) {
      testWidgets(
        'card real optional values (saved=$saved, numbers=$numbers)',
        (tester) async {
          final json = payload(numbers: numbers);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
                jobFeedProvider.overrideWith(
                  (ref) async => [JobModel.fromJson(json).toEntity()],
                ),
                savedJobsProvider.overrideWith(
                  (ref) async =>
                      saved ? [SavedJobModel.fromJson(json).toEntity()] : [],
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: saved ? const SavedJobsScreen() : const JobFeedScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text('รับ 3 คน'),
            numbers ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('8,000.25 บาท'),
            numbers ? findsWidgets : findsNothing,
          );
          if (!numbers) expect(find.text('มีเบี้ยเลี้ยง'), findsWidgets);
          expect(find.text('รับ 0 คน'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('detail shows the same openings and allowance amount', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          jobDetailProvider('job-1').overrideWith(
            (ref) async => JobDetailModel.fromJson(payload()).toEntity(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const JobDetailScreen(jobId: 'job-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('จำนวนรับ'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('รับ 3 คน'), findsOneWidget);
    expect(find.text('8,000.25 บาท'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
