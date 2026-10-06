import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/theme/app_tokens.dart';
import 'package:client/core/widgets/app_card.dart';
import 'package:client/core/widgets/company_top_bar.dart';
import 'package:client/features/company_jobs/data/datasources/applicant_resume_remote_data_source.dart';
import 'package:client/features/company_jobs/domain/entities/company_job.dart';
import 'package:client/features/company_jobs/presentation/providers/company_jobs_controller.dart';
import 'package:client/features/company_jobs/presentation/screens/applicant_detail_screen.dart';
import 'package:client/features/company_jobs/presentation/screens/applicants_screen.dart';
import 'package:client/features/resume/presentation/providers/resume_controller.dart';
import 'package:client/features/student_profile/presentation/widgets/resume_preview_modal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfx/pdfx.dart';

const arg = (jobId: 'job-1', applicationId: 'app-1');
const applicant = Applicant(
  applicationId: 'app-1',
  fullName: 'ผู้สมัคร',
  university: 'มหาวิทยาลัย',
  major: 'สาขา',
  status: 'accepted',
  coverLetter: 'Cover Letter ของใบสมัคร',
  resumeObjectKey: 'resumes/original.pdf',
  resumeFileName: 'original.pdf',
);
final pdfBytes = utf8.encode('%PDF-1.4 snapshot document');

