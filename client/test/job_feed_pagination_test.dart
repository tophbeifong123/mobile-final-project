import 'dart:convert';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/widgets/job_card.dart';
import 'package:client/features/jobs/data/datasources/job_remote_data_source.dart';
import 'package:client/features/jobs/domain/entities/company_logo.dart';
import 'package:client/features/jobs/domain/entities/job.dart';
import 'package:client/features/jobs/domain/repositories/job_repository.dart';
import 'package:client/features/jobs/presentation/providers/jobs_controller.dart';
import 'package:client/features/jobs/presentation/screens/job_feed_screen.dart';
import 'package:client/features/jobs/presentation/widgets/student_job_card.dart';
import 'package:client/features/saved_jobs/data/models/saved_job_model.dart';
import 'package:client/features/saved_jobs/data/datasources/saved_job_remote_data_source.dart';
import 'package:client/features/saved_jobs/domain/entities/saved_job.dart';
import 'package:client/features/saved_jobs/domain/repositories/saved_job_repository.dart';
import 'package:client/features/saved_jobs/presentation/providers/saved_jobs_controller.dart';
import 'package:client/features/saved_jobs/presentation/screens/saved_jobs_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Job job(int id, {bool logo = false}) => Job(
  id: '$id',
  title: 'Intern $id',
  companyName: 'Company',
  province: 'สงขลา',
  workMode: WorkMode.remote,
  category: 'IT',
  hasAllowance: false,
  status: JobStatus.open,
  createdAt: DateTime.now(),
  companyLogoAvailable: logo,
);

