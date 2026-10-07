import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/resume/domain/entities/resume_file.dart';
import 'package:client/features/resume/domain/repositories/resume_repository.dart';
import 'package:client/features/resume/presentation/providers/resume_controller.dart';
import 'package:client/features/student_profile/domain/entities/student_profile.dart';
import 'package:client/features/student_profile/domain/entities/university.dart';
import 'package:client/features/student_profile/domain/entities/major.dart';
import 'package:client/features/student_profile/domain/repositories/student_profile_repository.dart';
import 'package:client/features/student_profile/presentation/providers/student_profile_controller.dart';
import 'package:client/features/student_profile/presentation/screens/student_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'tapping the resume file name opens ResumePreviewModal and closing dismisses it',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeStudentRepo = _FakeStudentProfileRepository(
        profile: const StudentProfile(
          fullName: 'กวินทร์ รัตนวงศ์',
          university: 'มหาวิทยาลัยเทคโนโลยีพระจอมเกล้าธนบุรี',
          major: 'วิทยาการคอมพิวเตอร์',
          skills: ['Flutter', 'Dart'],
          portfolioUrl: 'https://github.com/kawin-rat',
          resumeFileName: 'my_resume.pdf',
          resumeObjectKey: 'resumes/user-1/my_resume.pdf',
        ),
      );

      final fakeResumeRepo = _FakeResumeRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            studentProfileRepositoryProvider.overrideWithValue(fakeStudentRepo),
            resumeRepositoryProvider.overrideWithValue(fakeResumeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StudentProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify resume card shows the active resume file name.
      expect(find.text('my_resume.pdf'), findsOneWidget);

      // Tap the linked resume file name.
      await tester.tap(find.text('my_resume.pdf'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify modal is open and displays resume info
      expect(find.text('ตัวอย่างเรซูเม่ (PDF Preview)'), findsOneWidget);
      expect(find.text('ปิด'), findsOneWidget);

      // Tap "ปิด"
      await tester.tap(find.text('ปิด'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify modal is dismissed
      expect(find.text('ตัวอย่างเรซูเม่ (PDF Preview)'), findsNothing);
    },
  );
}

class _FakeStudentProfileRepository implements StudentProfileRepository {
  _FakeStudentProfileRepository({required this.profile});

  StudentProfile profile;

  @override
  Future<List<University>> searchUniversities(String query) async => const [];
  @override
  Future<List<Major>> searchMajors(String query) async => const [];

  @override
  Future<StudentProfile> fetchMe() async => profile;

  @override
  Future<StudentProfile> update(StudentProfile updated) async {
    profile = updated;
    return updated;
  }

  @override
  Future<StudentProfile> uploadAvatar({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async => profile;

  @override
  Future<StudentProfile> deleteAvatar() async => profile;
}

class _FakeResumeRepository implements ResumeRepository {
  @override
  Future<ResumeFile> uploadPdf({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async {
    return ResumeFile(fileName: fileName, objectKey: 'resumes/$fileName');
  }

  @override
  Future<List<int>> downloadResumePdf() async {
    return [0x25, 0x50, 0x44, 0x46]; // %PDF
  }

  @override
  Future<List<int>> downloadDocumentPdf(String id) async {
    return [0x25, 0x50, 0x44, 0x46]; // %PDF
  }

  @override
  Future<List<StudentDocument>> listDocuments() async => const [];

  @override
  Future<StudentDocument> uploadDocument({
    required String kind,
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async => StudentDocument(id: 'doc', type: kind, fileName: fileName);

  @override
  Future<void> deleteDocument(String id) async {}
}
