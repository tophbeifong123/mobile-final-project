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
    'abcdefgh': false,
    'Abcdef1!': true,
    'Aa1!${List.filled(68, 'a').join()}': true,
    List.filled(73, 'a').join(): false,
    'Aa1!${List.filled(22, 'ก').join()}aa': true,
    List.filled(25, 'ก').join(): false,
    List.filled(4, '🔐').join(): false,
    List.filled(8, '🔐').join(): false,
    'Aa1!${List.filled(17, '🔐').join()}': true,
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
    'compact guidance updates live and confirmation errors stay under field',
    (tester) async {
      await openRegister(tester);
      final password = find.byType(TextFormField).at(2);
      final confirmation = find.byType(TextFormField).at(3);
      expect(
        find.text('อย่างน้อย 8 ตัว มี A–Z, a–z, ตัวเลข และสัญลักษณ์'),
        findsOneWidget,
      );
      expect(find.textContaining('เพิ่มอีก:'), findsNothing);
      expect(find.text('รหัสผ่านทั้งสองช่องไม่ตรงกัน'), findsNothing);
      expect(find.textContaining('ไบต์ (UTF-8)'), findsNothing);

      await tester.enterText(password, 'abcdefgh');
      await tester.pump();
      expect(
        find.text('เพิ่มอีก: ตัวพิมพ์ใหญ่ A–Z, ตัวเลข, สัญลักษณ์ เช่น ! @ #'),
        findsOneWidget,
      );
      await tester.enterText(password, 'Abcdef1!');
      await tester.pump();
      expect(find.textContaining('เพิ่มอีก:'), findsNothing);

      await tester.enterText(confirmation, 'different');
      await tester.pump();
      expect(find.text('รหัสผ่านทั้งสองช่องไม่ตรงกัน'), findsOneWidget);
      await tester.enterText(confirmation, 'Abcdef1!');
      await tester.pump();
      expect(find.text('รหัสผ่านทั้งสองช่องไม่ตรงกัน'), findsNothing);
      await tester.enterText(password, 'Abcdef1!x');
      await tester.pump();
      expect(find.text('รหัสผ่านทั้งสองช่องไม่ตรงกัน'), findsOneWidget);

      await tester.enterText(password, '');
      await tester.pump();
      expect(find.textContaining('เพิ่มอีก:'), findsNothing);
      expect(find.textContaining('ผ่านแล้ว:'), findsNothing);
      expect(find.textContaining('ยังขาด:'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final password in [
    'short',
    'abcdef1!',
    'ABCDEF1!',
    'Abcdefg!',
    'Abcdef12',
    'Abcdef1 ',
    'Aa1!${List.filled(69, 'a').join()}',
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
        expect(
          find.textContaining('เพิ่มอีก:'),
          password.startsWith('Aa1!') ? findsNothing : findsOneWidget,
        );
        expect(find.text('รหัสผ่านทั้งสองช่องไม่ตรงกัน'), findsNothing);
      },
    );
  }

  testWidgets(
    'mismatch blocks submission; correcting a valid password permits signup',
    (tester) async {
      final repository = await openRegister(tester);
      await prepareOtherFields(tester);
      await tester.enterText(find.byType(TextFormField).at(2), 'Abcdef1!');
      await tester.enterText(find.byType(TextFormField).at(3), 'different');
      await submit(tester);
      expect(repository.calls, 0);
      expect(find.text('รหัสผ่านทั้งสองช่องไม่ตรงกัน'), findsOneWidget);
      expect(find.textContaining('ยังขาด:'), findsNothing);
      await tester.enterText(find.byType(TextFormField).at(3), 'Abcdef1!');
      await tester.pump();
      expect(find.text('รหัสผ่านทั้งสองช่องไม่ตรงกัน'), findsNothing);
      expect(find.textContaining('ผ่านแล้ว:'), findsNothing);
      await submit(tester);
      expect(repository.calls, 1);
      expect(repository.password, 'Abcdef1!');
    },
  );

  for (final password in [
    'Aa1!${List.filled(68, 'a').join()}',
    'Aa1!${List.filled(22, 'ก').join()}aa',
    'Aa1!${List.filled(17, '🔐').join()}',
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