void phone(WidgetTester tester, [double width = 390]) {
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'company list uses ink cards and bounded text for every Thai status',
    (tester) async {
      phone(tester, 320);
      final long = List.filled(12, 'ข้อความยาว').join();
      await tester.pumpWidget(
        ProviderScope(
          retry: (count, error) => null,
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            companyJobApplicantsProvider('job-1').overrideWith(
              (ref) async => [
                for (final status in [
                  'submitted',
                  'reviewing',
                  'accepted',
                  'rejected',
                ])
                  Applicant(
                    applicationId: status,
                    fullName: long,
                    university: long,
                    major: long,
                    status: status,
                    coverLetter: '',
                  ),
              ],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ApplicantsScreen(jobId: 'job-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        NeoColors.paperCanvas,
      );
      expect(find.byType(CompanyTopBar), findsOneWidget);
      expect(find.byKey(const Key('company-top-bar-back')), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
      for (final status in [
        'ยื่นใบสมัครแล้ว',
        'กำลังพิจารณา',
        'ผ่านการคัดเลือก',
        'ไม่ผ่านการคัดเลือก',
      ]) {
        await tester.scrollUntilVisible(find.text(status), 160);
        expect(find.text(status), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      for (final text in tester.widgetList<Text>(find.text(long))) {
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
      }
      final card = tester.widget<AppCard>(find.byType(AppCard).first);
      expect(card.borderColor, NeoColors.inkSolid);
      expect(card.borderWidth, 2);
      expect(card.shadows, NeoShadows.elevation2);
    },
  );

  for (final empty in [false, true]) {
    testWidgets(
      'pull refresh reloads ${empty ? "empty" : "populated"} applicants',
      (tester) async {
        phone(tester);
        var requests = 0;
        await tester.pumpWidget(
          ProviderScope(
            retry: (count, error) => null,
            overrides: [
              tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
              companyJobApplicantsProvider('job-1').overrideWith((ref) async {
                requests++;
                return empty ? [] : [applicant];
              }),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ApplicantsScreen(jobId: 'job-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(requests, 1);
        await tester.drag(find.byType(ListView), const Offset(0, 450));
        await tester.pumpAndSettle();
        expect(requests, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'resume failure retries the company snapshot, never the student route',
    (tester) async {
      phone(tester);
      var attempts = 0, studentReads = 0;
      final pending = Completer<List<int>>();
      await tester.pumpWidget(
        ProviderScope(
          retry: (count, error) => null,
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            companyApplicantDetailProvider(
              arg,
            ).overrideWith((ref) async => applicant),
            applicantResumeBytesProvider(arg).overrideWith((ref) {
              attempts++;
              if (attempts == 1) {
                throw const AppException(
                  'เปิดไฟล์ Resume ไม่สำเร็จ กรุณาลองใหม่',
                );
              }
              return pending.future;
            }),
            resumePdfBytesProvider.overrideWith((ref) {
              studentReads++;
              throw StateError(
                'Company must not read the student resume endpoint',
              );
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ApplicantDetailScreen(
              jobId: 'job-1',
              applicationId: 'app-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('เปิด Resume (PDF)'));
      await tester.tap(find.text('เปิด Resume (PDF)'));
      await tester.pumpAndSettle();
      expect(find.byType(ResumePreviewModal), findsOneWidget);
      expect(
        find.text('เปิดไฟล์ Resume ไม่สำเร็จ กรุณาลองใหม่'),
        findsOneWidget,
      );
      expect(find.text('เปลี่ยนไฟล์'), findsNothing);
      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(attempts, 2);
      expect(find.text('กำลังดาวน์โหลดเอกสาร PDF...'), findsOneWidget);
      expect(studentReads, 0);
      await tester.tap(find.text('ปิด'));
      await tester.pumpAndSettle();
      expect(find.byType(ApplicantDetailScreen), findsOneWidget);
      expect(find.byType(ResumePreviewModal), findsNothing);
      pending.complete(pdfBytes);
    },
  );

  testWidgets('downloaded application bytes open in an embedded PDF viewer', (
    tester,
  ) async {
    phone(tester);
    final png = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 1, 1),
        Paint()..color = Colors.white,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(1, 1);
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      image.dispose();
      picture.dispose();
      return bytes;
    });
    Uint8List? opened;
    var closed = false;
    const channel = MethodChannel('io.scer.pdf_renderer');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'open.document.file') {
        throw PlatformException(code: 'test-use-memory');
      }
      if (call.method == 'open.document.data') {
        opened = call.arguments as Uint8List;
        return {'id': 'snapshot', 'pagesCount': 1};
      }
      if (call.method == 'open.page') {
        return {'id': 'page', 'width': 100, 'height': 100};
      }
      if (call.method == 'render') {
        return {'width': 1, 'height': 1, 'data': png};
      }
      if (call.method == 'close.document') closed = true;
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: (count, error) => null,
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyApplicantDetailProvider(
            arg,
          ).overrideWith((ref) async => applicant),
          applicantResumeBytesProvider(
            arg,
          ).overrideWith((ref) async => pdfBytes),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ApplicantDetailScreen(
            jobId: 'job-1',
            applicationId: 'app-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('เปิด Resume (PDF)'));
    await tester.tap(find.text('เปิด Resume (PDF)'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
    }
    await tester.pumpAndSettle();
    expect(find.byType(PdfView), findsOneWidget);
    expect(opened, orderedEquals(pdfBytes));
    expect(find.text('เปลี่ยนไฟล์'), findsNothing);
    expect(find.text('หน้า 1 / 1'), findsOneWidget);
    await tester.tap(find.text('ปิด'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    expect(closed, isTrue);
    expect(find.byType(ApplicantDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'resume datasource calls only the authenticated company application PDF path',
    () async {
      RequestOptions? captured;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response(
                requestOptions: options,
                data: pdfBytes,
                statusCode: 200,
              ),
            );
          },
        ),
      );
      expect(
        await ApplicantResumeRemoteDataSource(dio).fetch('job-1', 'app-1'),
        pdfBytes,
      );
      expect(captured!.path, '/company/jobs/job-1/applications/app-1/resume');
      expect(captured!.responseType, ResponseType.bytes);
      dio.close();
    },
  );

  test('resume datasource rejects an invalid PDF response', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: utf8.encode('<html>not PDF'),
            ),
          );
        },
      ),
    );
    await expectLater(
      ApplicantResumeRemoteDataSource(dio).fetch('job-1', 'app-1'),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'invalid PDF',
          contains('PDF ไม่ถูกต้อง'),
        ),
      ),
    );
    dio.close();
  });

  for (final status in [403, 404, 503]) {
    test('resume datasource safely reports HTTP $status', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: status,
                  data: utf8.encode('private storage error'),
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );
      await expectLater(
        ApplicantResumeRemoteDataSource(dio).fetch('job-1', 'app-1'),
        throwsA(
          isA<AppException>().having(
            (error) => error.message,
            'safe message',
            isNot(contains('private')),
          ),
        ),
      );
      dio.close();
    });
  }
}
