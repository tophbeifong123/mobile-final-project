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
            ContactLink(
              platform: 'github',
              value: 'somyingdev',
            ),
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
}

void main() {
  group('StudentProfileModel and Entities', () {
    test('serializes and deserializes bio, contactLinks, portfolioLinks correctly', () {
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
    });
  });

  group('StudentProfileScreen UI', () {
    testWidgets('renders bio, contact channels, and portfolio cards', (tester) async {
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
      expect(find.text('มุ่งมั่นพัฒนาแอปพลิเคชันที่มีคุณภาพ'), findsOneWidget);

      // Check Contact Channels Card
      expect(find.text('ช่องทางติดต่อ (Contact Channels)'), findsOneWidget);
      expect(find.text('0891234567'), findsOneWidget);
      expect(find.text('somyingdev'), findsOneWidget);

      // Check Portfolio Card
      expect(find.text('ผลงานและโปรเจกต์ (Portfolio)'), findsOneWidget);
      expect(find.text('InternFinder App'), findsOneWidget);
      expect(find.text('https://github.com/somying/internfinder'), findsOneWidget);
    });

    testWidgets('allows adding a new contact channel and saving profile', (tester) async {
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

      // Find the "+ เพิ่ม" button in Contact Channels Card
      final addContactButtons = find.widgetWithText(InkWell, 'เพิ่ม');
      expect(addContactButtons, findsWidgets);

      // Tap first "+ เพิ่ม" (contacts card)
      await tester.tap(addContactButtons.first);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('เพิ่มช่องทางติดต่อ'), findsOneWidget);

      // Fill in value
      await tester.enterText(
        find.widgetWithText(TextFormField, 'เช่น 0812345678, user@example.com หรือ @myline'),
        '0998877665',
      );

      // Tap "บันทึก" in dialog
      await tester.tap(find.widgetWithText(FilledButton, 'บันทึก'));
      await tester.pumpAndSettle();

      // Ensure new contact is now listed
      expect(find.text('0998877665'), findsOneWidget);

      // Edit bio
      await tester.enterText(
        find.widgetWithText(TextFormField, 'มุ่งมั่นพัฒนาแอปพลิเคชันที่มีคุณภาพ'),
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
        fakeRepo.lastSaved?.contactLinks.any((c) => c.value == '0998877665'),
        isTrue,
      );
    });
  });
}
