import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/auth/domain/entities/auth_session.dart';
import 'package:client/features/auth/domain/entities/registration_password_policy.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/presentation/providers/auth_controller.dart';
import 'package:client/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final entry in <String, bool>{
    'abcdefg': false,
    'abcdefgh': true,
    List.filled(72, 'a').join(): true,
    List.filled(73, 'a').join(): false,
    List.filled(24, 'ก').join(): true,
    List.filled(25, 'ก').join(): false,
    List.filled(4, '🔐').join(): false,
    List.filled(8, '🔐').join(): true,
    List.filled(18, '🔐').join(): true,
    List.filled(19, '🔐').join(): false,
  }.entries) {
    test('Unicode/UTF-8 password boundary: ${entry.key}', () {
      expect(
        RegistrationPasswordPolicy(entry.key, entry.key).passwordError == null,
        entry.value,
      );
    });
  }

  Future<_AuthRepository> openRegister(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _AuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RegisterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  Future<void> prepareOtherFields(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'person@example.com',
    );
    final checkbox = find.byWidgetPredicate(
      (widget) =>
          widget is GestureDetector &&
          widget.child is Container &&
          (widget.child as Container).constraints?.maxWidth == 22,
    );
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.ensureVisible(find.text('สร้างบัญชีผู้ใช้'));
    await tester.tap(find.text('สร้างบัญชีผู้ใช้'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'checklist changes live and rechecks confirmation when password changes',
    (tester) async {
      await openRegister(tester);
      final password = find.byType(TextFormField).at(2);
      final confirmation = find.byType(TextFormField).at(3);
      expect(find.text('ยังขาด: อย่างน้อย 8 ตัวอักษร'), findsOneWidget);
      expect(find.text('ผ่านแล้ว: ไม่เกิน 72 ไบต์ (UTF-8)'), findsOneWidget);
      expect(find.text('ยังขาด: ยืนยันรหัสผ่านตรงกัน'), findsOneWidget);
      await tester.enterText(password, 'abcdefgh');
      await tester.pump();
      expect(find.text('ผ่านแล้ว: อย่างน้อย 8 ตัวอักษร'), findsOneWidget);
      await tester.enterText(confirmation, 'different');
      await tester.pump();
      expect(find.text('ยังขาด: ยืนยันรหัสผ่านตรงกัน'), findsOneWidget);
      await tester.enterText(confirmation, 'abcdefgh');
      await tester.pump();
      expect(find.text('ผ่านแล้ว: ยืนยันรหัสผ่านตรงกัน'), findsOneWidget);
      await tester.enterText(password, 'abcdefghx');
      await tester.pump();
      expect(find.text('ยังขาด: ยืนยันรหัสผ่านตรงกัน'), findsOneWidget);
      await tester.enterText(password, List.filled(25, 'ก').join());
      await tester.pump();
      expect(find.text('ยังขาด: ไม่เกิน 72 ไบต์ (UTF-8)'), findsOneWidget);
      await tester.enterText(password, List.filled(4, '🔐').join());
      await tester.pump();
      expect(find.text('ยังขาด: อย่างน้อย 8 ตัวอักษร'), findsOneWidget);
      expect(find.textContaining('ระดับความปลอดภัย'), findsNothing);
    },
  );

  for (final password in [
    'short',
    List.filled(73, 'a').join(),
    List.filled(25, 'ก').join(),
    List.filled(19, '🔐').join(),
  ]) {
    testWidgets(
      'invalid password stays visible and blocks submission: $password',
      (tester) async {
        final repository = await openRegister(tester);
        await prepareOtherFields(tester);
        await tester.enterText(find.byType(TextFormField).at(2), password);
        await tester.enterText(find.byType(TextFormField).at(3), password);
        await submit(tester);
        expect(repository.calls, 0);
        expect(
          find.text(
            RegistrationPasswordPolicy(password, password).passwordError!,
          ),
          findsOneWidget,
        );
        expect(find.textContaining('ยังขาด:'), findsOneWidget);
        expect(find.text('ผ่านแล้ว: ยืนยันรหัสผ่านตรงกัน'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'mismatch blocks submission; correcting it permits signup without extra criteria',
    (tester) async {
      final repository = await openRegister(tester);
      await prepareOtherFields(tester);
      await tester.enterText(find.byType(TextFormField).at(2), 'abcdefgh');
      await tester.enterText(find.byType(TextFormField).at(3), 'different');
      await submit(tester);
      expect(repository.calls, 0);
      expect(find.text('รหัสผ่านทั้งสองช่องไม่ตรงกัน'), findsOneWidget);
      expect(find.text('ยังขาด: ยืนยันรหัสผ่านตรงกัน'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(3), 'abcdefgh');
      await tester.pump();
      expect(find.text('รหัสผ่านทั้งสองช่องไม่ตรงกัน'), findsNothing);
      expect(find.text('ผ่านแล้ว: ยืนยันรหัสผ่านตรงกัน'), findsOneWidget);
      await submit(tester);
      expect(repository.calls, 1);
      expect(repository.password, 'abcdefgh');
    },
  );

  for (final password in [
    List.filled(72, 'a').join(),
    List.filled(24, 'ก').join(),
    List.filled(18, '🔐').join(),
  ]) {
    testWidgets('company signup accepts exact 72-byte boundary: $password', (
      tester,
    ) async {
      final repository = await openRegister(tester);
      await tester.tap(find.text('บริษัท / องค์กร'));
      await prepareOtherFields(tester);
      await tester.enterText(find.byType(TextFormField).at(2), password);
      await tester.enterText(find.byType(TextFormField).at(3), password);
      await tester.pump();
      expect(find.textContaining('ยังขาด:'), findsNothing);
      await submit(tester);
      expect(repository.calls, 1);
      expect(repository.password, password);
      expect(repository.role, UserRole.company);
    });
  }
}

class _AuthRepository implements AuthRepository {
  int calls = 0;
  String? password;
  UserRole? role;
  @override
  Future<AuthSession?> restore() async => null;
  @override
  Future<void> logout() async {}
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => throw UnimplementedError();
  @override
  Future<bool> authenticateWithGoogle({
    required String idToken,
    UserRole? role,
  }) async => throw UnimplementedError();
  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    calls++;
    this.password = password;
    this.role = role;
    return AuthSession(
      accessToken: 'test-access',
      refreshToken: 'test-refresh',
      role: role,
    );
  }
}
