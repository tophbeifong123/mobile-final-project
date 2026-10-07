import 'dart:async';
import 'dart:typed_data';
import 'package:client/core/error/app_exception.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/widgets/neo_button.dart';
import 'package:client/features/resume/domain/entities/resume_file.dart';
import 'package:client/features/resume/domain/repositories/resume_repository.dart';
import 'package:client/features/resume/presentation/providers/resume_controller.dart';
import 'package:client/features/resume/presentation/screens/resume_upload_screen.dart';
import 'package:client/features/resume/presentation/widgets/student_documents_dialog.dart';
import 'package:client/features/student_profile/presentation/widgets/student_profile_resume_card.dart';
import 'package:client/features/student_profile/presentation/widgets/resume_preview_modal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    DocumentsRepo repo,
    Future<PlatformFile?> Function() picker,
  ) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resumeRepositoryProvider.overrideWithValue(repo),
          documentPickerProvider.overrideWithValue(picker),
          resumePdfDocumentLoaderProvider.overrideWithValue(
            (_) async => throw const AppException('เปิด PDF ไม่สำเร็จ'),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ResumeUploadScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 390.0]) {
    testWidgets(
      'profile opens document popup, uploads immediately, and closes at $width px',
      (tester) async {
        final repo = DocumentsRepo()..uploadWait = Completer<void>();
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              resumeRepositoryProvider.overrideWithValue(repo),
              documentPickerProvider.overrideWithValue(
                () async => MemoryPdf('my-cv.pdf'),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(16),
                  child: StudentProfileResumeCard(resumeFileName: null),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('+ เพิ่ม'));
        await tester.pumpAndSettle();
        expect(find.byType(StudentDocumentsDialog), findsOneWidget);
        final popupSize = tester.getSize(
          find.byKey(const ValueKey('document-dialog-border-inset')),
        );
        expect(popupSize.width, lessThanOrEqualTo(320));
        expect(popupSize.height, lessThanOrEqualTo(410));
        final borderInset = tester.widget<Padding>(
          find.byKey(const ValueKey('document-dialog-border-inset')),
        );
        expect(borderInset.padding, const EdgeInsets.all(2));
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('document-dialog-border-inset')),
            matching: find.byType(ClipRRect),
          ),
          findsOneWidget,
        );
        expect(find.text('ประเภทเอกสาร'), findsOneWidget);
        expect(find.text('ชื่อเอกสาร *'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byType(TextFormField), 'my-cv');
        await tester.ensureVisible(find.text('เลือก PDF'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('เลือก PDF'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(repo.uploadCalls, 1);
        expect(
          tester.widget<NeoButton>(find.byType(NeoButton).last).isLoading,
          isTrue,
        );
        final close = find.byWidgetPredicate(
          (widget) =>
              widget is IconButton && widget.tooltip == 'ปิดหน้าต่างเอกสาร',
        );
        expect(tester.widget<IconButton>(close).onPressed, isNull);
        repo.uploadWait!.complete();
        await tester.pumpAndSettle();
        expect(
          tester.widget<NeoButton>(find.byType(NeoButton).last).isLoading,
          isFalse,
        );
        expect(find.text('my-cv.pdf'), findsWidgets);
        expect(find.text('บันทึก'), findsOneWidget);
        await tester.ensureVisible(find.text('บันทึก'));
        await tester.pumpAndSettle();
        expect(tester.widget<IconButton>(close).onPressed, isNotNull);
        await tester.tap(find.text('บันทึก'));
        await tester.pumpAndSettle();
        expect(find.byType(StudentDocumentsDialog), findsNothing);
        expect(find.text('my-cv.pdf'), findsOneWidget);
        expect(repo.uploadCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  // Layout regressions cover empty controls and long names across viewports.
  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets('document list remains compact and bounded at $width px', (
      tester,
    ) async {
      final repo = DocumentsRepo();
      await open(tester, repo, () async => null);
      tester.view.physicalSize = Size(width, 1100);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('เพิ่ม CV'), findsOneWidget);
      repo.documents.addAll([
        StudentDocument(
          id: 'cv',
          type: 'cv',
          fileName: '${List.filled(10, 'long-name-').join()}.pdf',
        ),
        const StudentDocument(
          id: 'transcript',
          type: 'transcript',
          fileName: 'Transcript_2026.pdf',
        ),
        const StudentDocument(
          id: 'other',
          type: 'other',
          fileName: 'Certificate_Flutter.pdf',
        ),
      ]);
      final element = tester.element(find.byType(ResumeUploadScreen));
      ProviderScope.containerOf(element).invalidate(studentDocumentsProvider);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('แทนที่'), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNWidgets(3));
      expect(
        tester.getSize(find.byType(ListView)).width,
        lessThanOrEqualTo(448),
      );
    });
  }
  for (final kind in ['cv', 'transcript', 'other']) {
    testWidgets(
      'empty $kind row uploads immediately and offers stored actions',
      (tester) async {
        final repo = DocumentsRepo()..uploadWait = Completer<void>();
        await open(tester, repo, () async => MemoryPdf('file.pdf'));
        final label = {
          'cv': 'เพิ่ม CV',
          'transcript': 'เพิ่ม Transcript',
          'other': 'เพิ่มไฟล์',
        }[kind]!;
        expect(find.text(label), findsOneWidget);
        await tester.tap(find.text(label));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(repo.uploadCalls, 1);
        expect(repo.lastKind, kind);
        expect(find.text('กำลังอัปโหลด…'), findsOneWidget);
        expect(find.text('file.pdf'), findsOneWidget);
        expect(find.text('อัปโหลด CV'), findsNothing);
        expect(find.text('พร้อมอัปโหลด'), findsNothing);
        final buttons = tester.widgetList<NeoButton>(find.byType(NeoButton));
        expect(buttons.every((b) => b.onPressed == null), isTrue);
        repo.uploadWait!.complete();
        await tester.pumpAndSettle();
        expect(find.text('กำลังอัปโหลด…'), findsNothing);
        expect(find.text('อัปโหลดแล้ว'), findsOneWidget);
        expect(find.text('แทนที่'), findsNothing);
        await tester.ensureVisible(find.byTooltip('จัดการ file.pdf'));
        await tester.tap(find.byTooltip('จัดการ file.pdf'));
        await tester.pumpAndSettle();
        expect(find.text('เปิดดู'), findsOneWidget);
        expect(find.text('แทนที่'), findsOneWidget);
        expect(find.text('ลบ'), findsOneWidget);
        if (kind == 'other') {
          expect(find.text('เอกสารอื่นๆ (1/3)'), findsOneWidget);
          expect(find.text('เพิ่มไฟล์'), findsOneWidget);
        }
        await tester.tap(find.text('ลบ'));
        await tester.pumpAndSettle();
        expect(repo.deleted, ['doc-1']);
        expect(find.text('file.pdf'), findsNothing);
        expect(find.text(label), findsOneWidget);
      },
    );
  }

  testWidgets(
    'replace CV keeps one file and a failed upload preserves the old row',
    (tester) async {
      final repo = DocumentsRepo()
        ..documents.add(
          const StudentDocument(id: 'old-cv', type: 'cv', fileName: 'old.pdf'),
        );
      await open(tester, repo, () async => MemoryPdf('new.pdf'));
      repo.failUpload = true;
      await tester.tap(find.byTooltip('จัดการ old.pdf'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('แทนที่'));
      await tester.pumpAndSettle();
      expect(find.text('old.pdf'), findsOneWidget);
      expect(find.text('อัปโหลดไม่สำเร็จ'), findsOneWidget);
      repo.failUpload = false;
      await tester.tap(find.byTooltip('จัดการ old.pdf'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('แทนที่'));
      await tester.pumpAndSettle();
      expect(repo.documents.length, 1);
      expect(find.text('new.pdf'), findsOneWidget);
      expect(find.text('old.pdf'), findsNothing);
      expect(repo.deleted, isEmpty);
      await tester.tap(find.text('new.pdf'));
      await tester.pumpAndSettle();
      expect(find.byType(ResumePreviewModal), findsOneWidget);
      expect(repo.openedId, 'doc-2');
    },
  );

  testWidgets('three other files cannot add a fourth but can replace one', (
    tester,
  ) async {
    final repo = DocumentsRepo()
      ..documents.addAll(
        List.generate(
          3,
          (i) => StudentDocument(
            id: 'other-$i',
            type: 'other',
            fileName: 'old-$i.pdf',
          ),
        ),
      );
    await open(tester, repo, () async => MemoryPdf('replacement.pdf'));
    expect(find.text('เอกสารอื่นๆ (3/3)'), findsOneWidget);
    expect(find.text('เพิ่มไฟล์'), findsNothing);
    await tester.ensureVisible(find.byTooltip('จัดการ old-0.pdf'));
    await tester.tap(find.byTooltip('จัดการ old-0.pdf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('แทนที่').first);
    await tester.pumpAndSettle();
    expect(repo.replacingId, 'other-0');
    expect(repo.documents.length, 3);
    expect(repo.deleted, isEmpty);
    expect(find.text('replacement.pdf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final file in [
    MemoryPdf('text.txt'),
    MemoryPdf('fake.pdf', content: 'not PDF'),
    MemoryPdf('big.pdf', reportedSize: 10 * 1024 * 1024 + 1),
  ]) {
    testWidgets('rejects invalid selection ${file.name} without a saved row', (
      tester,
    ) async {
      final repo = DocumentsRepo();
      await open(tester, repo, () async => file);
      await tester.tap(find.text('เพิ่ม CV'));
      await tester.pumpAndSettle();
      expect(repo.uploadCalls, 0);
      expect(repo.documents, isEmpty);
      expect(find.text('อัปโหลดแล้ว'), findsNothing);
      expect(
        find.textContaining(file.name == 'big.pdf' ? 'ใหญ่เกิน 10 MiB' : 'PDF'),
        findsWidgets,
      );
      expect(find.text('เพิ่ม CV'), findsOneWidget);
    });
  }

  testWidgets(
    'canceling selection makes no request and disposed picker is safe',
    (tester) async {
      final repo = DocumentsRepo();
      final selection = Completer<PlatformFile?>();
      await open(tester, repo, () => selection.future);
      await tester.tap(find.text('เพิ่ม CV'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      selection.complete(null);
      await tester.pumpAndSettle();
      expect(repo.uploadCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

final class MemoryPdf extends PlatformFile {
  MemoryPdf(this.name, {this.content = '%PDF-1.4 test', this.reportedSize});
  @override
  final String name;
  final String content;
  final int? reportedSize;
  @override
  Uri get uri => Uri.parse('memory:$name');
  @override
  Never get xFile => throw UnimplementedError();
  @override
  int? lengthSync() => reportedSize ?? content.length;
  @override
  Future<int?> length() async => lengthSync();
  @override
  Future<Uint8List> readAsBytes() async =>
      Uint8List.fromList(content.codeUnits);
  @override
  Stream<Uint8List> readAsByteStream() => Stream.fromFuture(readAsBytes());
}

class DocumentsRepo implements ResumeRepository {
  final documents = <StudentDocument>[];
  final deleted = <String>[];
  int uploadCalls = 0;
  String? lastKind, replacingId, openedId;
  bool failUpload = false;
  Completer<void>? uploadWait;
  @override
  Future<List<StudentDocument>> listDocuments() async => List.of(documents);
  @override
  Future<StudentDocument> uploadDocument({
    required String kind,
    required String filePath,
    required String fileName,
    List<int>? bytes,
    String? replacingId,
  }) async {
    uploadCalls++;
    lastKind = kind;
    this.replacingId = replacingId;
    await uploadWait?.future;
    if (failUpload) throw const AppException('อัปโหลดไม่สำเร็จ');
    if (kind != 'other') {
      documents.removeWhere((d) => d.type == kind);
    } else if (replacingId != null) {
      documents.removeWhere((d) => d.id == replacingId);
    }
    final document = StudentDocument(
      id: 'doc-$uploadCalls',
      type: kind,
      fileName: fileName,
    );
    documents.add(document);
    return document;
  }

  @override
  Future<void> deleteDocument(String id) async {
    deleted.add(id);
    documents.removeWhere((d) => d.id == id);
  }

  @override
  Future<List<int>> downloadDocumentPdf(String id) async {
    openedId = id;
    return '%PDF-1.4'.codeUnits;
  }

  @override
  Future<List<int>> downloadResumePdf() async => '%PDF-1.4'.codeUnits;
  @override
  Future<ResumeFile> uploadPdf({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) => throw UnimplementedError();
}
