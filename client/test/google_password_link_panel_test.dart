import 'package:client/features/auth/presentation/widgets/google_password_link_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Google email and submits one password', (
    tester,
  ) async {
    String? submitted;
    var calls = 0;
    var cancelled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GooglePasswordLinkPanel(
            email: 'student@example.com',
            onSubmit: (password) async {
              calls++;
              submitted = password;
              return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
            },
            onCancel: () => cancelled = true,
          ),
        ),
      ),
    );

    expect(find.text('พบบัญชีนี้แล้ว'), findsOneWidget);
    expect(find.text('student@example.com'), findsWidgets);
    expect(find.text('รหัสผ่าน'), findsOneWidget);

    await tester.tap(find.text('เข้าสู่ระบบ'));
    await tester.pump();
    expect(calls, 0);
    expect(cancelled, isFalse);

    await tester.enterText(find.byType(TextFormField), 'password123');
    await tester.tap(find.text('เข้าสู่ระบบ'));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(submitted, 'password123');

    await tester.tap(find.text('กลับ'));
    await tester.pump();
    expect(cancelled, isTrue);
  });
}
