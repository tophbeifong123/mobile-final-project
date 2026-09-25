import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/student_profile/data/models/student_profile_model.dart';
import 'package:client/features/student_profile/domain/entities/student_profile.dart';
import 'package:client/features/student_profile/domain/repositories/student_profile_repository.dart';
import 'package:client/features/student_profile/presentation/providers/student_profile_controller.dart';
import 'package:client/features/student_profile/presentation/screens/student_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStudentProfileRepository implements StudentProfileRepository {
  StudentProfile? profile;
  StudentProfile? lastSaved;

  @override
  Future<StudentProfile> fetchMe() async {
    return profile ??
        const StudentProfile(
          fullName: 'สมหญิง รักเรียน',
          university: 'จุฬาลงกรณ์มหาวิทยาลัย',
          major: 'วิศวกรรมคอมพิวเตอร์',
          skills: ['Flutter', 'Node.js'],
          bio: 'มุ่งมั่นพัฒนาแอปพลิเคชันที่มีคุณภาพ',
          contactLinks: [
            ContactLink(
              platform: 'phone',
              label: 'เบอร์โทร',
              value: '0891234567',
            ),
            ContactLink(platform: 'github', value: 'somyingdev'),
          ],
          portfolioLinks: [
            PortfolioLink(
              title: 'InternFinder App',
              url: 'https://github.com/somying/internfinder',
              description: 'Mobile App for internships',
            ),
          ],
          portfolioUrl: 'https://github.com/somying/internfinder',
        );
  }

  @override
  Future<StudentProfile> update(StudentProfile updated) async {
    lastSaved = updated;
    profile = updated;
    return updated;
  }

  @override
  Future<StudentProfile> uploadAvatar({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async {
    final updated = (profile ?? await fetchMe()).copyWith(
      avatarObjectKey: 'avatars/new_avatar.png',
    );
    profile = updated;
    lastSaved = updated;
    return updated;
  }

  @override
  Future<StudentProfile> deleteAvatar() async {
    final current = profile ?? await fetchMe();
    final updated = StudentProfile(
      fullName: current.fullName,
      university: current.university,
      major: current.major,
      skills: current.skills,
      bio: current.bio,
      contactLinks: current.contactLinks,
      portfolioLinks: current.portfolioLinks,
      portfolioUrl: current.portfolioUrl,
      resumeFileName: current.resumeFileName,
      resumeObjectKey: current.resumeObjectKey,
      avatarObjectKey: null,
    );
    profile = updated;
    lastSaved = updated;
    return updated;
  }
}

void main() {
  group('StudentProfileModel and Entities', () {
    test(
      'serializes and deserializes bio, contactLinks, portfolioLinks correctly',
      () {
        final json = {
          'fullName': 'สมชาย',
          'university': 'PSU',
          'major': 'CS',
          'skills': ['Dart', 'Flutter'],
          'bio': 'ชอบการเขียนโค้ดและดีไซน์ UI',
          'contactLinks': [
            {
              'id': 'c-1',
              'platform': 'line',
              'label': 'Line ID',
              'value': '@somchai_line',
            },
          ],
          'portfolioLinks': [
            {
              'id': 'p-1',
              'title': 'My Project',
              'url': 'https://myproject.com',
              'description': 'A web app',
            },
          ],
          'portfolioUrl': 'https://myproject.com',
          'resumeFileName': 'resume.pdf',
          'resumeObjectKey': 'resumes/somchai.pdf',
        };

        final model = StudentProfileModel.fromJson(json);
        expect(model.fullName, 'สมชาย');
        expect(model.bio, 'ชอบการเขียนโค้ดและดีไซน์ UI');
        expect(model.contactLinks.length, 1);
        expect(model.contactLinks.first.platform, 'line');
        expect(model.contactLinks.first.value, '@somchai_line');
        expect(model.portfolioLinks.length, 1);
        expect(model.portfolioLinks.first.title, 'My Project');

        final entity = model.toEntity();
        expect(entity.bio, 'ชอบการเขียนโค้ดและดีไซน์ UI');
        expect(entity.contactLinks.first.value, '@somchai_line');
        expect(entity.portfolioLinks.first.url, 'https://myproject.com');

        final serialized = model.toJson();
        expect(serialized['bio'], 'ชอบการเขียนโค้ดและดีไซน์ UI');
        expect(serialized['contactLinks'], isA<List>());
        expect(serialized['portfolioLinks'], isA<List>());
      },
    );
  });

  group('StudentProfileScreen UI', () {
    testWidgets(
      'renders profile, bio, general info, skills, and unified links card in order',
      (tester) async {
        tester.view.physicalSize = const Size(400, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeRepo = _FakeStudentProfileRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
              studentProfileRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const StudentProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check Bio Card
        expect(find.text('เกี่ยวกับฉัน (About Me)'), findsOneWidget);
        expect(
          find.text('มุ่งมั่นพัฒนาแอปพลิเคชันที่มีคุณภาพ'),
          findsOneWidget,
        );

        // Check General Info Card
        expect(find.text('ข้อมูลทั่วไป (General Info)'), findsOneWidget);
        expect(find.text('สมหญิง รักเรียน'), findsWidgets);

        // Check Skills Card
        expect(find.text('ทักษะและความสามารถ (Skills)'), findsOneWidget);

        // Check Unified Links Card (ผลงานและช่องทางติดต่อ)
        expect(find.text('ผลงานและช่องทางติดต่อ (Links)'), findsOneWidget);
        expect(find.text('0891234567'), findsOneWidget);
        expect(find.text('somyingdev'), findsOneWidget);
        expect(
          find.text('https://github.com/somying/internfinder'),
          findsOneWidget,
        );
      },
    );

    testWidgets('allows adding a new link and saving profile', (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeStudentProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            studentProfileRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StudentProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the "+ เพิ่ม" button in Links Card
      final addLinkButton = find.widgetWithText(InkWell, 'เพิ่ม');
      expect(addLinkButton, findsOneWidget);

      // Tap "+ เพิ่ม"
      await tester.tap(addLinkButton);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('เพิ่มผลงาน / ช่องทางติดต่อ'), findsOneWidget);

      // Fill in URL (since default is 'portfolio')
      await tester.enterText(
        find.widgetWithText(TextFormField, 'https://...'),
        'https://gitlab.com/newproject',
      );

      // Tap "บันทึก" in dialog
      await tester.tap(find.widgetWithText(FilledButton, 'บันทึก'));
      await tester.pumpAndSettle();

      // Ensure new link is now listed
      expect(find.text('https://gitlab.com/newproject'), findsOneWidget);

      // Edit bio
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'มุ่งมั่นพัฒนาแอปพลิเคชันที่มีคุณภาพ',
        ),
        'อัปเดตประวัติเกี่ยวกับฉันฉบับใหม่',
      );

      // Tap save profile
      final saveButton = find.text('บันทึกโปรไฟล์');
      await tester.scrollUntilVisible(
        saveButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.lastSaved, isNotNull);
      expect(fakeRepo.lastSaved?.bio, 'อัปเดตประวัติเกี่ยวกับฉันฉบับใหม่');
      expect(
        fakeRepo.lastSaved?.contactLinks.any(
          (c) => c.value == 'https://gitlab.com/newproject',
        ),
        isTrue,
      );
      expect(
        fakeRepo.lastSaved?.portfolioLinks.any(
          (p) => p.url == 'https://gitlab.com/newproject',
        ),
        isTrue,
      );
    });

    testWidgets(
      'dismisses add/edit dialog when tapping the top-right X button',
      (tester) async {
        tester.view.physicalSize = const Size(400, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeRepo = _FakeStudentProfileRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
              studentProfileRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const StudentProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap "+ เพิ่ม"
        await tester.tap(find.widgetWithText(InkWell, 'เพิ่ม'));
        await tester.pumpAndSettle();

        expect(find.text('เพิ่มผลงาน / ช่องทางติดต่อ'), findsOneWidget);

        // Tap the top-right [X] button in AlertDialog
        final closeButton = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byIcon(Icons.close_rounded),
        );
        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        // Dialog is dismissed
        expect(find.text('เพิ่มผลงาน / ช่องทางติดต่อ'), findsNothing);
      },
    );

    testWidgets(
      'shows avatar modal when tapping camera button and dismisses on X',
      (tester) async {
        tester.view.physicalSize = const Size(400, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeRepo = _FakeStudentProfileRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
              studentProfileRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const StudentProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the camera icon on the avatar
        await tester.tap(find.byIcon(Icons.photo_camera_rounded));
        await tester.pumpAndSettle();

        expect(find.text('รูปโปรไฟล์ (Profile Avatar)'), findsOneWidget);
        expect(find.text('เลือกรูปโปรไฟล์'), findsOneWidget);

        // Tap top-right X in the bottom sheet
        final closeButton = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byIcon(Icons.close_rounded),
        );
        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        expect(find.text('รูปโปรไฟล์ (Profile Avatar)'), findsNothing);
      },
    );

    testWidgets(
      'shows delete avatar option when avatar already exists and confirms delete',
      (tester) async {
        tester.view.physicalSize = const Size(400, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeRepo = _FakeStudentProfileRepository();
        fakeRepo.profile = const StudentProfile(
          fullName: 'มีนา เพ็งชัย',
          university: 'PSU',
          major: 'IT',
          skills: ['Flutter'],
          portfolioUrl: null,
          avatarObjectKey: 'avatars/my_avatar.png',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
              studentProfileRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const StudentProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the camera icon
        await tester.tap(find.byIcon(Icons.photo_camera_rounded));
        await tester.pumpAndSettle();

        expect(find.text('รูปโปรไฟล์ (Profile Avatar)'), findsOneWidget);
        expect(find.text('เปลี่ยนรูปภาพใหม่'), findsOneWidget);
        expect(find.text('ลบรูปโปรไฟล์'), findsOneWidget);

        // Tap delete avatar
        await tester.tap(find.text('ลบรูปโปรไฟล์'));
        await tester.pumpAndSettle();

        // Confirm dialog appears
        expect(find.text('ยืนยันการลบรูปโปรไฟล์'), findsOneWidget);

        // Tap confirm button
        await tester.tap(find.widgetWithText(FilledButton, 'ลบรูปโปรไฟล์'));
        await tester.pumpAndSettle();

        expect(fakeRepo.lastSaved?.avatarObjectKey, isNull);
        expect(find.text('ลบรูปโปรไฟล์แล้ว'), findsOneWidget);
      },
    );
  });
}
