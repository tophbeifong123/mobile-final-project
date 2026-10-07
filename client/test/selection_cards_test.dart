import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/applications/domain/entities/job_application.dart';
import 'package:client/features/applications/presentation/widgets/student_selection_cards.dart';
import 'package:client/features/company_jobs/domain/entities/company_job.dart';
import 'package:client/features/company_jobs/presentation/widgets/company_selection_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final deadline = DateTime.now().add(const Duration(days: 1));
  final past = DateTime.now().subtract(const Duration(hours: 1));

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
