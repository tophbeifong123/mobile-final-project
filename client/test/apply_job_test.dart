import 'dart:async';

import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/theme/app_tokens.dart';
import 'package:client/core/widgets/app_card.dart';
import 'package:client/core/widgets/neo_button.dart';
import 'package:client/features/applications/domain/entities/job_application.dart';
import 'package:client/features/applications/domain/repositories/application_repository.dart';
import 'package:client/features/applications/presentation/providers/applications_controller.dart';
import 'package:client/features/applications/presentation/screens/apply_job_screen.dart';
import 'package:client/features/jobs/domain/entities/job.dart';
import 'package:client/features/jobs/domain/repositories/job_repository.dart';
import 'package:client/features/jobs/presentation/providers/jobs_controller.dart';
import 'package:client/features/resume/domain/entities/resume_file.dart';
import 'package:client/features/resume/presentation/providers/resume_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  const sampleJob = JobDetail(
    id: 'job-123',
    title: 'Flutter Developer Intern',
    companyName: 'Tech Co',
    province: 'กรุงเทพมหานคร',
    workMode: WorkMode.onSite,
    category: 'Software Engineering',
    hasAllowance: true,
    description: 'พัฒนาแอปมือถือ',
    requirements: 'ใช้ Flutter ได้',
    status: JobStatus.open,
    businessType: 'Tech',
    companyDescription: 'Software house',
    saved: false,
  );

  const cvDocument = StudentDocument(
    id: 'cv-123',
    type: 'cv',
    fileName: 'my_resume.pdf',
  );

  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets(
      'shows themed application screen and submits at width $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final appRepository = _FakeApplicationRepository();

        await _mount(
          tester,
          documents: const [cvDocument],
          appRepository: appRepository,
        );

        expect(find.text('Flutter Developer Intern'), findsOneWidget);
        expect(find.text('Tech Co'), findsOneWidget);
        expect(find.text('เอกสารที่เลือกแนบ'), findsOneWidget);
        expect(find.text('my_resume.pdf'), findsOneWidget);

        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          NeoColors.paperCanvas,
        );

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, NeoColors.paperCanvas);
        expect(appBar.foregroundColor, NeoColors.inkSolid);

        for (final card in tester.widgetList<AppCard>(find.byType(AppCard))) {
          expect(card.borderColor, NeoColors.inkSolid);
          expect(card.borderWidth, 2);
          expect(card.shadows, isNotEmpty);
        }

        final field = tester.widget<TextFormField>(find.byType(TextFormField));
        expect(field.enabled, isTrue);

        final submitButton = tester.widget<NeoButton>(
          find.byKey(const Key('apply-submit')),
        );
        expect(submitButton.onPressed, isNotNull);

        await tester.enterText(
          find.byKey(const Key('apply-cover-letter')),
          'สนใจฝึกงานกับ Tech Co',
        );
        await tester.tap(find.byKey(const Key('apply-submit')));
        await tester.pumpAndSettle();

        expect(appRepository.applyCalls, 1);
        expect(appRepository.appliedJobId, 'job-123');
        expect(appRepository.appliedCoverLetter, 'สนใจฝึกงานกับ Tech Co');
        expect(appRepository.appliedDocumentIds, const ['cv-123']);
        expect(find.text('Submitted'), findsOneWidget);
      },
    );
  }

  testWidgets('without a CV, submit is disabled and upload route works', (
    tester,
  ) async {
    final appRepository = _FakeApplicationRepository();

    await _mount(
      tester,
      documents: const [],
      appRepository: appRepository,
    );

    expect(find.text('ยังไม่มี CV ในระบบ'), findsOneWidget);

    final submit = tester.widget<NeoButton>(
      find.byKey(const Key('apply-submit')),
    );
    expect(submit.onPressed, isNull);

    await tester.tap(find.byKey(const Key('apply-upload-cv')));
    await tester.pumpAndSettle();

    expect(find.text('อัปโหลด Resume'), findsOneWidget);
    expect(appRepository.applyCalls, 0);
  });

  testWidgets('empty or whitespace Cover Letter does not call apply', (
    tester,
  ) async {
    final appRepository = _FakeApplicationRepository();

    await _mount(
      tester,
      documents: const [cvDocument],
      appRepository: appRepository,
    );

    await tester.enterText(
      find.byKey(const Key('apply-cover-letter')),
      '  \n  ',
    );
    await tester.tap(find.byKey(const Key('apply-submit')));
    await tester.pumpAndSettle();

    expect(find.text('กรอก Cover Letter'), findsOneWidget);
    expect(appRepository.applyCalls, 0);
  });

  testWidgets('shows loading and ignores repeat taps while submitting', (
    tester,
  ) async {
    final appRepository = _FakeApplicationRepository()..pending = Completer();

    await _mount(
      tester,
      documents: const [cvDocument],
      appRepository: appRepository,
    );

    await tester.enterText(
      find.byKey(const Key('apply-cover-letter')),
      'จดหมายสมัครงาน',
    );
    await tester.tap(find.byKey(const Key('apply-submit')));
    await tester.pump();

    expect(find.text('กำลังส่งใบสมัคร'), findsOneWidget);

    await tester.tap(find.byKey(const Key('apply-submit')));
    await tester.pump();

    expect(appRepository.applyCalls, 1);

    appRepository.pending!.complete(_submitted('จดหมายสมัครงาน'));
    await tester.pumpAndSettle();

    expect(appRepository.applyCalls, 1);
  });

  testWidgets('submission error stays in the form card and preserves text', (
    tester,
  ) async {
    final appRepository = _FakeApplicationRepository()
      ..failure = const AppException('สมัครงานนี้แล้ว');

    await _mount(
      tester,
      documents: const [cvDocument],
      appRepository: appRepository,
    );

    await tester.enterText(
      find.byKey(const Key('apply-cover-letter')),
      'ข้อความที่ต้องเก็บไว้',
    );
    await tester.tap(find.byKey(const Key('apply-submit')));
    await tester.pumpAndSettle();

    expect(find.text('สมัครงานนี้แล้ว'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const Key('apply-submit-error')),
        matching: find.byKey(const Key('apply-form-card')),
      ),
      findsOneWidget,
    );
    expect(find.text('ข้อความที่ต้องเก็บไว้'), findsOneWidget);
    expect(appRepository.applyCalls, 1);
    expect(find.text('ยืนยันสมัคร'), findsOneWidget);
  });

  testWidgets('selected additional documents are displayed and submitted', (
    tester,
  ) async {
    final appRepository = _FakeApplicationRepository();

    await _mount(
      tester,
      documents: const [
        cvDocument,
        StudentDocument(
          id: 'portfolio-456',
          type: 'portfolio',
          fileName: 'portfolio.pdf',
        ),
      ],
      appRepository: appRepository,
      documentIds: const ['portfolio-456'],
    );

    expect(find.text('my_resume.pdf'), findsOneWidget);
    expect(find.text('portfolio.pdf'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('apply-cover-letter')),
      'สนใจตำแหน่งนี้',
    );
    await tester.tap(find.byKey(const Key('apply-submit')));
    await tester.pumpAndSettle();

    expect(
      appRepository.appliedDocumentIds,
      const ['cv-123', 'portfolio-456'],
    );
  });

  testWidgets('narrow screen and long job details do not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _mount(
      tester,
      documents: const [],
      appRepository: _FakeApplicationRepository(),
      job: const JobDetail(
        id: 'job-123',
        title:
            'งานนักพัฒนา Flutter สำหรับระบบภายในองค์กรและแพลตฟอร์มมือถือหลายรูปแบบ',
        companyName:
            'บริษัทเทคโนโลยีที่มีชื่อยาวมากสำหรับทดสอบการจัดวางบนโทรศัพท์',
        province: 'กรุงเทพมหานคร',
        workMode: WorkMode.onSite,
        category: 'Software Engineering',
        hasAllowance: true,
        description: 'พัฒนาแอปมือถือ',
        requirements: 'ใช้ Flutter ได้',
        status: JobStatus.open,
        businessType: 'Tech',
        companyDescription: 'Software house',
        saved: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Future<void> _mount(
  WidgetTester tester, {
  required List<StudentDocument> documents,
  required _FakeApplicationRepository appRepository,
  List<String> documentIds = const [],
  JobDetail job = sampleJob,
}) async {
  final router = GoRouter(
    initialLocation: '/student/jobs/job-123/apply',
    routes: [
      GoRoute(
        path: '/student/jobs/:jobId/apply',
        builder: (context, state) => ApplyJobScreen(
          jobId: state.pathParameters['jobId']!,
          documentIds: documentIds,
        ),
      ),
      GoRoute(
        path: '/student/resume',
        builder: (_, __) => const Scaffold(body: Text('อัปโหลด Resume')),
      ),
      GoRoute(
        path: '/student/applications',
        builder: (_, __) => const Scaffold(body: Text('Submitted')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
        studentDocumentsProvider.overrideWith((ref) async => documents),
        jobRepositoryProvider.overrideWithValue(_FakeJobRepository(job)),
        applicationRepositoryProvider.overrideWithValue(appRepository),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

JobApplication _submitted(String coverLetter) => JobApplication(
  id: 'app-999',
  jobTitle: 'Flutter Developer Intern',
  companyName: 'Tech Co',
  status: ApplicationStatus.submitted,
  coverLetter: coverLetter,
);

class _FakeJobRepository implements JobRepository {
  _FakeJobRepository(this.job);

  final JobDetail job;

  @override
  Future<JobPage> fetchFeed(JobFilter filter) async => const JobPage();

  @override
  Future<JobDetail> fetchDetail(String jobId) async => job;

  @override
  Future<void> save(String jobId) async {}

  @override
  Future<void> unsave(String jobId) async {}
}

class _FakeApplicationRepository implements ApplicationRepository {
  String? appliedJobId;
  String? appliedCoverLetter;
  List<String> appliedDocumentIds = [];
  int applyCalls = 0;
  Completer<JobApplication>? pending;
  Object? failure;

  @override
  Future<List<JobApplication>> fetchMine() async => [];

  @override
  Future<JobApplication> fetchDetail(String applicationId) async =>
      throw UnimplementedError();

  @override
  Future<JobApplication> apply({
    required String jobId,
    required String coverLetter,
    List<String> documentIds = const [],
  }) async {
    applyCalls++;
    appliedJobId = jobId;
    appliedCoverLetter = coverLetter;
    appliedDocumentIds = documentIds;

    if (failure != null) throw failure!;
    if (pending != null) return pending!.future;

    return _submitted(coverLetter);
  }

  @override
  Future<void> completeExam(String applicationId) async {}
}