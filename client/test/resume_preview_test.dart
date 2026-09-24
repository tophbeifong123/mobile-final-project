import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/resume/domain/entities/resume_file.dart';
import 'package:client/features/resume/domain/repositories/resume_repository.dart';
import 'package:client/features/resume/presentation/providers/resume_controller.dart';
import 'package:client/features/student_profile/domain/entities/student_profile.dart';
import 'package:client/features/student_profile/domain/repositories/student_profile_repository.dart';
import 'package:client/features/student_profile/presentation/providers/student_profile_controller.dart';
import 'package:client/features/student_profile/presentation/screens/student_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping ดูตัวอย่าง opens ResumePreviewModal and closing dismisses it', (tester) async {
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

    // Verify resume card shows file name and preview button
    expect(find.text('my_resume.pdf'), findsOneWidget);
    expect(find.text('ดูตัวอย่าง'), findsOneWidget);

    // Tap "ดูตัวอย่าง"
    await tester.tap(find.text('ดูตัวอย่าง'));
    await tester.pumpAndSettle();

    // Verify modal is open and displays resume info
    expect(find.text('ตัวอย่างเรซูเม่ (PDF Preview)'), findsOneWidget);
    expect(find.text('ปิด'), findsOneWidget);
    expect(find.text('เปลี่ยนไฟล์'), findsOneWidget);

    // Tap "ปิด"
    await tester.tap(find.text('ปิด'));
    await tester.pumpAndSettle();

    // Verify modal is dismissed
    expect(find.text('ตัวอย่างเรซูเม่ (PDF Preview)'), findsNothing);
  });
}

class _FakeStudentProfileRepository implements StudentProfileRepository {
  _FakeStudentProfileRepository({required this.profile});

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
  @override
  Future<ResumeFile> uploadPdf({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async {
    return ResumeFile(
      fileName: fileName,
      objectKey: 'resumes/$fileName',
    );
  }

  @override
  Future<List<int>> downloadResumePdf() async {
    return [0x25, 0x50, 0x44, 0x46]; // %PDF
  }
}
