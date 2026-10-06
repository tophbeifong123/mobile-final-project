import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/applications/presentation/screens/application_detail_screen.dart';
import 'package:client/features/applications/presentation/screens/apply_job_screen.dart';
import 'package:client/features/applications/presentation/screens/my_applications_screen.dart';
import 'package:client/features/jobs/domain/entities/job.dart';
import 'package:client/features/jobs/domain/repositories/job_repository.dart';
import 'package:client/features/jobs/presentation/providers/jobs_controller.dart';
import 'package:client/features/jobs/presentation/screens/job_detail_screen.dart';
import 'package:client/features/jobs/presentation/screens/job_feed_screen.dart';
import 'package:client/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:client/features/resume/presentation/screens/resume_upload_screen.dart';
import 'package:client/features/saved_jobs/domain/entities/saved_job.dart';
import 'package:client/features/saved_jobs/domain/repositories/saved_job_repository.dart';
import 'package:client/features/saved_jobs/presentation/providers/saved_jobs_controller.dart';
import 'package:client/features/saved_jobs/presentation/screens/saved_jobs_screen.dart';
import 'package:client/features/student_profile/domain/entities/student_profile.dart';
import 'package:client/features/student_profile/domain/entities/university.dart';
import 'package:client/features/student_profile/domain/repositories/student_profile_repository.dart';
import 'package:client/features/student_profile/presentation/providers/student_profile_controller.dart';
import 'package:client/features/student_profile/presentation/screens/student_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('student screens render the Stitch chrome', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final screens = <Widget>[
      const SavedJobsScreen(),
      const MyApplicationsScreen(),
      const StudentProfileScreen(),
      const ResumeUploadScreen(),
      const NotificationsScreen(),
      const JobDetailScreen(jobId: 'job-1'),
      const ApplyJobScreen(jobId: 'job-1'),
      const ApplicationDetailScreen(applicationId: 'app-1'),
    ];

    for (final screen in screens) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            studentProfileRepositoryProvider.overrideWithValue(
              _FakeStudentProfileRepository(),
            ),
            jobRepositoryProvider.overrideWithValue(_EmptyJobRepository()),
            savedJobRepositoryProvider.overrideWithValue(
              _EmptySavedJobRepository(),
            ),
          ],
          child: MaterialApp(theme: AppTheme.lightTheme, home: screen),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          studentProfileRepositoryProvider.overrideWithValue(
            _FakeStudentProfileRepository(),
          ),
          jobRepositoryProvider.overrideWithValue(_EmptyJobRepository()),
          savedJobRepositoryProvider.overrideWithValue(
            _EmptySavedJobRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const JobFeedScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('สวัสดี'), findsOneWidget);
    expect(find.text('ยังไม่มีงานที่เปิดรับ'), findsOneWidget);

    await tester.tap(find.byTooltip('ตัวกรอง'));
    await tester.pumpAndSettle();
    expect(find.text('ใช้ตัวกรอง'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile form loads and saves the student fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeStudentProfileRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          studentProfileRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const StudentProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final universityField = find.byKey(const Key('student-university-picker'));
    await tester.scrollUntilVisible(
      universityField,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(universityField);
    await tester.pumpAndSettle();
    expect(find.text('PSU'), findsOneWidget);
    await tester.tap(universityField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('อื่นๆ — พิมพ์ชื่อสถาบันเอง'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'พิมพ์ชื่อสถาบันของคุณ',
      ),
      'KMUTT',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('เลือกมหาวิทยาลัย'), findsNothing);
    final saveButton = find.text('บันทึกโปรไฟล์');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(repository.lastSaved?.university, 'KMUTT');
    expect(repository.lastSaved?.universityId, isNull);
    expect(repository.lastSaved?.customUniversityName, 'KMUTT');
    expect(repository.lastSaved?.fullName, 'มีนา');
    expect(repository.lastSaved?.skills, ['Flutter']);
    expect(find.text('บันทึกโปรไฟล์แล้ว'), findsOneWidget);
  });
}

class _FakeStudentProfileRepository implements StudentProfileRepository {
  StudentProfile? lastSaved;

  @override
  Future<List<University>> searchUniversities(String query) async => const [];

  @override
  Future<StudentProfile> fetchMe() async {
    return const StudentProfile(
      fullName: 'มีนา',
      university: 'PSU',
      customUniversityName: 'PSU',
      major: 'IT',
      skills: ['Flutter'],
      portfolioUrl: null,
    );
  }

  @override
  Future<StudentProfile> update(StudentProfile profile) async {
    lastSaved = profile;
    return profile;
  }

  @override
  Future<StudentProfile> uploadAvatar({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async {
    return const StudentProfile(
      fullName: 'มีนา',
      university: 'PSU',
      major: 'IT',
      skills: ['Flutter'],
      portfolioUrl: null,
      avatarObjectKey: 'avatars/avatar.png',
    );
  }

  @override
  Future<StudentProfile> deleteAvatar() async {
    return const StudentProfile(
      fullName: 'มีนา',
      university: 'PSU',
      major: 'IT',
      skills: ['Flutter'],
      portfolioUrl: null,
    );
  }
}

class _EmptyJobRepository implements JobRepository {
  @override
  Future<List<Job>> fetchFeed(JobFilter filter) async => const [];

  @override
  Future<JobDetail> fetchDetail(String jobId) => throw UnimplementedError();

  @override
  Future<void> save(String jobId) async {}

  @override
  Future<void> unsave(String jobId) async {}
}

class _EmptySavedJobRepository implements SavedJobRepository {
  @override
  Future<List<SavedJob>> fetchSaved() async => const [];
}
