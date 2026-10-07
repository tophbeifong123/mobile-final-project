import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/theme/app_tokens.dart';
import 'package:client/core/widgets/neo_button.dart';
import 'package:client/core/widgets/app_card.dart';
import 'package:client/features/company_jobs/presentation/widgets/company_applicant_widgets.dart';
import 'package:client/features/applications/domain/entities/job_application.dart';
import 'package:client/features/applications/presentation/widgets/student_selection_cards.dart';
import 'package:client/features/company_jobs/domain/entities/company_job.dart';
import 'package:client/features/company_jobs/presentation/widgets/company_selection_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final deadline = DateTime.now().add(const Duration(days: 1));
  final past = DateTime.now().subtract(const Duration(hours: 1));

  for (final width in [320.0, 390.0, 768.0]) {
    for (final interview in [false, true]) {
      testWidgets(
        'student step actions are centered at $width, interview=$interview',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: StudentSelectionCards(
                    application: JobApplication(
                      id: 'app',
                      jobTitle: 'Intern',
                      companyName: 'Company',
                      status: ApplicationStatus.reviewing,
                      coverLetter: '',
                      examUrl: 'https://exam.example',
                      examDeadline: deadline,
                      interviewUrl: interview
                          ? 'https://interview.example'
                          : null,
                    ),
                    onOpenLink: (_) {},
                    onCompleteExam: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final cardCenter = tester.getCenter(find.byType(AppCard)).dx;
          final cardWidth = tester.getSize(find.byType(AppCard)).width;
          final buttons = find.byType(NeoButton);
          expect(buttons, findsNWidgets(interview ? 1 : 2));
          for (final button in buttons.evaluate()) {
            expect(
              tester.getSize(find.byWidget(button.widget)).width,
              closeTo(cardWidth - 32, .1),
            );
            expect(
              tester.getCenter(find.byWidget(button.widget)).dx,
              closeTo(cardCenter, .1),
            );
          }
          if (!interview) {
            expect(
              tester.getSize(find.widgetWithText(NeoButton, 'เปิดข้อสอบ')),
              tester.getSize(find.widgetWithText(NeoButton, 'ทำข้อสอบแล้ว')),
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final width in [320.0, 390.0, 768.0]) {
    for (final passed in [false, true]) {
      testWidgets(
        'company selection cards stretch and use ink text at $width, exam passed=$passed',
        (tester) async {
          tester.view.physicalSize = Size(width, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 1200),
                      textScaler: const TextScaler.linear(1.5),
                    ),
                    child: CompanySelectionSection(
                      applicant: Applicant(
                        applicationId: 'app',
                        fullName: 'Student',
                        university: '',
                        major: '',
                        status: 'reviewing',
                        coverLetter: '',
                        examUrl: passed
                            ? 'https://exam.example/${List.filled(10, 'long-path').join()}'
                            : null,
                        examDeadline: deadline,
                        examCompletedAt: passed ? past : null,
                        examPassedAt: passed ? past : null,
                        interviewUrl: passed
                            ? 'https://interview.example/${List.filled(10, 'long-path').join()}'
                            : null,
                      ),
                      onEditExam: () {},
                      onPassExam: () {},
                      onEditInterview: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final cards = find.byType(CompanyApplicantCard);
          expect(cards, findsNWidgets(2));
          expect(find.byIcon(Icons.quiz_outlined), findsOneWidget);
          expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);
          for (final symbol in [Icons.quiz_outlined, Icons.videocam_outlined]) {
            final icon = tester.widget<Icon>(find.byIcon(symbol));
            expect(icon.color, AppColors.primary);
            expect(icon.size, 20);
            expect(
              find.ancestor(
                of: find.byIcon(symbol),
                matching: find.byType(Container),
              ),
              findsNothing,
            );
          }
          for (final card in cards.evaluate()) {
            expect(
              tester.getSize(find.byWidget(card.widget)).width,
              width - 32,
            );
          }
          for (final button in find.byType(NeoButton).evaluate()) {
            expect(
              tester.getCenter(find.byWidget(button.widget)).dx,
              closeTo(width / 2, .1),
            );
          }
          expect(
            tester.widget<Text>(find.text('ข้อสอบ')).style?.color,
            NeoColors.inkSolid,
          );
          expect(
            tester.widget<Text>(find.text('นัดสัมภาษณ์ออนไลน์')).style?.color,
            NeoColors.inkSolid,
          );
          final message = passed
              ? find.textContaining('ตรวจว่าข้อสอบผ่านแล้วเมื่อ')
              : find.text('ยังไม่ได้ส่งลิงก์ข้อสอบ');
          expect(tester.widget<Text>(message).style?.color, NeoColors.inkSolid);
          if (!passed) {
            expect(
              tester
                  .widget<Text>(
                    find.text('เรียกสัมภาษณ์ได้หลังนักศึกษาทำข้อสอบแล้ว'),
                  )
                  .style
                  ?.color,
              NeoColors.inkSolid,
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('student can open an exam and mark it done before the deadline', (
    tester,
  ) async {
    var opened = '';
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StudentSelectionCards(
            application: JobApplication(
              id: 'app-1',
              jobTitle: 'ฝึกงาน',
              companyName: 'Acme',
              status: ApplicationStatus.reviewing,
              coverLetter: 'สวัสดี',
              examUrl: 'https://exam.example/quiz',
              examDeadline: deadline,
            ),
            onOpenLink: (url) => opened = url,
            onCompleteExam: () => completed++,
          ),
        ),
      ),
    );

    expect(find.text('เปิดข้อสอบ'), findsOneWidget);
    expect(find.text('ทำข้อสอบแล้ว'), findsOneWidget);
    expect(find.text('เปิดลิงก์นัด'), findsNothing);
    await tester.tap(find.text('เปิดข้อสอบ'));
    await tester.tap(find.text('ทำข้อสอบแล้ว'));
    expect(opened, 'https://exam.example/quiz');
    expect(completed, 1);
  });

  testWidgets('student exam buttons stay closed after the deadline', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StudentSelectionCards(
            now: DateTime.now(),
            application: JobApplication(
              id: 'app-1',
              jobTitle: 'ฝึกงาน',
              companyName: 'Acme',
              status: ApplicationStatus.reviewing,
              coverLetter: 'สวัสดี',
              examUrl: 'https://exam.example/quiz',
              examDeadline: past,
            ),
            onOpenLink: (_) {},
            onCompleteExam: () {},
          ),
        ),
      ),
    );

    expect(find.text('หมดเวลาทำข้อสอบแล้ว'), findsOneWidget);
    expect(find.text('เปิดข้อสอบ'), findsNothing);
    expect(find.text('ทำข้อสอบแล้ว'), findsNothing);
  });

  testWidgets(
    'company can send an exam while reviewing and sees a finished exam',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CompanySelectionSection(
              applicant: Applicant(
                applicationId: 'app-1',
                fullName: 'อลิซ',
                university: 'มหาวิทยาลัยทดสอบ',
                major: 'คอมพิวเตอร์',
                status: 'reviewing',
                coverLetter: 'สวัสดี',
                examUrl: 'https://exam.example/quiz',
                examDeadline: past,
                examCompletedAt: DateTime.now(),
              ),
              onEditExam: () {},
              onPassExam: () {},
              onEditInterview: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('นักศึกษาทำข้อสอบแล้ว'), findsOneWidget);
      expect(find.text('แก้ลิงก์ข้อสอบ'), findsNothing);
      expect(find.text('ข้อสอบผ่าน'), findsOneWidget);
      expect(find.text('ส่งลิงก์นัด'), findsNothing);
      expect(
        find.text('เรียกสัมภาษณ์ได้หลังตรวจว่าข้อสอบผ่าน'),
        findsOneWidget,
      );
    },
  );

  testWidgets('company cannot invite before the exam is finished', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: CompanySelectionSection(
            applicant: const Applicant(
              applicationId: 'app-1',
              fullName: 'อลิซ',
              university: 'มหาวิทยาลัยทดสอบ',
              major: 'คอมพิวเตอร์',
              status: 'reviewing',
              coverLetter: 'สวัสดี',
              examUrl: 'https://exam.example/quiz',
            ),
            onEditExam: () {},
            onPassExam: () {},
            onEditInterview: () {},
          ),
        ),
      ),
    );

    expect(
      find.text('เรียกสัมภาษณ์ได้หลังนักศึกษาทำข้อสอบแล้ว'),
      findsOneWidget,
    );
    expect(find.text('ข้อสอบผ่าน'), findsNothing);
    expect(find.text('ส่งลิงก์นัด'), findsNothing);
    expect(find.text('นัดที่สำนักงาน'), findsNothing);
  });

  testWidgets('company can invite only after marking the exam passed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: CompanySelectionSection(
            applicant: Applicant(
              applicationId: 'app-1',
              fullName: 'อลิซ',
              university: 'มหาวิทยาลัยทดสอบ',
              major: 'คอมพิวเตอร์',
              status: 'reviewing',
              coverLetter: 'สวัสดี',
              examUrl: 'https://exam.example/quiz',
              examDeadline: past,
              examCompletedAt: DateTime.now(),
              examPassedAt: DateTime.now(),
            ),
            onEditExam: () {},
            onPassExam: () {},
            onEditInterview: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('ตรวจว่าข้อสอบผ่านแล้ว'), findsOneWidget);
    expect(find.text('ข้อสอบผ่าน'), findsNothing);
    expect(find.text('ส่งลิงก์นัด'), findsOneWidget);
  });

  testWidgets('on-site interview shows the office time without a link', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StudentSelectionCards(
            application: JobApplication(
              id: 'app-1',
              jobTitle: 'ฝึกงาน',
              companyName: 'Acme',
              status: ApplicationStatus.reviewing,
              coverLetter: 'สวัสดี',
              interviewMode: 'on_site',
              interviewStartsAt: deadline,
            ),
            onOpenLink: (_) {},
            onCompleteExam: () {},
          ),
        ),
      ),
    );

    expect(find.text('นัดสัมภาษณ์ออนไซต์'), findsOneWidget);
    expect(find.textContaining('สัมภาษณ์ที่สำนักงาน'), findsOneWidget);
    expect(find.text('ข้อสอบ'), findsNothing);
    expect(find.text('เปิดลิงก์นัด'), findsNothing);
  });

  testWidgets('an interview replaces the exam card on the student detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: StudentSelectionCards(
            application: JobApplication(
              id: 'app-1',
              jobTitle: 'ฝึกงาน',
              companyName: 'Acme',
              status: ApplicationStatus.reviewing,
              coverLetter: 'สวัสดี',
              examUrl: 'https://exam.example/quiz',
              examDeadline: deadline,
              examCompletedAt: DateTime.now(),
              interviewUrl: 'https://meet.example/room',
              interviewStartsAt: deadline,
            ),
            onOpenLink: (_) {},
            onCompleteExam: () {},
          ),
        ),
      ),
    );

    expect(find.text('นัดสัมภาษณ์ออนไลน์'), findsOneWidget);
    expect(find.text('เปิดลิงก์นัด'), findsOneWidget);
    expect(find.text('ข้อสอบ'), findsNothing);
    expect(find.text('เปิดข้อสอบ'), findsNothing);
  });
}
