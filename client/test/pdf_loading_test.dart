import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:client/features/student_profile/presentation/widgets/resume_preview_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfx/pdfx.dart';

void main() {
  testWidgets(
    'one central loader until first page decoded; later pages have no spinner or transition overlap',
    (tester) async {
      final png = await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 10, 10),
          Paint()..color = Colors.white,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(10, 10);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        image.dispose();
        picture.dispose();
        return bytes;
      });
      final opened = Completer<PdfDocument>();
      final document = _Document();
      final bytesState = ValueNotifier<AsyncValue<List<int>>>(
        const AsyncLoading(),
      );
      addTearDown(bytesState.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumePdfDocumentLoaderProvider.overrideWithValue(
              (_) => opened.future,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<AsyncValue<List<int>>>(
                valueListenable: bytesState,
                builder: (_, bytes, _) => ResumePreviewModal(
                  fileName: 'snapshot.pdf',
                  readOnly: true,
                  pdfBytes: bytes,
                  onRetry: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      bytesState.value = const AsyncData([1]);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      opened.complete(document);
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final viewer = tester.widget<PdfView>(find.byType(PdfView));
      expect(
        (viewer.builders.options as DefaultBuilderOptions).loaderSwitchDuration,
        Duration.zero,
      );
      document.pages[0].complete(_Image(png!, 1));
      await tester.runAsync(() async {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.drag(find.byType(PdfView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const ValueKey('pdf-page-placeholder')), findsWidgets);
      document.pages[1].complete(_Image(png, 2));
      await tester.runAsync(() async {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _Document extends PdfDocument {
  _Document()
    : super(sourceName: 'loading-test', id: 'loading-test', pagesCount: 2);
  final pages = [Completer<PdfPageImage>(), Completer<PdfPageImage>()];
  @override
  Future<PdfPage> getPage(
    int pageNumber, {
    bool autoCloseAndroid = false,
  }) async => _Page(this, pageNumber, pages[pageNumber - 1].future);
  @override
  Future<void> close() async {
    isClosed = true;
  }
}

class _Page extends PdfPage {
  _Page(PdfDocument document, int number, this.image)
    : super(
        document: document,
        id: 'page-$number',
        pageNumber: number,
        width: 100,
        height: 100,
        autoCloseAndroid: false,
      );
  final Future<PdfPageImage> image;
  @override
  Future<PdfPageImage?> render({
    required double width,
    required double height,
    PdfPageImageFormat format = PdfPageImageFormat.jpeg,
    String? backgroundColor,
    Rect? cropRect,
    int quality = 100,
    bool forPrint = false,
    bool removeTempFile = true,
  }) => image;
  @override
  Future<PdfPageTexture> createTexture() => throw UnimplementedError();
  @override
  Future<void> close() async {
    isClosed = true;
  }
}

class _Image extends PdfPageImage {
  _Image(Uint8List bytes, int number)
    : super(
        id: 'page-$number',
        pageNumber: number,
        width: 10,
        height: 10,
        bytes: bytes,
        format: PdfPageImageFormat.png,
        quality: 100,
      );
}
