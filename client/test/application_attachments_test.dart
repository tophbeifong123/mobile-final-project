import 'dart:async';
import 'package:client/core/error/app_exception.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/widgets/neo_button.dart';
import 'package:client/core/widgets/app_card.dart';
import 'package:client/core/theme/app_tokens.dart';
import 'package:client/features/applications/domain/entities/job_application.dart';
import 'package:client/features/applications/domain/repositories/application_repository.dart';
import 'package:client/features/applications/data/models/job_application_model.dart';
import 'package:client/features/applications/presentation/providers/applications_controller.dart';
import 'package:client/features/applications/presentation/screens/apply_job_screen.dart';
import 'package:client/features/applications/presentation/screens/application_detail_screen.dart';
import 'package:client/features/resume/domain/entities/resume_file.dart';
import 'package:client/features/resume/presentation/providers/resume_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const library = [
  StudentDocument(id: 'cv', type: 'cv', fileName: 'CV.pdf'),
  StudentDocument(
    id: 'transcript',
    type: 'transcript',
    fileName: 'Transcript.pdf',
  ),
  StudentDocument(id: 'other1', type: 'other', fileName: 'Certificate.pdf'),
  StudentDocument(id: 'other2', type: 'other', fileName: 'Portfolio.pdf'),
  StudentDocument(id: 'other3', type: 'other', fileName: 'Award.pdf'),
];

class _Repo implements ApplicationRepository {
  List<String>? ids;
  bool fail = false;
  @override
  Future<JobApplication> apply({
    required String jobId,
    required String coverLetter,
    List<String> documentIds = const [],
  }) async {
    ids = List.of(documentIds);
    if (fail) throw const AppException('เอกสารที่เลือกถูกลบ กรุณาเลือกใหม่');
    return const JobApplication(
      id: 'application',
      jobTitle: 'Intern',
      companyName: 'Company',
      status: ApplicationStatus.submitted,
      coverLetter: 'Hello',
    );
  }

  @override
  Future<List<JobApplication>> fetchMine() async => [];
  @override
  Future<JobApplication> fetchDetail(String id) async =>
      throw UnimplementedError();

  @override
  Future<void> completeExam(String applicationId) async =>
      throw UnimplementedError();
}

