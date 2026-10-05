import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/provinces/thai_province.dart';
import 'package:client/core/provinces/thai_provinces_provider.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/company_profile/domain/entities/company_profile.dart';
import 'package:client/features/company_profile/domain/repositories/company_profile_repository.dart';
import 'package:client/features/company_profile/data/models/company_profile_model.dart';
import 'package:client/features/company_profile/presentation/providers/company_profile_controller.dart';
import 'package:client/features/company_profile/presentation/screens/company_profile_screen.dart';
import 'package:client/features/company_profile/presentation/widgets/office_map_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const mockProfile = CompanyProfile(
    name: 'Tech Solutions Co.',
    businessType: 'ซอฟต์แวร์',
    description: 'พัฒนาแอปพลิเคชันมือถือและเว็บ',
    logoObjectKey: null,
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

    expect(model.toEntity().provinceId, 90);
    expect(model.toEntity().provinceName, 'สงขลา');
    expect(model.toEntity().location, 'อาคาร A ถนนนิพัทธ์อุทิศ');
    expect(model.toJson(), {
      'name': 'Tech Solutions Co.',
      'businessType': 'ซอฟต์แวร์',
      'description': '',
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
    expect(find.text('ข้อมูลบริษัทและที่ตั้งสำนักงาน'), findsOneWidget);
    expect(find.text('โลโก้บริษัท'), findsOneWidget);
    expect(find.text('ยังไม่มีโลโก้บริษัท'), findsOneWidget);
    expect(find.text('เลือกรูป'), findsOneWidget);

    expect(find.text('Tech Solutions Co.'), findsOneWidget);
    expect(find.text('ซอฟต์แวร์'), findsOneWidget);
    expect(find.text('พัฒนาแอปพลิเคชันมือถือและเว็บ'), findsOneWidget);

    expect(find.text('บันทึกโปรไฟล์'), findsOneWidget);
    expect(find.text('เลือกจังหวัด'), findsOneWidget);
    expect(find.text('ที่อยู่สำนักงาน (แบบสั้น)'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('ออกจากระบบ'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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
    await _tapSave(tester);
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

    await _tapSave(tester);
    await tester.pumpAndSettle();

    expect(repo.updateCalls, 1);
    expect(repo.profile.name, 'New Company Name');
    expect(repo.profile.businessType, 'เทคโนโลยี AI');
    expect(repo.profile.description, 'เชี่ยวชาญด้าน LLM และ Agent');
    expect(find.text('บันทึกโปรไฟล์แล้ว'), findsOneWidget);
  });

  testWidgets(
    'shows error state when fetching company profile fails and retry works',
    (tester) async {
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
      find.widgetWithText(TextFormField, 'ประเภทเดิม'),
      'ประเภทใหม่',
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
    await tester.pumpAndSettle();
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
    // Return to the form top without dragging the interactive office map.
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('มีโลโก้บริษัทแล้ว'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'ชื่อที่ยังไม่บันทึก'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'ประเภทใหม่'), findsOneWidget);
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
    expect(repo.lastUpdateRequest?.businessType, 'ประเภทใหม่');
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
    expect(
      find.widgetWithText(TextFormField, 'ประเภทจากเซิร์ฟเวอร์'),
      findsOneWidget,
    );
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
  await tester.pumpAndSettle();
  await tester.tap(find.text('บันทึกโปรไฟล์'));
}

class _FakeCompanyProfileRepository implements CompanyProfileRepository {
  _FakeCompanyProfileRepository({required this.profile, this.updateResponse});

  CompanyProfile profile;
  final CompanyProfile Function(CompanyProfile)? updateResponse;
  CompanyProfile? lastUpdateRequest;
  int updateCalls = 0;
  int uploadLogoCalls = 0;

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
    profile = CompanyProfile(
      name: profile.name,
      businessType: profile.businessType,
      description: profile.description,
      logoObjectKey: 'company-logos/user-1/$fileName',
      provinceId: profile.provinceId,
      provinceName: profile.provinceName,
      location: profile.location,
      latitude: profile.latitude,
      longitude: profile.longitude,
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
