import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/resume/domain/entities/resume_file.dart';
import 'package:client/features/resume/domain/repositories/resume_repository.dart';
import 'package:client/features/resume/presentation/providers/resume_controller.dart';
import 'package:client/features/resume/presentation/screens/resume_upload_screen.dart';
import 'package:client/features/student_profile/domain/entities/student_profile.dart';
import 'package:client/features/student_profile/domain/repositories/student_profile_repository.dart';
import 'package:client/features/student_profile/presentation/providers/student_profile_controller.dart';
import 'package:client/features/student_profile/presentation/screens/student_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('student profile screen shows uploaded resume file name', (
    tester,
  ) async {
    final profileWithResume = const StudentProfile(
      fullName: 'มีนา เพ็งชัย',
      university: 'PSU',
      major: 'IT',
      skills: ['Flutter'],
      portfolioUrl: 'https://example.com',
      resumeFileName: 'my_resume.pdf',
      resumeObjectKey: 'resumes/user-1/my_resume.pdf',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          studentProfileRepositoryProvider.overrideWithValue(
            _FakeStudentProfileRepository(profileWithResume),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const StudentProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('my_resume.pdf'), findsOneWidget);
    expect(find.text('เปลี่ยน'), findsOneWidget);
  });

  testWidgets('student profile screen shows empty resume prompt when none uploaded', (
    tester,
  ) async {
    const profileWithoutResume = StudentProfile(
      fullName: 'มีนา เพ็งชัย',
      university: 'PSU',
      major: 'IT',
      skills: ['Flutter'],
      portfolioUrl: null,
      resumeFileName: null,
      resumeObjectKey: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          studentProfileRepositoryProvider.overrideWithValue(
            _FakeStudentProfileRepository(profileWithoutResume),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const StudentProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('ยังไม่มี Resume ในระบบ'), findsOneWidget);
    expect(find.text('อัปโหลด'), findsOneWidget);
  });

  testWidgets('resume upload screen renders current resume and upload controls', (
    tester,
  ) async {
    const profile = StudentProfile(
      fullName: 'มีนา เพ็งชัย',
      university: 'PSU',
      major: 'IT',
      skills: ['Flutter'],
      portfolioUrl: null,
      resumeFileName: 'current_resume.pdf',
      resumeObjectKey: 'resumes/current_resume.pdf',
    );

    final fakeResumeRepo = _FakeResumeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          studentProfileRepositoryProvider.overrideWithValue(
            _FakeStudentProfileRepository(profile),
          ),
          resumeRepositoryProvider.overrideWithValue(fakeResumeRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ResumeUploadScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('อัปโหลด Resume'), findsWidgets);
    expect(find.text('Resume ในระบบ'), findsOneWidget);
    expect(find.text('current_resume.pdf'), findsOneWidget);
    expect(find.text('เลือกไฟล์ PDF จากเครื่อง'), findsOneWidget);
    expect(find.text('เลือกไฟล์'), findsOneWidget);
  });
}

class _FakeStudentProfileRepository implements StudentProfileRepository {
  _FakeStudentProfileRepository(this.profile);

  StudentProfile profile;

  @override
  Future<StudentProfile> fetchMe() async => profile;

  @override
  Future<StudentProfile> update(StudentProfile updated) async {
    profile = updated;
    return updated;
  }
}

class _FakeResumeRepository implements ResumeRepository {
  ResumeFile? lastUploaded;

  @override
  Future<ResumeFile> uploadPdf({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async {
    final result = ResumeFile(
      fileName: fileName,
      objectKey: 'resumes/uploaded-$fileName',
    );
    lastUploaded = result;
    return result;
  }
}