void main() {
  test(
    'API metadata, publication time and logo availability survive parsing',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      final json = {
        'id': '21',
        'title': 'Intern',
        'companyName': 'Company',
        'province': 'สงขลา',
        'workMode': 'remote',
        'category': 'IT',
        'hasAllowance': false,
        'status': 'open',
        'createdAt': '2026-10-01T12:00:00.000Z',
        'companyLogoAvailable': true,
      };
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.queryParameters['page'], 2);
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'items': [json],
                  'total': 21,
                  'totalPages': 2,
                  'page': 2,
                  'limit': 20,
                },
              ),
            );
          },
        ),
      );
      final page = await JobRemoteDataSource(
        dio,
      ).fetchFeed(const JobFilter(page: 2));
      expect(page.total, 21);
      expect(page.totalPages, 2);
      expect(page.page, 2);
      expect(page.items.single.createdAt, DateTime.utc(2026, 10, 1, 12));
      expect(page.items.single.companyLogoAvailable, true);
      final saved = SavedJobModel.fromJson(json).toEntity();
      expect(saved.createdAt, page.items.single.createdAt);
      expect(saved.companyLogoAvailable, true);
    },
  );

  test(
    'saved jobs load every page so counts and saved markers are complete',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      final requestedPages = <int>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final page = options.queryParameters['page'] as int;
            requestedPages.add(page);
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'items': [
                    {
                      'id': '$page',
                      'title': 'Intern',
                      'companyName': 'Company',
                      'province': 'สงขลา',
                      'workMode': 'remote',
                      'category': 'IT',
                      'hasAllowance': false,
                      'status': 'open',
                      'createdAt': '2026-10-01T12:00:00.000Z',
                      'companyLogoAvailable': true,
                    },
                  ],
                  'total': 2,
                  'totalPages': 2,
                  'page': page,
                  'limit': 1,
                },
              ),
            );
          },
        ),
      );
      final saved = await SavedJobRemoteDataSource(dio).fetchSaved();
      expect(requestedPages, [1, 2]);
      expect(saved.map((item) => item.id), ['1', '2']);
      expect(saved.every((item) => item.companyLogoAvailable), true);
    },
  );

  test('publication time uses calendar days, not a permanent new badge', () {
    expect(
      postedTimeLabel(DateTime(2026, 10, 6, 0), now: DateTime(2026, 10, 6, 23)),
      'วันนี้',
    );
    expect(
      postedTimeLabel(DateTime(2026, 10, 3, 23), now: DateTime(2026, 10, 6, 0)),
      '3 วันที่แล้ว',
    );
  });

  for (final width in [320.0, 390.0]) {
    testWidgets(
      'long card fields truncate without overflow at width $width and large text',
      (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final long = List.filled(20, 'ข้อความยาว').join();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1100),
                  textScaler: const TextScaler.linear(1.6),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: JobCard(
                    title: long,
                    companyName: long,
                    province: long,
                    details: [long, 'Online'],
                    createdAt: DateTime.now(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        for (final text in tester.widgetList<Text>(find.text(long))) {
          expect(text.overflow, TextOverflow.ellipsis);
          expect(text.maxLines, isNotNull);
        }
        expect(find.text('ไม่มีเบี้ยเลี้ยง'), findsOneWidget);
        expect(find.text('วันนี้'), findsOneWidget);
        expect(find.text('ใหม่'), findsNothing);
      },
    );
  }

  testWidgets(
    '21 jobs paginate using total; searching and filtering reset page; empty can clear; pull refresh reloads',
    (tester) async {
      final repository = _Repository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            jobRepositoryProvider.overrideWithValue(repository),
            savedJobRepositoryProvider.overrideWithValue(_Saved()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const JobFeedScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('พบ 21 ตำแหน่ง'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byTooltip('หน้าถัดไป'),
        500,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.text('หน้า 1 จาก 2 (แสดง 1-20 จาก 21 ตำแหน่ง)'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('หน้าถัดไป'));
      await tester.pumpAndSettle();
      expect(repository.filters.last.page, 2);
      expect(find.text('Intern 21'), findsOneWidget);
      expect(
        find.text('หน้า 2 จาก 2 (แสดง 21-21 จาก 21 ตำแหน่ง)'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton && widget.tooltip == 'หน้าถัดไป',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField).first, 'missing');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(repository.filters.last.page, 1);
      expect(find.text('ไม่พบงานที่ตรงกับตัวกรอง'), findsOneWidget);
      await tester.tap(find.text('ล้างตัวกรอง'));
      await tester.pumpAndSettle();
      expect(repository.filters.last.search, '');
      expect(find.text('พบ 21 ตำแหน่ง'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byTooltip('หน้าถัดไป'),
        500,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byTooltip('หน้าถัดไป'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Online'));
      await tester.pumpAndSettle();
      expect(repository.filters.last.page, 1);
      expect(repository.filters.last.workMode, WorkMode.remote);
      final calls = repository.filters.length;
      await tester.drag(find.byType(ListView).last, const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(repository.filters.length, greaterThan(calls));
    },
  );

  for (final saved in [false, true]) {
    testWidgets(
      'feed and Saved Jobs share logo-backed card data (saved=$saved)',
      (tester) async {
        final svg = utf8.encode(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><rect width="10" height="10"/></svg>',
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
              jobRepositoryProvider.overrideWithValue(_Repository(logo: true)),
              savedJobRepositoryProvider.overrideWithValue(_Saved(logo: true)),
              jobCardLogoProvider.overrideWith(
                (ref, id) async =>
                    CompanyLogo(bytes: svg, mimeType: 'image/svg+xml'),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: saved ? const SavedJobsScreen() : const JobFeedScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(StudentJobCard), findsWidgets);
        expect(find.bySemanticsLabel('โลโก้บริษัท Company'), findsWidgets);
        final card = tester.widget<JobCard>(find.byType(JobCard).first);
        expect(card.details, ['IT', 'Online']);
        expect(card.createdAt, isNotNull);
        expect(card.hasAllowance, false);
        expect(find.text('ใหม่'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _Repository implements JobRepository {
  _Repository({this.logo = false});
  final bool logo;
  final filters = <JobFilter>[];
  @override
  Future<JobPage> fetchFeed(JobFilter filter) async {
    filters.add(filter);
    if (filter.search == 'missing') return const JobPage();
    final all = List.generate(
      logo ? 1 : 21,
      (index) => job(index + 1, logo: logo),
    );
    return JobPage(
      items: all
          .skip((filter.page - 1) * filter.limit)
          .take(filter.limit)
          .toList(),
      total: all.length,
      totalPages: (all.length / filter.limit).ceil(),
      page: filter.page,
      limit: filter.limit,
    );
  }

  @override
  Future<JobDetail> fetchDetail(String jobId) => throw UnimplementedError();
  @override
  Future<void> save(String jobId) async {}
  @override
  Future<void> unsave(String jobId) async {}
}

class _Saved implements SavedJobRepository {
  _Saved({this.logo = false});
  final bool logo;
  @override
  Future<List<SavedJob>> fetchSaved() async => logo
      ? [
          SavedJob(
            id: '1',
            title: 'Intern 1',
            companyName: 'Company',
            province: 'สงขลา',
            workMode: WorkMode.remote,
            category: 'IT',
            hasAllowance: false,
            status: JobStatus.open,
            createdAt: DateTime.now(),
            companyLogoAvailable: true,
          ),
        ]
      : [];
}
