import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/auth/domain/entities/auth_session.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/presentation/providers/auth_controller.dart';
import 'package:client/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders Neo-Brutalist login screen with all elements matching design', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeAuthRepo = _FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Top Bar
    expect(find.text('เข้าสู่ระบบนักศึกษา'), findsOneWidget);

    // Hero Logo Badge Stickers
    expect(find.text('★ PRO'), findsOneWidget);
    expect(find.text('เวอร์ชัน 2.4'), findsOneWidget);

    // Greeting
    expect(find.text('ยินดีต้อนรับกลับมา!'), findsOneWidget);
    expect(
      find.text('พร้อมค้นหาตำแหน่งฝึกงานใหม่ๆ วันนี้หรือยัง?'),
      findsOneWidget,
    );

    // Form Labels & Helpers
    expect(find.text('อีเมลนักศึกษา / มหาวิทยาลัย'), findsOneWidget);
    expect(find.text('รหัสนักศึกษาหรืออีเมลมหาวิทยาลัย'), findsOneWidget);
    expect(find.text('รหัสผ่าน'), findsOneWidget);
    expect(find.text('ลืมรหัส PIN?'), findsOneWidget);

    // Checkbox & Forgot Password
    expect(find.text('จดจำฉันไว้ในระบบ'), findsOneWidget);
    expect(find.text('ลืมรหัสผ่าน?'), findsOneWidget);

    // Action button
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);

    // Divider
    expect(find.text('หรือเข้าสู่ระบบด้วย'), findsOneWidget);

    // Social buttons
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('GitHub'), findsOneWidget);

    // Bottom prompt & partner badge
    expect(find.text('ยังไม่มีบัญชีผู้ใช้?'), findsOneWidget);
    expect(find.text('ลงทะเบียนสมาชิก'), findsOneWidget);
    expect(
      find.text('เชื่อมต่อกับระบบมหาวิทยาลัยพันธมิตรกว่า 250+ แห่ง'),
      findsOneWidget,
    );
  });

  testWidgets('validates required fields on submit', (tester) async {
    tester.view.physicalSize = const Size(390, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeAuthRepo = _FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap submit without typing anything
    await tester.tap(find.text('เข้าสู่ระบบ'));
    await tester.pumpAndSettle();

    expect(find.text('กรอกอีเมลให้ถูกต้อง'), findsOneWidget);
    expect(find.text('กรอกรหัสผ่าน'), findsOneWidget);
    expect(fakeAuthRepo.loginCalls, 0);
  });

  testWidgets('submits valid credentials and shows error if login fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeAuthRepo = _FakeAuthRepository(shouldFail: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Type valid credentials
    final emailField = find.byType(TextFormField).first;
    final passwordField = find.byType(TextFormField).last;

    await tester.enterText(emailField, 'student@university.ac.th');
    await tester.enterText(passwordField, 'secret1234');

    await tester.tap(find.text('เข้าสู่ระบบ'));
    await tester.pumpAndSettle();

    expect(fakeAuthRepo.loginCalls, 1);
    expect(find.text('อีเมลหรือรหัสผ่านไม่ถูกต้อง'), findsOneWidget);
  });

  testWidgets('toggles remember me checkbox and password visibility', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeAuthRepo = _FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Remember me toggle
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.text('จดจำฉันไว้ในระบบ'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsNothing);

    // Visibility toggle
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.shouldFail = false});

  final bool shouldFail;
  int loginCalls = 0;

  @override
  Future<AuthSession?> restore() async => null;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    if (shouldFail) {
      throw const AppException('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
    }
    return const AuthSession(
      accessToken: 'test-token',
      refreshToken: 'test-refresh',
      role: UserRole.student,
    );
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    return const AuthSession(
      accessToken: 'test-token',
      refreshToken: 'test-refresh',
      role: UserRole.student,
    );
  }

  @override
  Future<void> logout() async {}
}