void main() {
  Future<void> open(
    WidgetTester tester,
    _Repo repo, {
    Future<List<StudentDocument>> Function()? load,
  }) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/apply',
      routes: [
        GoRoute(
          path: '/apply',
          builder: (_, _) => const ApplyJobScreen(jobId: 'job'),
        ),
        GoRoute(
          path: '/student/applications',
          builder: (_, _) => const Scaffold(body: Text('Applications')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          studentDocumentsProvider.overrideWith(
            (ref) => load == null ? Future.value(library) : load(),
          ),
          applicationRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'CV is mandatory; four optional files start unchecked; submit attaches CV only',
    (tester) async {
      final repo = _Repo();
      await open(tester, repo);
      await tester.tap(find.text('เลือกเอกสาร'));
      await tester.pumpAndSettle();
      expect(find.text('CV (จำเป็น)'), findsOneWidget);
      expect(
        tester
            .widget<Checkbox>(find.byKey(const ValueKey('attach-cv')))
            .onChanged,
        isNull,
      );
      expect(
        tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .where((w) => w.onChanged != null)
            .every((w) => w.value == false),
        isTrue,
      );
      await tester.tap(find.text('ใช้เอกสารที่เลือก'));
      await tester.pumpAndSettle();
      expect(find.text('เอกสารที่เลือกแนบ'), findsOneWidget);
      for (final id in ['cv']) {
        final card = tester.widget<AppCard>(
          find.byKey(ValueKey('selected-document-$id')),
        );
        expect(card.borderColor, NeoColors.inkSolid);
        expect(card.borderWidth, 2);
        expect(card.backgroundColor, NeoColors.paperCanvas);
      }
      expect(
        find.byKey(const ValueKey('selected-document-other2')),
        findsNothing,
      );
      await tester.enterText(find.byType(TextFormField), 'Hello');
      await tester.tap(find.text('ยืนยันสมัคร'));
      await tester.pumpAndSettle();
      expect(repo.ids, ['cv']);
      expect(find.text('Applications'), findsOneWidget);
    },
  );

  testWidgets(
    'optional selection and deselection sends exactly the final set',
    (tester) async {
      final repo = _Repo();
      await open(tester, repo);
      await tester.tap(find.text('เลือกเอกสาร'));
      await tester.pumpAndSettle();
      for (final id in ['transcript', 'other1', 'other2', 'other2']) {
        await tester.tap(find.byKey(ValueKey('attach-$id')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('ใช้เอกสารที่เลือก'));
      await tester.pumpAndSettle();
      for (final id in ['cv', 'transcript', 'other1']) {
        final card = tester.widget<AppCard>(
          find.byKey(ValueKey('selected-document-$id')),
        );
        expect(card.borderColor, NeoColors.inkSolid);
        expect(card.borderWidth, 2);
        expect(card.backgroundColor, NeoColors.paperCanvas);
      }
      expect(
        find.byKey(const ValueKey('selected-document-other2')),
        findsNothing,
      );
      await tester.enterText(find.byType(TextFormField), 'Hello');
      await tester.tap(find.text('ยืนยันสมัคร'));
      await tester.pumpAndSettle();
      expect(repo.ids, ['cv', 'transcript', 'other1']);
    },
  );

  testWidgets(
    'missing CV blocks submission despite optional files being available',
    (tester) async {
      final repo = _Repo();
      await open(tester, repo, load: () async => library.sublist(1));
      expect(
        tester
            .widget<NeoButton>(find.widgetWithText(NeoButton, 'ยืนยันสมัคร'))
            .onPressed,
        isNull,
      );
      expect(repo.ids, isNull);
    },
  );

  testWidgets('failed document loading has retry and cannot submit', (
    tester,
  ) async {
    final repo = _Repo();
    var calls = 0;
    await open(
      tester,
      repo,
      load: () async {
        calls++;
        if (calls == 1) throw const AppException('โหลดไม่สำเร็จ');
        return library;
      },
    );
    expect(
      tester
          .widget<NeoButton>(find.widgetWithText(NeoButton, 'ยืนยันสมัคร'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();
    expect(find.text('CV.pdf'), findsOneWidget);
  });

  testWidgets(
    'server rejects stale document selection without navigation or clearing form',
    (tester) async {
      final repo = _Repo()..fail = true;
      await open(tester, repo);
      await tester.tap(find.text('เลือกเอกสาร'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('attach-transcript')));
      await tester.tap(find.text('ใช้เอกสารที่เลือก'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Hello');
      await tester.tap(find.text('ยืนยันสมัคร'));
      await tester.pumpAndSettle();
      expect(find.text('Applications'), findsNothing);
      await tester.ensureVisible(
        find.text('เอกสารที่เลือกถูกลบ กรุณาเลือกใหม่'),
      );
      expect(find.text('เอกสารที่เลือกถูกลบ กรุณาเลือกใหม่'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'Hello',
      );
    },
  );

  test('snapshot metadata survives response parsing', () {
    final app = JobApplicationModel.fromJson({
      'id': 'app',
      'status': 'submitted',
      'documents': [
        {
          'id': 'snapshot',
          'type': 'transcript',
          'fileName': 'old-transcript.pdf',
        },
      ],
    }).toEntity();
    expect(app.documents.single.id, 'snapshot');
    expect(app.documents.single.fileName, 'old-transcript.pdf');
  });

  testWidgets(
    'student opens the attached snapshot, not the current document library',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const app = JobApplication(
        id: 'app',
        jobTitle: 'Intern',
        companyName: 'Company',
        status: ApplicationStatus.submitted,
        coverLetter: 'Hello',
        documents: [
          AttachedDocument(
            id: 'snapshot',
            type: 'transcript',
            fileName: 'original.pdf',
          ),
        ],
      );
      final request = Completer<List<int>>();
      String? requested;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            applicationDetailProvider('app').overrideWith((ref) async => app),
            applicationDocumentPdfProvider.overrideWith((ref, key) {
              requested = '${key.applicationId}/${key.documentId}';
              return request.future;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ApplicationDetailScreen(applicationId: 'app'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('เปิดดู original.pdf'));
      await tester.pumpAndSettle();
      for (final key in [
        'attached-documents-container',
        'attached-document-snapshot',
      ]) {
        final card = tester.widget<AppCard>(find.byKey(ValueKey(key)));
        expect(card.borderColor, NeoColors.inkSolid);
        expect(card.borderWidth, 2);
        expect(card.shadows, isNotEmpty);
      }
      await tester.tap(find.byTooltip('เปิดดู original.pdf'));
      await tester.pump();
      expect(requested, 'app/snapshot');
      request.completeError(const AppException('เปิดไฟล์ไม่สำเร็จ'));
      await tester.pumpAndSettle();
      expect(find.text('เปิดไฟล์ไม่สำเร็จ'), findsWidgets);
      await tester.tap(find.text('ปิด'));
      await tester.pumpAndSettle();
      expect(find.byType(ApplicationDetailScreen), findsOneWidget);
    },
  );
}
