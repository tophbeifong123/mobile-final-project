import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/applications/domain/entities/job_application.dart';
import 'package:client/features/applications/domain/repositories/application_repository.dart';
import 'package:client/features/applications/presentation/providers/applications_controller.dart';
import 'package:client/features/applications/presentation/screens/apply_job_screen.dart';
import 'package:client/features/jobs/domain/entities/job.dart';
import 'package:client/features/jobs/domain/repositories/job_repository.dart';
import 'package:client/features/jobs/presentation/providers/jobs_controller.dart';
import 'package:client/features/student_profile/domain/entities/student_profile.dart';
import 'package:client/features/student_profile/domain/repositories/student_profile_repository.dart';
import 'package:client/features/student_profile/presentation/providers/student_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets(
    'apply job screen shows warning banner and disables submit when student has no resume',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            studentProfileRepositoryProvider.overrideWithValue(
              _FakeStudentProfileRepository(profileWithoutResume),
            ),
            jobRepositoryProvider.overrideWithValue(
              _FakeJobRepository(sampleJob),
            ),
            applicationRepositoryProvider.overrideWithValue(
              _FakeApplicationRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ApplyJobScreen(jobId: 'job-123'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่มี Resume ในระบบ'), findsOneWidget);
      expect(find.text('อัปโหลด Resume'), findsOneWidget);

      final submitButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'ยืนยันสมัคร'),
      );
      expect(submitButton.onPressed, isNull);
    },
  );

  testWidgets(
    'apply job screen shows resume ready and submits cover letter successfully',
    (tester) async {
      final fakeAppRepo = _FakeApplicationRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            studentProfileRepositoryProvider.overrideWithValue(
              _FakeStudentProfileRepository(profileWithResume),
            ),
            jobRepositoryProvider.overrideWithValue(
              _FakeJobRepository(sampleJob),
            ),
            applicationRepositoryProvider.overrideWithValue(fakeAppRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ApplyJobScreen(jobId: 'job-123'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Flutter Developer Intern'), findsOneWidget);
      expect(find.text('Tech Co'), findsOneWidget);
      expect(find.text('Resume ที่จะใช้'), findsOneWidget);
      expect(find.text('my_resume.pdf'), findsOneWidget);

      final submitButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'ยืนยันสมัคร'),
      );
      expect(submitButton.onPressed, isNotNull);

      // Enter cover letter
      await tester.enterText(
        find.byType(TextFormField),
        'ผมสนใจร่วมงานกับบริษัท Tech Co มากครับ',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'ยืนยันสมัคร'));
      await tester.pumpAndSettle();

      expect(fakeAppRepo.appliedJobId, 'job-123');
      expect(
        fakeAppRepo.appliedCoverLetter,
        'ผมสนใจร่วมงานกับบริษัท Tech Co มากครับ',
      );
    },
  );

  testWidgets('validates empty cover letter', (tester) async {
    final fakeAppRepo = _FakeApplicationRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          studentProfileRepositoryProvider.overrideWithValue(
            _FakeStudentProfileRepository(profileWithResume),
          ),
          jobRepositoryProvider.overrideWithValue(
            _FakeJobRepository(sampleJob),
          ),
          applicationRepositoryProvider.overrideWithValue(fakeAppRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ApplyJobScreen(jobId: 'job-123'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'ยืนยันสมัคร'));
    await tester.pumpAndSettle();

    expect(find.text('กรอก Cover Letter'), findsOneWidget);
    expect(fakeAppRepo.appliedJobId, isNull);
  });
}

class _FakeStudentProfileRepository implements StudentProfileRepository {
  _FakeStudentProfileRepository(this.profile);
  final StudentProfile profile;

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
  Future<List<Job>> fetchFeed(JobFilter filter) async => const [];

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
    appliedJobId = jobId;
    appliedCoverLetter = coverLetter;
    return JobApplication(
      id: 'app-999',
      jobTitle: 'Flutter Developer Intern',
      companyName: 'Tech Co',
      status: ApplicationStatus.submitted,
      coverLetter: coverLetter,
    );
  }
}
