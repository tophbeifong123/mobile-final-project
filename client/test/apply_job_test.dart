import 'dart:async';

import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/widgets/neo_button.dart';
import 'package:client/features/applications/domain/entities/job_application.dart';
import 'package:client/features/applications/domain/repositories/application_repository.dart';
import 'package:client/features/applications/presentation/screens/apply_job_screen.dart';
import 'package:client/features/jobs/domain/entities/job.dart';
import 'package:client/features/jobs/domain/repositories/job_repository.dart';
import 'package:client/features/jobs/presentation/providers/jobs_controller.dart';
import 'package:client/features/student_profile/domain/entities/student_profile.dart';
import 'package:client/features/student_profile/domain/entities/university.dart';
import 'package:client/features/student_profile/domain/entities/major.dart';
import 'package:client/features/student_profile/domain/repositories/student_profile_repository.dart';
import 'package:client/features/student_profile/presentation/providers/student_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  const profileWithResume = StudentProfile(
    fullName: 'มีนา เพ็งชัย',
    university: 'PSU',
    major: 'IT',
    skills: ['Flutter'],
    portfolioUrl: 'https://example.com',
    resumeFileName: 'my_resume.pdf',
    resumeObjectKey: 'resumes/user-1/my_resume.pdf',
  );
  const profileWithoutResume = StudentProfile(
    fullName: 'มีนา เพ็งชัย',
    university: 'PSU',
    major: 'IT',
    skills: ['Flutter'],
    portfolioUrl: null,
    resumeFileName: null,
    resumeObjectKey: null,
  );
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

  testWidgets('with a Resume, shows real job details and submits once', (
    tester,
  ) async {
    final appRepository = _FakeApplicationRepository();
    await _mount(
      tester,
      profile: profileWithResume,
      appRepository: appRepository,
    );

    expect(find.text('Flutter Developer Intern'), findsOneWidget);
    expect(find.text('Tech Co'), findsOneWidget);
    expect(find.text('my_resume.pdf'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('apply-cover-letter')),
      'สนใจฝึกงานกับ Tech Co',
    );
    await tester.ensureVisible(find.byKey(const Key('apply-submit')));
    await tester.tap(find.byKey(const Key('apply-submit')));
    await tester.pumpAndSettle();

    expect(appRepository.applyCalls, 1);
    expect(appRepository.appliedJobId, 'job-123');
    expect(appRepository.appliedCoverLetter, 'สนใจฝึกงานกับ Tech Co');
    expect(find.text('Submitted'), findsOneWidget);
  });

  testWidgets('without a Resume, submit is disabled and upload route works', (
    tester,
  ) async {
    final appRepository = _FakeApplicationRepository();
    await _mount(
      tester,
      profile: profileWithoutResume,
      appRepository: appRepository,
    );

    expect(find.text('ยังไม่มี CV ในระบบ'), findsOneWidget);
    final submit = tester.widget<NeoButton>(
      find.byKey(const Key('apply-submit')),
    );
    expect(submit.onPressed, isNull);
    await tester.ensureVisible(find.byKey(const Key('apply-upload-cv')));
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
      profile: profileWithResume,
      appRepository: appRepository,
    );

    await tester.enterText(
      find.byKey(const Key('apply-cover-letter')),
      '  \n  ',
    );
    await tester.ensureVisible(find.byKey(const Key('apply-submit')));
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
      profile: profileWithResume,
      appRepository: appRepository,
    );
    await tester.enterText(
      find.byKey(const Key('apply-cover-letter')),
      'จดหมายสมัครงาน',
    );
    await tester.ensureVisible(find.byKey(const Key('apply-submit')));
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
      profile: profileWithResume,
      appRepository: appRepository,
    );
    await tester.enterText(
      find.byKey(const Key('apply-cover-letter')),
      'ข้อความที่ต้องเก็บไว้',
    );
    await tester.ensureVisible(find.byKey(const Key('apply-submit')));
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

  testWidgets('narrow screen and long job details do not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(
      tester,
      profile: profileWithoutResume,
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
  required StudentProfile profile,
  required _FakeApplicationRepository appRepository,
  JobDetail job = const JobDetail(
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
  ),
}) async {
  final router = GoRouter(
    initialLocation: '/student/jobs/job-123/apply',
    routes: [
      GoRoute(
        path: '/student/jobs/:jobId/apply',
        builder: (context, state) =>
            ApplyJobScreen(jobId: state.pathParameters['jobId']!),
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
        studentProfileRepositoryProvider.overrideWithValue(
          _FakeStudentProfileRepository(profile),
        ),
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

class _FakeStudentProfileRepository implements StudentProfileRepository {
  _FakeStudentProfileRepository(this.profile);
  final StudentProfile profile;

  @override
  Future<List<University>> searchUniversities(String query) async => const [];
  @override
  Future<List<Major>> searchMajors(String query) async => const [];
  @override
  Future<StudentProfile> fetchMe() async => profile;
  @override
  Future<StudentProfile> update(StudentProfile profile) async => profile;
  @override
  Future<StudentProfile> uploadAvatar({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async => profile;
  @override
  Future<StudentProfile> deleteAvatar() async => profile;
}

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
  }) async {
    applyCalls++;
    appliedJobId = jobId;
    appliedCoverLetter = coverLetter;
    if (failure != null) throw failure!;
    if (pending != null) return pending!.future;
    return _submitted(coverLetter);
  }
}
