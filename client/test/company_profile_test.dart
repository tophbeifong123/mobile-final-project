import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/company_profile/domain/entities/company_profile.dart';
import 'package:client/features/company_profile/domain/entities/company_website_policy.dart';
import 'package:client/features/company_profile/domain/repositories/company_profile_repository.dart';
import 'package:client/features/company_profile/presentation/providers/company_profile_controller.dart';
import 'package:client/features/company_profile/presentation/screens/company_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mockProfile = CompanyProfile(
    name: 'Tech Solutions Co.',
    businessType: 'ซอฟต์แวร์ & ไอที (Software & IT Solutions)',
    description: 'พัฒนาแอปพลิเคชันมือถือและเว็บ',
    logoObjectKey: null,
    websiteUrl: 'https://techsolutions.co',
    location: 'FYI Center, Bangkok',
    companySize: '51-200',
    perks: ['💻 MacBook Pro', '🍱 Free Lunch'],
    coverObjectKey: null,
  );

  testWidgets(
    'renders redesigned company profile with neo-brutalist cards and fields',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeCompanyProfileRepository(profile: mockProfile);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            companyProfileRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CompanyProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top Bar & Branding
      expect(find.text('InternMatch'), findsOneWidget);
      expect(find.text('บริษัท'), findsOneWidget);
      expect(find.text('บรรยากาศการทำงานจริง (Life at Office)'), findsNothing);
      expect(find.text('Team & Collab'), findsNothing);
      expect(find.text('Pantry & Snacks'), findsNothing);

      // Cover & Avatar section
      expect(find.text('เปลี่ยนรูปหน้าปก'), findsOneWidget);
      expect(find.text('VERIFIED PARTNER'), findsOneWidget);

      // Section Cards
      expect(find.text('ข้อมูลทั่วไปของบริษัท'), findsOneWidget);
      expect(
        find.text('Tech Solutions Co.'),
        findsNWidgets(2),
      ); // Title & Form Input
      expect(
        find.text('ซอฟต์แวร์ & ไอที (Software & IT Solutions)'),
        findsOneWidget,
      );

      // Scroll down to check further sections
      final locationCard = find.text('สถานที่ฝึกงาน & การเดินทาง');
      await tester.ensureVisible(locationCard);
      expect(locationCard, findsOneWidget);
      expect(find.text('FYI Center, Bangkok'), findsOneWidget);

      final cultureCard = find.text('เกี่ยวกับและวัฒนธรรมองค์กร');
      await tester.ensureVisible(cultureCard);
      expect(cultureCard, findsOneWidget);
      expect(find.text('พัฒนาแอปพลิเคชันมือถือและเว็บ'), findsOneWidget);

      final perksCard = find.text('สวัสดิการเด็กฝึกงาน');
      await tester.ensureVisible(perksCard);
      expect(perksCard, findsOneWidget);
      expect(find.text('💻 MacBook Pro'), findsOneWidget);
      expect(find.text('🍱 Free Lunch'), findsOneWidget);
      expect(find.text('2 แท็ก'), findsOneWidget);

      // Primary CTA and Logout
      final saveButton = find.text('บันทึกโปรไฟล์');
      await tester.ensureVisible(saveButton);
      expect(saveButton, findsOneWidget);
      expect(find.text('ออกจากระบบ'), findsOneWidget);
    },
  );

  testWidgets('invalid website cannot save and displays a reason', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _FakeCompanyProfileRepository(profile: mockProfile);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyProfileRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompanyProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = find.widgetWithText(
      TextFormField,
      'https://techsolutions.co',
    );
    await tester.ensureVisible(field);
    await tester.enterText(field, 'javascript:alert(1)');
    await tester.ensureVisible(find.text('บันทึกโปรไฟล์'));
    await tester.tap(find.text('บันทึกโปรไฟล์'));
    await tester.pumpAndSettle();
    expect(repo.updateCalls, 0);
    expect(find.text(companyWebsiteError), findsOneWidget);
  });

  testWidgets('saved profile fields survive opening a new page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _FakeCompanyProfileRepository(profile: mockProfile);
    Widget page() => ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
        companyProfileRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const CompanyProfileScreen(),
      ),
    );
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    final name = find.widgetWithText(TextFormField, 'Tech Solutions Co.').first;
    await tester.enterText(name, 'Saved Company');
    final website = find.widgetWithText(
      TextFormField,
      'https://techsolutions.co',
    );
    await tester.ensureVisible(website);
    await tester.enterText(website, 'https://saved.example.com');
    await tester.ensureVisible(find.text('บันทึกโปรไฟล์'));
    await tester.tap(find.text('บันทึกโปรไฟล์'));
    await tester.pumpAndSettle();
    expect(repo.updateCalls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(find.text('Saved Company'), findsWidgets);
    expect(find.text('https://saved.example.com'), findsOneWidget);
    expect(repo.profile.businessType, mockProfile.businessType);
    expect(repo.profile.description, mockProfile.description);
    expect(repo.profile.companySize, mockProfile.companySize);
    expect(repo.profile.perks, mockProfile.perks);
    expect(repo.profile.location, mockProfile.location);
  });

  testWidgets('validates required fields before submitting', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeCompanyProfileRepository(profile: mockProfile);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyProfileRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompanyProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Clear name field
    final nameField = find
        .widgetWithText(TextFormField, 'Tech Solutions Co.')
        .first;
    await tester.enterText(nameField, '');

    final saveButton = find.text('บันทึกโปรไฟล์');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('กรอกข้อมูลนี้'), findsOneWidget);
    expect(repo.updateCalls, 0);
  });

  testWidgets('adds and removes perk tags dynamically', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeCompanyProfileRepository(profile: mockProfile);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyProfileRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompanyProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll to perks
    final perksCard = find.text('สวัสดิการเด็กฝึกงาน');
    await tester.ensureVisible(perksCard);
    expect(find.text('2 แท็ก'), findsOneWidget);

    // Add new perk
    final newPerkField = find.widgetWithText(
      TextFormField,
      'เช่น วันหยุดพิเศษ, คลาสเรียนฟรี...',
    );
    await tester.ensureVisible(newPerkField);
    await tester.enterText(newPerkField, '🎓 Mentor 1:1');
    await tester.tap(find.text('เพิ่ม'));
    await tester.pumpAndSettle();

    expect(find.text('🎓 Mentor 1:1'), findsOneWidget);
    expect(find.text('3 แท็ก'), findsOneWidget);

    // Remove first perk
    final closeIcons = find.byIcon(Icons.close_rounded);
    await tester.tap(closeIcons.first);
    await tester.pumpAndSettle();

    expect(find.text('💻 MacBook Pro'), findsNothing);
    expect(find.text('2 แท็ก'), findsOneWidget);
  });

  testWidgets('selects company size and saves profile successfully', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeCompanyProfileRepository(profile: mockProfile);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyProfileRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompanyProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Select 201-500 size
    final sizeButton = find.text('201-500 คน');
    await tester.ensureVisible(sizeButton);
    await tester.tap(sizeButton);
    await tester.pumpAndSettle();

    // Update website
    final webField = find.widgetWithText(
      TextFormField,
      'https://techsolutions.co',
    );
    await tester.ensureVisible(webField);
    await tester.enterText(webField, 'https://new-tech.com');

    // Tap Save
    final saveButton = find.text('บันทึกโปรไฟล์');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 1);
    expect(repo.profile.companySize, '201-500');
    expect(repo.profile.websiteUrl, 'https://new-tech.com');
    expect(find.text('บันทึกข้อมูลเรียบร้อยแล้ว! 🎉'), findsOneWidget);
  });

  testWidgets(
    'shows error state when fetching company profile fails and retry works',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FailingCompanyProfileRepository(profile: mockProfile);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            companyProfileRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CompanyProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('โหลดโปรไฟล์บริษัทไม่ได้'), findsOneWidget);
      expect(find.text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'), findsOneWidget);
      expect(find.text('ลองอีกครั้ง'), findsOneWidget);
      expect(find.text('ออกจากระบบ'), findsOneWidget);

      repo.shouldFail = false;
      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pumpAndSettle();

      expect(find.text('InternMatch'), findsOneWidget);
      expect(find.text('Tech Solutions Co.'), findsWidgets);
    },
  );
}

