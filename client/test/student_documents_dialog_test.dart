import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/resume/domain/entities/resume_file.dart';
import 'package:client/features/resume/presentation/providers/resume_controller.dart';
import 'package:client/features/resume/presentation/screens/resume_upload_screen.dart';
import 'package:client/features/resume/presentation/widgets/student_documents_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'student_documents_test.dart' show DocumentsRepo, MemoryPdf;

void main() {
  Future<void> open(
    WidgetTester tester,
    DocumentsRepo repo,
    Future<PlatformFile?> Function() picker,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resumeRepositoryProvider.overrideWithValue(repo),
          documentPickerProvider.overrideWithValue(picker),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => StudentDocumentsDialog.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> upload(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  for (final entry in {
    'cv': 'CV',
    'transcript': 'Transcript',
    'other': 'เอกสารอื่นๆ',
  }.entries) {
    testWidgets(
      '${entry.key} stores chosen type and custom PDF name immediately',
      (tester) async {
        final repo = DocumentsRepo();
        if (entry.key != 'other') {
          repo.documents.add(
            StudentDocument(id: 'old', type: entry.key, fileName: 'old.pdf'),
          );
        }
        await open(tester, repo, () async => MemoryPdf('original.pdf'));
        await select(tester, entry.value);
        await tester.enterText(find.byType(TextFormField), 'เอกสารของฉัน');
        await upload(
          tester,
          entry.key == 'other' ? 'เลือก PDF' : 'เลือก PDF เพื่อแทนที่',
        );
        expect(repo.uploadCalls, 1);
        expect(repo.lastKind, entry.key);
        expect(repo.documents.single.fileName, 'เอกสารของฉัน.pdf');
        expect(find.text('อัปโหลดแล้ว: เอกสารของฉัน.pdf'), findsOneWidget);
        expect(find.text('บันทึก'), findsOneWidget);
        expect(find.text('เลือก PDF'), findsNothing);
        expect(find.text('เลือก PDF เพื่อแทนที่'), findsNothing);
        await upload(tester, 'บันทึก');
        expect(find.byType(StudentDocumentsDialog), findsNothing);
        expect(repo.uploadCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('missing or unsafe name never opens file picker', (tester) async {
    final repo = DocumentsRepo();
    var picks = 0;
    await open(tester, repo, () async {
      picks++;
      return MemoryPdf('file.pdf');
    });
    await upload(tester, 'เลือก PDF');
    expect(find.text('กรุณาระบุชื่อเอกสาร'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'folder/file');
    await upload(tester, 'เลือก PDF');
    expect(picks, 0);
    expect(repo.uploadCalls, 0);
  });

  testWidgets(
    'other documents at 3/3 are rejected; popup has no redundant management button',
    (tester) async {
      final repo = DocumentsRepo();
      repo.documents.addAll(
        List.generate(
          3,
          (i) => StudentDocument(id: '$i', type: 'other', fileName: '$i.pdf'),
        ),
      );
      var picks = 0;
      await open(tester, repo, () async {
        picks++;
        return null;
      });
      await select(tester, 'เอกสารอื่นๆ');
      await tester.enterText(find.byType(TextFormField), 'fourth');
      await upload(tester, 'เลือก PDF');
      expect(
        find.text('เอกสารอื่นๆ ครบ 3 ไฟล์แล้ว กรุณาลบหรือแทนที่ไฟล์เดิม'),
        findsOneWidget,
      );
      expect(picks, 0);
      expect(repo.documents.length, 3);
      expect(find.text('จัดการไฟล์ที่อัปโหลดแล้ว'), findsNothing);
    },
  );

  for (final file in [
    MemoryPdf('text.txt'),
    MemoryPdf('fake.pdf', content: 'invalid'),
    MemoryPdf('big.pdf', reportedSize: 10 * 1024 * 1024 + 1),
  ]) {
    testWidgets('popup rejects ${file.name} without creating a document', (
      tester,
    ) async {
      final repo = DocumentsRepo();
      await open(tester, repo, () async => file);
      await tester.enterText(find.byType(TextFormField), 'name');
      await upload(tester, 'เลือก PDF');
      expect(repo.uploadCalls, 0);
      expect(repo.documents, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'cancel and failed upload retain form; retry keeps a single pdf suffix',
    (tester) async {
      final repo = DocumentsRepo();
      PlatformFile? selection;
      await open(tester, repo, () async => selection);
      await tester.enterText(find.byType(TextFormField), 'name.pdf');
      await upload(tester, 'เลือก PDF');
      expect(repo.uploadCalls, 0);
      selection = MemoryPdf('original.pdf');
      repo.failUpload = true;
      await upload(tester, 'เลือก PDF');
      expect(find.text('อัปโหลดไม่สำเร็จ'), findsOneWidget);
      expect(repo.documents, isEmpty);
      repo.failUpload = false;
      await upload(tester, 'เลือก PDF');
      expect(repo.documents.single.fileName, 'name.pdf');
      await upload(tester, 'บันทึก');
      expect(find.byType(StudentDocumentsDialog), findsNothing);
    },
  );
}
