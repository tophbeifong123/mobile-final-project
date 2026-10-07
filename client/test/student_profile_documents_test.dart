import 'dart:async';
import 'package:client/core/error/app_exception.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/resume/domain/entities/resume_file.dart';
import 'package:client/features/resume/presentation/providers/resume_controller.dart';
import 'package:client/features/resume/presentation/screens/resume_upload_screen.dart';
import 'package:client/features/resume/presentation/widgets/student_documents_dialog.dart';
import 'package:client/features/student_profile/presentation/widgets/student_profile_resume_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'student_documents_test.dart' show DocumentsRepo, MemoryPdf;

void main() {
  Future<void> open(
    WidgetTester tester,
    DocumentsRepo repo, {
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resumeRepositoryProvider.overrideWithValue(repo),
          documentPickerProvider.overrideWithValue(
            () async => MemoryPdf('replacement.pdf'),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: StudentProfileResumeCard(resumeFileName: 'stale.pdf'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets(
      'all document types have visible edit/delete actions at $width',
      (tester) async {
        final repo = DocumentsRepo();
        repo.documents.addAll([
          const StudentDocument(id: 'cv', type: 'cv', fileName: 'CV.pdf'),
          const StudentDocument(
            id: 'transcript',
            type: 'transcript',
            fileName: 'grades.pdf',
          ),
          StudentDocument(
            id: 'other',
            type: 'other',
            fileName: '${'long-name-' * 20}.pdf',
          ),
        ]);
        await open(tester, repo, width: width);
        expect(find.text('CV'), findsOneWidget);
        expect(find.text('Transcript'), findsOneWidget);
        expect(find.text('เอกสารอื่นๆ'), findsOneWidget);
        for (final document in repo.documents) {
          final view = find.byWidgetPredicate(
            (w) =>
                w is IconButton && w.tooltip == 'เปิดดู ${document.fileName}',
          );
          final edit = find.byTooltip('แก้ไข ${document.fileName}');
          final delete = find.byTooltip('ลบ ${document.fileName}');
          expect(tester.getSize(view), const Size(31, 44));
          expect(tester.getCenter(view).dy, tester.getCenter(edit).dy);
          expect(tester.getCenter(edit).dy, tester.getCenter(delete).dy);
          expect(tester.getCenter(edit).dx - tester.getCenter(view).dx, 31);
          expect(tester.getCenter(delete).dx - tester.getCenter(edit).dx, 31);
          expect(
            tester.getCenter(view).dx,
            lessThan(tester.getCenter(edit).dx),
          );
          expect(tester.widget<IconButton>(view).onPressed, isNotNull);
          expect(find.byTooltip('แก้ไข ${document.fileName}'), findsOneWidget);
          expect(find.byTooltip('ลบ ${document.fileName}'), findsOneWidget);
        }
        expect(find.text('stale.pdf'), findsNothing);
        expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(3));
        for (final icon in tester.widgetList<Icon>(
          find.byIcon(Icons.visibility_outlined),
        )) {
          expect(icon.color, const Color(0xFF18181B));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final type in ['cv', 'transcript', 'other']) {
    testWidgets('edit $type name without choosing a new PDF', (tester) async {
      final repo = DocumentsRepo();
      repo.documents.add(
        StudentDocument(id: 'old', type: type, fileName: 'old.pdf'),
      );
      if (type == 'other') {
        repo.documents.addAll(
          List.generate(
            2,
            (i) => StudentDocument(
              id: 'extra$i',
              type: 'other',
              fileName: 'extra$i.pdf',
            ),
          ),
        );
      }
      await open(tester, repo);
      await tester.tap(find.byTooltip('แก้ไข old.pdf'));
      await tester.pumpAndSettle();
      expect(find.text('แก้ไขเอกสาร'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'old',
      );
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .onChanged,
        isNull,
      );
      await tester.enterText(find.byType(TextFormField), 'new-title');
      await tester.ensureVisible(find.text('บันทึกชื่อเอกสาร'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('บันทึกชื่อเอกสาร'));
      await tester.pumpAndSettle();
      expect(repo.openedId, 'old');
      expect(repo.lastKind, type);
      expect(repo.replacingId, type == 'other' ? 'old' : null);
      expect(repo.documents.length, type == 'other' ? 3 : 1);
      expect(find.byType(StudentDocumentsDialog), findsNothing);
      expect(find.text('new-title.pdf'), findsOneWidget);
      expect(find.text('old.pdf'), findsNothing);
    });
  }

  testWidgets(
    'edit can replace existing other PDF at 3/3 without adding a fourth',
    (tester) async {
      final repo = DocumentsRepo();
      repo.documents.addAll(
        List.generate(
          3,
          (i) => StudentDocument(id: '$i', type: 'other', fileName: '$i.pdf'),
        ),
      );
      await open(tester, repo);
      await tester.tap(find.byTooltip('แก้ไข 0.pdf'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('เลือก PDF เพื่อแทนที่'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เลือก PDF เพื่อแทนที่'));
      await tester.pumpAndSettle();
      expect(repo.replacingId, '0');
      expect(repo.documents.length, 3);
      expect(find.text('บันทึก'), findsOneWidget);
      await tester.ensureVisible(find.text('บันทึก'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();
      expect(find.byType(StudentDocumentsDialog), findsNothing);
    },
  );

  testWidgets(
    'delete needs confirmation, waits for request, then removes stale CV',
    (tester) async {
      final repo = _DeleteRepo()..wait = Completer<void>();
      repo.documents.add(
        const StudentDocument(id: 'cv', type: 'cv', fileName: 'cv.pdf'),
      );
      await open(tester, repo);
      await tester.tap(find.byTooltip('ลบ cv.pdf'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();
      expect(repo.deleted, isEmpty);
      await tester.tap(find.byTooltip('ลบ cv.pdf'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ลบ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final edit = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'แก้ไข cv.pdf',
      );
      expect(tester.widget<IconButton>(edit).onPressed, isNull);
      repo.wait!.complete();
      await tester.pumpAndSettle();
      expect(repo.deleted, ['cv']);
      expect(find.text('cv.pdf'), findsNothing);
      expect(find.text('stale.pdf'), findsNothing);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
      expect(find.text('ยังไม่มี CV ในระบบ'), findsOneWidget);
    },
  );

  testWidgets('delete failure keeps document visible and allows retry', (
    tester,
  ) async {
    final repo = _DeleteRepo()..fail = true;
    repo.documents.add(
      const StudentDocument(id: 'cv', type: 'cv', fileName: 'cv.pdf'),
    );
    await open(tester, repo);
    await tester.tap(find.byTooltip('ลบ cv.pdf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ'));
    await tester.pumpAndSettle();
    expect(find.text('ลบไม่สำเร็จ'), findsOneWidget);
    expect(find.text('cv.pdf'), findsOneWidget);
    expect(repo.deleted, isEmpty);
  });
}

class _DeleteRepo extends DocumentsRepo {
  bool fail = false;
  Completer<void>? wait;
  @override
  Future<void> deleteDocument(String id) async {
    await wait?.future;
    if (fail) throw const AppException('ลบไม่สำเร็จ');
    await super.deleteDocument(id);
  }
}
