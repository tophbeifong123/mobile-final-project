import 'dart:async';

import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/theme/app_tokens.dart';
import 'package:client/features/jobs/presentation/providers/jobs_controller.dart';
import 'package:client/features/jobs/presentation/screens/job_feed_screen.dart';
import 'package:client/features/jobs/presentation/widgets/feed_greeting_header.dart';
import 'package:client/features/saved_jobs/presentation/providers/saved_jobs_controller.dart';
import 'package:client/features/student_profile/domain/entities/student_profile.dart';
import 'package:client/features/student_profile/domain/repositories/student_profile_repository.dart';
import 'package:client/features/student_profile/presentation/providers/student_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

StudentProfile profile(String name, String university) => StudentProfile(
  fullName: name,
  university: university,
  major: 'สาขาที่อยู่ในหน้าโปรไฟล์เท่านั้น',
  skills: const ['ทักษะที่อยู่ในหน้าโปรไฟล์เท่านั้น'],
  bio: 'ชีวประวัติที่อยู่ในหน้าโปรไฟล์เท่านั้น',
  portfolioUrl: null,
  resumeFileName: 'private-resume.pdf',
);

ProviderContainer _containerFor(_ProfileRepository repository) =>
    ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
        studentProfileRepositoryProvider.overrideWithValue(repository),
        jobFeedProvider.overrideWith((ref) async => []),
        savedJobsProvider.overrideWith((ref) async => []),
      ],
    );

Widget home(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(theme: AppTheme.lightTheme, home: const JobFeedScreen()),
);

Finder headerText(String text) => find.descendant(
  of: find.byType(FeedGreetingHeader),
  matching: find.text(text),
);

void expectNoInventedStatus() {
  expect(headerText('ม.ธรรมศาสตร์ • พร้อมเริ่มฝึกงาน'), findsNothing);
  expect(
    find.descendant(
      of: find.byType(FeedGreetingHeader),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color == NeoColors.freshMint,
      ),
    ),
    findsNothing,
  );
}

void main() {
  for (final input in [
    ('กิตติ', 'มหาวิทยาลัยสงขลานครินทร์'),
    ('กิตติ', ''),
    ('', 'มหาวิทยาลัยสงขลานครินทร์'),
    ('', ''),
    ('  ', '\t'),
  ]) {
    testWidgets('home uses saved student identity (${input.$1}/${input.$2})', (
      tester,
    ) async {
      final repository = _ProfileRepository(profile(input.$1, input.$2));
      final container = _containerFor(repository);
      addTearDown(container.dispose);
      await tester.pumpWidget(home(container));
      await tester.pumpAndSettle();
      expect(headerText('สวัสดี'), findsOneWidget);
      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(FeedGreetingHeader),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .toList();
      expect(texts, [
        'สวัสดี',
        if (input.$1.trim().isNotEmpty) input.$1.trim(),
        '✨',
        if (input.$2.trim().isNotEmpty) input.$2.trim(),
      ]);
      expect(repository.fetchCount, 1);
      expectNoInventedStatus();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'loading and failed profile reads show a generic greeting without invented identity',
    (tester) async {
      final pending = Completer<StudentProfile>();
      final repository = _ProfileRepository(
        profile('', ''),
        pending: pending.future,
      );
      final container = _containerFor(repository);
      addTearDown(container.dispose);
      await tester.pumpWidget(home(container));
      await tester.pump();
      expect(headerText('สวัสดี'), findsOneWidget);
      expectNoInventedStatus();
      pending.completeError(StateError('profile unavailable'));
      await tester.pumpAndSettle();
      expect(headerText('สวัสดี'), findsOneWidget);
      expectNoInventedStatus();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'saving and reopening the profile updates the home header, including cleared fields',
    (tester) async {
      final repository = _ProfileRepository(
        profile('ชื่อเดิม', 'มหาวิทยาลัยเดิม'),
      );
      final container = _containerFor(repository);
      addTearDown(container.dispose);
      await tester.pumpWidget(home(container));
      await tester.pumpAndSettle();
      expect(headerText('ชื่อเดิม'), findsOneWidget);
      await container
          .read(studentProfileControllerProvider.notifier)
          .save(profile('ชื่อที่แก้แล้ว', 'มหาวิทยาลัยที่แก้แล้ว'));
      await tester.pumpAndSettle();
      expect(headerText('ชื่อที่แก้แล้ว'), findsOneWidget);
      expect(headerText('มหาวิทยาลัยที่แก้แล้ว'), findsOneWidget);
      expect(headerText('ชื่อเดิม'), findsNothing);
      container.invalidate(studentProfileControllerProvider);
      await tester.pumpAndSettle();
      expect(repository.fetchCount, 2);
      expect(headerText('ชื่อที่แก้แล้ว'), findsOneWidget);
      expect(headerText('มหาวิทยาลัยที่แก้แล้ว'), findsOneWidget);
      await container
          .read(studentProfileControllerProvider.notifier)
          .save(profile('', ''));
      await tester.pumpAndSettle();
      expect(headerText('ชื่อที่แก้แล้ว'), findsNothing);
      expect(headerText('มหาวิทยาลัยที่แก้แล้ว'), findsNothing);
      expect(headerText('สวัสดี'), findsOneWidget);
      expectNoInventedStatus();
      container.invalidate(studentProfileControllerProvider);
      await tester.pumpAndSettle();
      expect(repository.fetchCount, 3);
      expect(headerText('สวัสดี'), findsOneWidget);
      expectNoInventedStatus();
    },
  );

  testWidgets('long saved names and universities truncate on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final name = List.filled(10, 'ชื่อจริงที่ยาว').join();
    final university = List.filled(10, 'มหาวิทยาลัยชื่อยาว').join();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: FeedGreetingHeader(name: name, university: university),
          ),
        ),
      ),
    );
    expect(
      tester.widget<Text>(headerText(name)).overflow,
      TextOverflow.ellipsis,
    );
    expect(
      tester.widget<Text>(headerText(university)).overflow,
      TextOverflow.ellipsis,
    );
    expect(tester.takeException(), isNull);
  });
}

class _ProfileRepository implements StudentProfileRepository {
  _ProfileRepository(this.value, {this.pending});
  StudentProfile value;
  final Future<StudentProfile>? pending;
  int fetchCount = 0;

  @override
  Future<StudentProfile> fetchMe() async {
    fetchCount++;
    return pending ?? value;
  }

  @override
  Future<StudentProfile> update(StudentProfile profile) async =>
      value = profile;

  @override
  Future<StudentProfile> deleteAvatar() => throw UnimplementedError();

  @override
  Future<StudentProfile> uploadAvatar({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) => throw UnimplementedError();
}
