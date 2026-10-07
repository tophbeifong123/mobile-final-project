import 'package:client/core/theme/app_theme.dart';
import 'package:client/core/widgets/neo_button.dart';
import 'package:client/features/company_profile/presentation/widgets/company_contact_links_editor.dart';
import 'package:client/features/student_profile/domain/entities/student_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('adds and edits contact rows after valid save', (tester) async {
    final harness = _EditorHarness();
    await _mount(tester, harness);

    await tester.tap(find.text('เพิ่มช่องทาง'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '+1 555 010 2020');
    await tester.enterText(find.byType(TextFormField).last, 'Recruiting');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(harness.links.single.value, '+1 555 010 2020');
    expect(find.text('Recruiting'), findsOneWidget);

    await tester.tap(find.byTooltip('แก้ไข'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '+1 555 010 3030');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(harness.links.single.value, '+1 555 010 3030');
    expect(find.text('+1 555 010 3030'), findsOneWidget);
  });

  testWidgets('cancel leaves existing contact and save callback unchanged', (
    tester,
  ) async {
    final original = const ContactLink(
      id: 'saved-id',
      platform: 'phone',
      label: 'ฝ่ายบุคคล',
      value: '0812345678',
    );
    final harness = _EditorHarness(links: [original]);
    await _mount(tester, harness);
    final callbackCount = harness.changeCalls;

    await tester.tap(find.byTooltip('แก้ไข'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '0899999999');
    await tester.tap(find.byKey(const Key('close-company-contact-dialog')));
    await tester.pumpAndSettle();

    expect(harness.links.single.value, '0812345678');
    expect(harness.links.single.id, 'saved-id');
    expect(harness.changeCalls, callbackCount);
  });

  testWidgets('invalid phone and email show field errors and block save', (
    tester,
  ) async {
    final harness = _EditorHarness();
    await _mount(tester, harness);
    await tester.tap(find.text('เพิ่มช่องทาง'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '123');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('เบอร์โทรศัพท์ไม่ถูกต้อง'), findsOneWidget);
    expect(harness.changeCalls, 0);

    await tester.enterText(
      find.byType(TextFormField).first,
      'person@example.com',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('อีเมล').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'bad-email');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('อีเมลติดต่อไม่ถูกต้อง'), findsOneWidget);
    expect(harness.changeCalls, 0);

    await tester.enterText(
      find.byType(TextFormField).first,
      'person@example.com',
    );
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(harness.links.single.platform, 'email');
    expect(harness.links.single.value, 'person@example.com');
  });

  testWidgets('optional label accepts 100 and rejects 101 characters', (
    tester,
  ) async {
    final harness = _EditorHarness();
    await _mount(tester, harness);
    await tester.tap(find.text('เพิ่มช่องทาง'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '0812345678');
    await tester.enterText(find.byType(TextFormField).last, 'x' * 101);
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('ป้ายชื่อต้องไม่เกิน 100 ตัวอักษร'), findsOneWidget);
    expect(harness.changeCalls, 0);

    await tester.enterText(find.byType(TextFormField).last, 'x' * 100);
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(harness.links.single.label, 'x' * 100);
  });

  testWidgets('credentials and unsupported URL schemes are rejected', (
    tester,
  ) async {
    final harness = _EditorHarness();
    await _mount(tester, harness);
    await tester.tap(find.text('เพิ่มช่องทาง'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('อื่นๆ').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'https://user:pass@example.com',
    );
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ไม่มีชื่อผู้ใช้หรือรหัสผ่าน'), findsOneWidget);
    expect(harness.changeCalls, 0);

    await tester.enterText(
      find.byType(TextFormField).first,
      'ftp://example.com',
    );
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(harness.changeCalls, 0);

    await tester.enterText(
      find.byType(TextFormField).first,
      'https://example.com/careers',
    );
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(harness.links.single.value, 'https://example.com/careers');
  });

  testWidgets('both HTTP and HTTPS links are accepted', (tester) async {
    final harness = _EditorHarness();
    await _mount(tester, harness);

    for (final url in [
      'http://example.com/careers',
      'https://example.com/careers',
    ]) {
      await tester.tap(find.byKey(const Key('add-company-contact')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('อื่นๆ').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, url);
      await tester.tap(find.text('บันทึก'));
      await tester.pumpAndSettle();
    }

    expect(harness.links.map((link) => link.value), [
      'http://example.com/careers',
      'https://example.com/careers',
    ]);
  });

  testWidgets('7 contacts can become 8 and the add control is then disabled', (
    tester,
  ) async {
    final harness = _EditorHarness(
      links: [
        for (var i = 0; i < 7; i++)
          ContactLink(platform: 'other', value: 'Contact $i'),
      ],
    );
    await _mount(tester, harness);
    await tester.tap(find.byKey(const Key('add-company-contact')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'New contact');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(harness.links, hasLength(8));
    final addButton = tester.widget<NeoButton>(
      find.byKey(const Key('add-company-contact')),
    );
    expect(addButton.onPressed, isNull);
  });

  testWidgets('narrow dialog remains usable with validation text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = _EditorHarness();
    await _mount(tester, harness);
    await tester.tap(find.text('เพิ่มช่องทาง'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('กรอกข้อมูลติดต่อ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _mount(WidgetTester tester, _EditorHarness harness) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => CompanyContactLinksEditor(
            links: harness.links,
            onChanged: (links) => setState(() {
              harness.links = links;
              harness.changeCalls++;
            }),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _EditorHarness {
  _EditorHarness({List<ContactLink> links = const []}) : links = List.of(links);

  List<ContactLink> links;
  int changeCalls = 0;
}
