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

import 'package:client/core/provinces/thai_province.dart';
import 'package:client/core/provinces/thai_provinces_provider.dart';
import 'package:client/features/company_profile/data/models/company_profile_model.dart';
import 'package:client/features/company_profile/presentation/widgets/office_map_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  test('company profile JSON keeps office fields separate', () {
    final model = CompanyProfileModel.fromJson(const {
      'name': 'Tech Solutions Co.',
      'businessType': 'ซอฟต์แวร์',
      'description': '',
      'logoObjectKey': null,
      'provinceId': 90,
      'provinceName': 'สงขลา',
      'location': 'อาคาร A ถนนนิพัทธ์อุทิศ',
      'latitude': 7.0084,
      'longitude': 100.4747,
    });

    expect(
      CompanyProfileModel.fromEntity(model.toEntity()).toJson(),
      model.toJson(),
    );
    expect(model.toEntity().provinceId, 90);
    expect(model.toEntity().provinceName, 'สงขลา');
    expect(model.toEntity().location, 'อาคาร A ถนนนิพัทธ์อุทิศ');
    expect(model.toJson(), {
      'name': 'Tech Solutions Co.',
      'businessType': 'ซอฟต์แวร์',
      'description': '',
      'websiteUrl': '',
      'companySize': '',
      'perks': <String>[],
      'provinceId': 90,
      'location': 'อาคาร A ถนนนิพัทธ์อุทิศ',
      'latitude': 7.0084,
      'longitude': 100.4747,
    });
  });

  testWidgets('office preview marker is draggable but not saved until moved', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    LatLng? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: OfficeMapPicker(
              province: _provinces.first,
              pin: null,
              onPinChanged: (position) => selected = position,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(selected, isNull);
    expect(find.byKey(const Key('office-marker')), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('office-marker')),
      const Offset(60, 30),
    );
    await tester.pump();
    expect(selected, isNotNull);
    expect(selected, isNot(const LatLng(13.7563, 100.5018)));
  });

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
  testWidgets('province alias selects canonical province and map opens there', (
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
          thaiProvincesProvider.overrideWith((ref) async => _provinces),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompanyProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('company-province-picker')),
    );
    await tester.tap(find.byKey(const Key('company-province-picker')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'กทม.');
    await tester.pumpAndSettle();
    expect(find.text('กรุงเทพมหานคร'), findsOneWidget);
    await tester.tap(find.text('กรุงเทพมหานคร'));
    await tester.pumpAndSettle();

    expect(find.byType(OfficeMapPicker), findsOneWidget);
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCenter.latitude, 13.7563);
    expect(map.options.initialCenter.longitude, 100.5018);
    expect(find.textContaining('หมุดเริ่มที่กึ่งกลางจังหวัด'), findsOneWidget);

    await _tapSave(tester);
    await tester.pumpAndSettle();

    expect(repo.profile.provinceId, 10);
    expect(repo.profile.provinceName, 'กรุงเทพมหานคร');
    expect(repo.profile.latitude, isNull);
    expect(repo.profile.longitude, isNull);
  });

  testWidgets('saved company office has separate address and coordinates', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeCompanyProfileRepository(
      profile: const CompanyProfile(
        name: 'Tech Solutions Co.',
        businessType: 'ซอฟต์แวร์',
        description: 'พัฒนาแอปพลิเคชันมือถือและเว็บ',
        logoObjectKey: null,
        provinceId: 90,
        provinceName: 'สงขลา',
        location: 'อาคาร A ถนนนิพัทธ์อุทิศ',
        websiteUrl: 'https://example.com',
        companySize: '201-500',
        perks: ['Mentor'],
        latitude: 7.0084,
        longitude: 100.4747,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyProfileRepositoryProvider.overrideWithValue(repo),
          thaiProvincesProvider.overrideWith((ref) async => _provinces),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompanyProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('สงขลา'), findsOneWidget);
    expect(find.text('อาคาร A ถนนนิพัทธ์อุทิศ'), findsOneWidget);
    expect(find.byType(OfficeMapPicker), findsOneWidget);
    expect(find.textContaining('พิกัด 7.008400, 100.474700'), findsOneWidget);

    await _tapSave(tester);
    await tester.pumpAndSettle();
    expect(repo.profile.provinceId, 90);
    expect(repo.profile.location, 'อาคาร A ถนนนิพัทธ์อุทิศ');
    expect(repo.profile.latitude, 7.0084);
    expect(repo.profile.longitude, 100.4747);
    expect(repo.profile.websiteUrl, 'https://example.com');
    expect(repo.profile.companySize, '201-500');
    expect(repo.profile.perks, ['Mentor']);
  });

  testWidgets('clearing province also clears the office pin', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeCompanyProfileRepository(
      profile: const CompanyProfile(
        name: 'Tech Solutions Co.',
        businessType: 'ซอฟต์แวร์',
        description: '',
        logoObjectKey: null,
        provinceId: 90,
        provinceName: 'สงขลา',
        latitude: 7.0084,
        longitude: 100.4747,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyProfileRepositoryProvider.overrideWithValue(repo),
          thaiProvincesProvider.overrideWith((ref) async => _provinces),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompanyProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('company-clear-province')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('company-clear-province')));
    await tester.pumpAndSettle();
    expect(find.byType(OfficeMapPicker), findsNothing);

    await _tapSave(tester);
    await tester.pumpAndSettle();
    expect(repo.profile.provinceId, isNull);
    expect(repo.profile.latitude, isNull);
    expect(repo.profile.longitude, isNull);
  });

  testWidgets('changing province re-centers map and drops the old office pin', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeCompanyProfileRepository(
      profile: const CompanyProfile(
        name: 'Tech Solutions Co.',
        businessType: 'ซอฟต์แวร์',
        description: '',
        logoObjectKey: null,
        provinceId: 90,
        provinceName: 'สงขลา',
        latitude: 7.0084,
        longitude: 100.4747,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyProfileRepositoryProvider.overrideWithValue(repo),
          thaiProvincesProvider.overrideWith((ref) async => _provinces),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompanyProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('company-province-picker')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('company-province-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('กรุงเทพมหานคร'));
    await tester.pumpAndSettle();

    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCenter.latitude, 13.7563);
    expect(map.options.initialCenter.longitude, 100.5018);
    expect(find.textContaining('หมุดเริ่มที่กึ่งกลางจังหวัด'), findsOneWidget);
    expect(find.textContaining('พิกัด 7.008400'), findsNothing);

    await _tapSave(tester);
    await tester.pumpAndSettle();
    expect(repo.profile.provinceId, 10);
    expect(repo.profile.latitude, isNull);
    expect(repo.profile.longitude, isNull);
  });

  testWidgets('logo update preserves unsaved form and office draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeCompanyProfileRepository(
      profile: const CompanyProfile(
        name: 'ชื่อเดิม',
        businessType: 'ประเภทเดิม',
        description: 'คำอธิบายเดิม',
        logoObjectKey: null,
        provinceId: 90,
        provinceName: 'สงขลา',
        location: 'ที่อยู่เดิม',
        latitude: 7.0084,
        longitude: 100.4747,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
        companyProfileRepositoryProvider.overrideWithValue(repo),
        thaiProvincesProvider.overrideWith((ref) async => _provinces),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompanyProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'ชื่อเดิม'),
      'ชื่อที่ยังไม่บันทึก',
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'คำอธิบายเดิม'),
      'คำอธิบายใหม่',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ที่อยู่เดิม'),
      'อาคารใหม่ ถนนสีลม',
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('company-province-picker')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('company-province-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('กรุงเทพมหานคร'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(OfficeMapPicker),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byType(OfficeMapPicker));
    await tester.drag(
      find.byKey(const Key('office-marker')),
      const Offset(60, 30),
    );
    await tester.pumpAndSettle();
    final draftPin = tester
        .widget<OfficeMapPicker>(find.byType(OfficeMapPicker))
        .pin;
    expect(draftPin, isNotNull);

    // A logo response still contains the previously saved office data.
    await container
        .read(companyProfileControllerProvider.notifier)
        .uploadLogo(filePath: '', fileName: 'logo.png', bytes: [1, 2, 3]);
    await tester.pumpAndSettle();

    expect(repo.uploadLogoCalls, 1);
    expect(repo.profile.provinceId, 90);
    expect(repo.profile.location, 'ที่อยู่เดิม');
    expect(repo.profile.logoObjectKey, isNotNull);
    expect(
      find.widgetWithText(TextFormField, 'ชื่อที่ยังไม่บันทึก'),
      findsOneWidget,
    );

    expect(find.widgetWithText(TextFormField, 'คำอธิบายใหม่'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'อาคารใหม่ ถนนสีลม'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.widgetWithText(TextFormField, 'อาคารใหม่ ถนนสีลม'),
      findsOneWidget,
    );
    expect(find.text('กรุงเทพมหานคร'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(OfficeMapPicker),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    final afterLogoPin = tester
        .widget<OfficeMapPicker>(find.byType(OfficeMapPicker))
        .pin;
    expect(afterLogoPin, draftPin);

    await _tapSave(tester);
    await tester.pumpAndSettle();
    expect(repo.lastUpdateRequest?.name, 'ชื่อที่ยังไม่บันทึก');
    expect(repo.lastUpdateRequest?.businessType, 'ประเภทเดิม');
    expect(repo.lastUpdateRequest?.description, 'คำอธิบายใหม่');
    expect(repo.lastUpdateRequest?.location, 'อาคารใหม่ ถนนสีลม');
    expect(repo.lastUpdateRequest?.provinceId, 10);
    expect(repo.lastUpdateRequest?.latitude, draftPin!.latitude);
    expect(repo.lastUpdateRequest?.longitude, draftPin.longitude);
  });

  testWidgets('successful save applies authoritative profile response', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _FakeCompanyProfileRepository(
      profile: mockProfile,
      updateResponse: (draft) => CompanyProfile(
        name: 'ชื่อจากเซิร์ฟเวอร์',
        businessType: 'ประเภทจากเซิร์ฟเวอร์',
        description: 'คำอธิบายจากเซิร์ฟเวอร์',
        logoObjectKey: draft.logoObjectKey,
        provinceId: 10,
        provinceName: 'กรุงเทพมหานคร',
        location: 'ที่อยู่จากเซิร์ฟเวอร์',
        latitude: 13.7563,
        longitude: 100.5018,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          companyProfileRepositoryProvider.overrideWithValue(repo),
          thaiProvincesProvider.overrideWith((ref) async => _provinces),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CompanyProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tech Solutions Co.'),
      'ชื่อที่ส่ง',
    );
    await _tapSave(tester);
    await tester.pumpAndSettle();

    expect(repo.lastUpdateRequest?.name, 'ชื่อที่ส่ง');
    expect(
      find.widgetWithText(TextFormField, 'ชื่อจากเซิร์ฟเวอร์'),
      findsOneWidget,
    );
    expect(repo.profile.businessType, 'ประเภทจากเซิร์ฟเวอร์');
    expect(
      find.widgetWithText(TextFormField, 'คำอธิบายจากเซิร์ฟเวอร์'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, 'ที่อยู่จากเซิร์ฟเวอร์'),
      findsOneWidget,
    );
    expect(find.text('กรุงเทพมหานคร'), findsOneWidget);
    expect(
      tester.widget<OfficeMapPicker>(find.byType(OfficeMapPicker)).pin,
      const LatLng(13.7563, 100.5018),
    );
  });
}

const _provinces = [
  ThaiProvince(
    id: 10,
    nameTh: 'กรุงเทพมหานคร',
    centerLatitude: 13.7563,
    centerLongitude: 100.5018,
    aliases: ['กทม.'],
  ),
  ThaiProvince(
    id: 90,
    nameTh: 'สงขลา',
    centerLatitude: 7.0084,
    centerLongitude: 100.4747,
  ),
];

Future<void> _tapSave(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('บันทึกโปรไฟล์'),
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('บันทึกโปรไฟล์'));
}

class _FakeCompanyProfileRepository implements CompanyProfileRepository {
  _FakeCompanyProfileRepository({required this.profile, this.updateResponse});

  CompanyProfile profile;
  final CompanyProfile Function(CompanyProfile)? updateResponse;
  CompanyProfile? lastUpdateRequest;
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
    lastUpdateRequest = updated;
    profile = updateResponse?.call(updated) ?? updated;
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
