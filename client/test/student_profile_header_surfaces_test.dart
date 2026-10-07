import 'dart:convert';

import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/applications/presentation/providers/applications_controller.dart';
import 'package:client/features/applications/presentation/screens/my_applications_screen.dart';
import 'package:client/features/jobs/domain/entities/job.dart';
import 'package:client/features/jobs/presentation/providers/jobs_controller.dart';
import 'package:client/features/jobs/presentation/screens/job_feed_screen.dart';
import 'package:client/features/jobs/presentation/widgets/feed_greeting_header.dart';
import 'package:client/features/saved_jobs/presentation/providers/saved_jobs_controller.dart';
import 'package:client/features/student_profile/domain/entities/major.dart';
import 'package:client/features/student_profile/domain/entities/student_profile.dart';
import 'package:client/features/student_profile/domain/entities/university.dart';
import 'package:client/features/student_profile/domain/repositories/student_profile_repository.dart';
import 'package:client/features/student_profile/presentation/providers/student_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jQioAAAAASUVORK5CYII=',
);

StudentProfile _profile({
  String name = 'กิตติ',
  String university = 'มหาวิทยาลัยสงขลานครินทร์',
  String major = 'วิศวกรรมซอฟต์แวร์',
  String? avatarKey = 'avatar-1',
}) => StudentProfile(
  fullName: name,
  university: university,
  major: major,
  skills: const [],
  portfolioUrl: null,
  avatarObjectKey: avatarKey,
);

ProviderContainer _container({required StudentProfile profile}) {
  return ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
      studentProfileRepositoryProvider.overrideWithValue(
        _ProfileRepository(profile),
      ),
      studentAvatarBytesProvider.overrideWith((ref, key) async {
        if (key == null || key.isEmpty) return null;
        return key == 'broken-avatar' ? [0, 1, 2] : _onePixelPng;
      }),
      jobFeedProvider.overrideWith(
        (ref) async => const JobPage(items: [], total: 0, totalPages: 0),
      ),
      savedJobsProvider.overrideWith((ref) async => []),
      myApplicationsProvider.overrideWith((ref) async => const []),
    ],
  );
}

Widget _screen(ProviderContainer container, Widget screen) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.lightTheme, home: screen),
    );

void main() {
  testWidgets('Home and My Applications show the uploaded profile image', (
    tester,
  ) async {
    final container = _container(profile: _profile());
    addTearDown(container.dispose);

    await tester.pumpWidget(_screen(container, const JobFeedScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(FeedGreetingHeader), findsOneWidget);
    expect(find.text('กิตติ'), findsOneWidget);
    expect(find.text('มหาวิทยาลัยสงขลานครินทร์'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('วิศวกรรมซอฟต์แวร์'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_screen(container, const MyApplicationsScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(FeedGreetingHeader), findsOneWidget);
    expect(find.text('กิตติ'), findsOneWidget);
    expect(find.text('มหาวิทยาลัยสงขลานครินทร์'), findsOneWidget);
    expect(find.text('วิศวกรรมซอฟต์แวร์'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('ยังไม่มีใบสมัคร'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing avatar and blank identity fields use safe fallbacks', (
    tester,
  ) async {
    final container = _container(
      profile: _profile(
        name: '  ',
        university: '\t',
        major: '  ',
        avatarKey: null,
      ),
    );
    addTearDown(container.dispose);

    for (final screen in [
      const JobFeedScreen(),
      const MyApplicationsScreen(),
    ]) {
      await tester.pumpWidget(_screen(container, screen));
      await tester.pumpAndSettle();

      final header = find.byType(FeedGreetingHeader);
      expect(find.text('สวัสดี'), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(
        find.descendant(
          of: header,
          matching: find.text('มหาวิทยาลัยสงขลานครินทร์'),
        ),
        findsNothing,
      );
      expect(find.text('กิตติ'), findsNothing);
      expect(find.text('วิศวกรรมซอฟต์แวร์'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('saving the profile updates shared header values on both pages', (
    tester,
  ) async {
    final container = _container(profile: _profile());
    addTearDown(container.dispose);

    await tester.pumpWidget(_screen(container, const JobFeedScreen()));
    await tester.pumpAndSettle();
    await container
        .read(studentProfileControllerProvider.notifier)
        .save(
          _profile(
            name: 'ชื่อใหม่',
            university: 'มหาวิทยาลัยใหม่',
            major: 'สาขาใหม่',
            avatarKey: 'avatar-2',
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('ชื่อใหม่'), findsOneWidget);
    expect(find.text('มหาวิทยาลัยใหม่'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.pumpWidget(_screen(container, const MyApplicationsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('ชื่อใหม่'), findsOneWidget);
    expect(find.text('มหาวิทยาลัยใหม่'), findsOneWidget);
    expect(find.text('สาขาใหม่'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    await container
        .read(studentProfileControllerProvider.notifier)
        .deleteAvatar();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an invalid avatar image falls back to the person icon', (
    tester,
  ) async {
    final container = _container(profile: _profile(avatarKey: 'broken-avatar'));
    addTearDown(container.dispose);

    await tester.pumpWidget(_screen(container, const MyApplicationsScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ProfileRepository implements StudentProfileRepository {
  _ProfileRepository(this.value);

  StudentProfile value;

  @override
  Future<StudentProfile> fetchMe() async => value;

  @override
  Future<List<University>> searchUniversities(String query) async => const [];

  @override
  Future<List<Major>> searchMajors(String query) async => const [];

  @override
  Future<StudentProfile> update(StudentProfile profile) async =>
      value = profile;

  @override
  Future<StudentProfile> deleteAvatar() async => value = StudentProfile(
    fullName: value.fullName,
    university: value.university,
    major: value.major,
    skills: value.skills,
    bio: value.bio,
    contactLinks: value.contactLinks,
    portfolioLinks: value.portfolioLinks,
    portfolioUrl: value.portfolioUrl,
    resumeFileName: value.resumeFileName,
    resumeObjectKey: value.resumeObjectKey,
    avatarObjectKey: null,
    universityId: value.universityId,
    customUniversityName: value.customUniversityName,
    majorId: value.majorId,
    customMajorName: value.customMajorName,
  );

  @override
  Future<StudentProfile> uploadAvatar({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async => value = value.copyWith(avatarObjectKey: 'avatar-updated');
}