class _FakeCompanyProfileRepository implements CompanyProfileRepository {
  _FakeCompanyProfileRepository({required this.profile});

  CompanyProfile profile;
  int updateCalls = 0;
  int uploadLogoCalls = 0;
  int uploadCoverCalls = 0;
  int deleteLogoCalls = 0;
  int deleteCoverCalls = 0;

  @override
  Future<CompanyProfile> fetchMe() async => profile;

  @override
  Future<CompanyProfile> update(CompanyProfile updated) async {
    updateCalls++;
    profile = updated;
    return profile;
  }

  @override
  Future<CompanyProfile> uploadLogo({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async {
    uploadLogoCalls++;
    profile = profile.copyWith(
      logoObjectKey: () => 'company-logos/user-1/$fileName',
    );
    return profile;
  }

  @override
  Future<CompanyProfile> deleteLogo() async {
    deleteLogoCalls++;
    profile = profile.copyWith(logoObjectKey: () => null);
    return profile;
  }

  @override
  Future<CompanyProfile> uploadCover({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async {
    uploadCoverCalls++;
    profile = profile.copyWith(
      coverObjectKey: () => 'company-covers/user-1/$fileName',
    );
    return profile;
  }

  @override
  Future<CompanyProfile> deleteCover() async {
    deleteCoverCalls++;
    profile = profile.copyWith(coverObjectKey: () => null);
    return profile;
  }
}

class _FailingCompanyProfileRepository implements CompanyProfileRepository {
  _FailingCompanyProfileRepository({required this.profile});

  final CompanyProfile profile;
  bool shouldFail = true;

  @override
  Future<CompanyProfile> fetchMe() async {
    if (shouldFail) {
      throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
    }
    return profile;
  }

  @override
  Future<CompanyProfile> update(CompanyProfile updated) async => updated;

  @override
  Future<CompanyProfile> uploadLogo({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async => profile;

  @override
  Future<CompanyProfile> deleteLogo() async => profile;

  @override
  Future<CompanyProfile> uploadCover({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async => profile;

  @override
  Future<CompanyProfile> deleteCover() async => profile;
}
