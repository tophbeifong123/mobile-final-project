import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/company_profile/domain/entities/company_profile.dart';
import 'package:client/features/company_profile/domain/repositories/company_profile_repository.dart';
import 'package:client/features/company_profile/presentation/providers/company_profile_controller.dart';
import 'package:client/features/company_profile/presentation/screens/company_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mockProfile = CompanyProfile(
    name: 'Tech Solutions Co.',
    businessType: 'ซอฟต์แวร์',
    description: 'พัฒนาแอปพลิเคชันมือถือและเว็บ',
    logoObjectKey: null,
  );

  testWidgets('renders company profile form with existing fields and logout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
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

    expect(find.text('โปรไฟล์บริษัท'), findsOneWidget);
    expect(find.text('ชื่อ โลโก้ ประเภทกิจการ และคำอธิบาย'), findsOneWidget);
    expect(find.text('โลโก้บริษัท'), findsOneWidget);
    expect(find.text('ยังไม่มีโลโก้บริษัท'), findsOneWidget);
    expect(find.text('เลือกรูป'), findsOneWidget);

    expect(find.text('Tech Solutions Co.'), findsOneWidget);
    expect(find.text('ซอฟต์แวร์'), findsOneWidget);
    expect(find.text('พัฒนาแอปพลิเคชันมือถือและเว็บ'), findsOneWidget);

    expect(find.text('บันทึกโปรไฟล์'), findsOneWidget);
    expect(find.text('ออกจากระบบ'), findsOneWidget);
  });

  testWidgets('renders logo status when company already has logo uploaded', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profileWithLogo = const CompanyProfile(
      name: 'Tech Corp',
      businessType: 'IT',
      description: 'Consulting',
      logoObjectKey: 'company-logos/company-1/logo.png',
    );
    final repo = _FakeCompanyProfileRepository(profile: profileWithLogo);

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

    expect(find.text('มีโลโก้บริษัทแล้ว'), findsOneWidget);
    expect(find.text('เปลี่ยน'), findsOneWidget);
  });

  testWidgets('validates required fields before submitting', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
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
    final nameField = find.widgetWithText(TextFormField, 'Tech Solutions Co.');
    await tester.enterText(nameField, '');
    await tester.tap(find.text('บันทึกโปรไฟล์'));
    await tester.pumpAndSettle();

    expect(find.text('กรอกข้อมูลนี้'), findsOneWidget);
    expect(repo.updateCalls, 0);
  });

  testWidgets('saves updated company profile fields successfully', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
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

    // Update fields
    final nameField = find.widgetWithText(TextFormField, 'Tech Solutions Co.');
    await tester.enterText(nameField, 'New Company Name');

    final businessTypeField = find.widgetWithText(TextFormField, 'ซอฟต์แวร์');
    await tester.enterText(businessTypeField, 'เทคโนโลยี AI');

    final descriptionField = find.widgetWithText(
      TextFormField,
      'พัฒนาแอปพลิเคชันมือถือและเว็บ',
    );
    await tester.enterText(descriptionField, 'เชี่ยวชาญด้าน LLM และ Agent');

    await tester.tap(find.text('บันทึกโปรไฟล์'));
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 1);
    expect(repo.profile.name, 'New Company Name');
    expect(repo.profile.businessType, 'เทคโนโลยี AI');
    expect(repo.profile.description, 'เชี่ยวชาญด้าน LLM และ Agent');
    expect(find.text('บันทึกโปรไฟล์แล้ว'), findsOneWidget);
  });

  testWidgets('shows error state when fetching company profile fails and retry works', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
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

    expect(find.text('โปรไฟล์บริษัท'), findsOneWidget);
    expect(find.text('Tech Solutions Co.'), findsOneWidget);
  });
}

class _FakeCompanyProfileRepository implements CompanyProfileRepository {
  _FakeCompanyProfileRepository({required this.profile});

  CompanyProfile profile;
  int updateCalls = 0;
  int uploadLogoCalls = 0;

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
    profile = CompanyProfile(
      name: profile.name,
      businessType: profile.businessType,
      description: profile.description,
      logoObjectKey: 'company-logos/user-1/$fileName',
    );
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
}
