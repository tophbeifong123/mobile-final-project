import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/auth/domain/entities/auth_session.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/presentation/providers/auth_controller.dart';
import 'package:client/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'renders Neo-Brutalist register screen with all elements matching design',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1100);
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
          home: const RegisterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Top App Bar
    expect(find.text('ลงทะเบียนสมาชิก'), findsOneWidget);

    // Hero Section
    expect(find.text('ค้นหาและสมัครงานฝึกงานในฝันกับสตาร์ทอัพ\nและเทคคอมพานีชั้นนำ'), findsOneWidget);

    // Role switcher
    expect(find.text('นักศึกษา'), findsOneWidget);
    expect(find.text('บริษัท / องค์กร'), findsOneWidget);

    // Field headers
    expect(find.text('ชื่อ - นามสกุล'), findsOneWidget);
    expect(find.text('ตรงตามบัตร/รหัสนักศึกษา'), findsOneWidget);
    expect(find.text('อีเมลมหาวิทยาลัย'), findsOneWidget);
    expect(find.text('ตั้งรหัสผ่าน'), findsOneWidget);
    expect(find.text('อย่างน้อย 8 ตัวอักษร'), findsOneWidget);
    expect(find.text('ยืนยันรหัสผ่าน'), findsOneWidget);

    // Password strength
    expect(find.text('ระดับความปลอดภัย: '), findsOneWidget);
    expect(find.text('ยังไม่ปลอดภัย'), findsOneWidget);

    // Submit button
    expect(find.text('สร้างบัญชีผู้ใช้'), findsOneWidget);

    // Divider
    expect(find.text('หรือลงทะเบียนด้วย'), findsOneWidget);

    // Social buttons
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('SSO มหาวิทยาลัย'), findsOneWidget);

    // Footer
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
  });

  testWidgets('switching role updates email and name label context', (tester) async {
    tester.view.physicalSize = const Size(390, 1100);
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
          home: const RegisterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('อีเมลมหาวิทยาลัย'), findsOneWidget);
    expect(find.text('ตรงตามบัตร/รหัสนักศึกษา'), findsOneWidget);

    // Tap Company Role
    await tester.tap(find.text('บริษัท / องค์กร'));
    await tester.pumpAndSettle();

    expect(find.text('อีเมลบริษัท'), findsOneWidget);
    expect(find.text('ชื่อผู้ติดต่อ / บริษัท'), findsOneWidget);
  });

  testWidgets('validates required fields on submit', (tester) async {
    tester.view.physicalSize = const Size(390, 1100);
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
          home: const RegisterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap submit without typing anything
    await tester.tap(find.text('สร้างบัญชีผู้ใช้'));
    await tester.pumpAndSettle();

    expect(find.text('กรุณากรอกชื่อ - นามสกุล'), findsOneWidget);
    expect(find.text('กรุณากรอกอีเมล'), findsOneWidget);
    expect(find.text('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร'), findsOneWidget);
    expect(fakeAuthRepo.registerCalls, 0);
  });

  testWidgets('shows warning when terms are not agreed', (tester) async {
    tester.view.physicalSize = const Size(390, 1100);
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
          home: const RegisterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Fill all fields
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'กวิน รัตนพงษ์');
    await tester.enterText(textFields.at(1), 'student@university.ac.th');
    await tester.enterText(textFields.at(2), 'Password123!');
    await tester.enterText(textFields.at(3), 'Password123!');
    await tester.pumpAndSettle();

    // Submit without checking terms
    await tester.tap(find.text('สร้างบัญชีผู้ใช้'));
    await tester.pump();
    expect(find.text('กรุณายอมรับข้อกำหนดการให้บริการและนโยบายความเป็นส่วนตัว'), findsOneWidget);
    expect(fakeAuthRepo.registerCalls, 0);

    // Allow toast timer to complete
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('successfully registers student when valid and terms checked', (tester) async {
    tester.view.physicalSize = const Size(390, 1100);
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
          home: const RegisterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Fill all fields
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'กวิน รัตนพงษ์');
    await tester.enterText(textFields.at(1), 'student@university.ac.th');
    await tester.enterText(textFields.at(2), 'Password123!');
    await tester.enterText(textFields.at(3), 'Password123!');
    await tester.pumpAndSettle();

    // Check terms (the checkbox is the GestureDetector before terms text)
    final checkFinder = find.byType(GestureDetector);
    // Find the gesture detector with container width 22
    for (final element in checkFinder.evaluate()) {
      final widget = element.widget as GestureDetector;
      if (widget.child is Container) {
        final container = widget.child as Container;
        if (container.constraints?.maxWidth == 22 || (container.decoration is BoxDecoration && (container.decoration as BoxDecoration).borderRadius == BorderRadius.circular(6))) {
          await tester.tap(find.byWidget(widget));
          break;
        }
      }
    }
    await tester.pumpAndSettle();

    // Submit
    await tester.tap(find.text('สร้างบัญชีผู้ใช้'));
    await tester.pumpAndSettle();

    expect(fakeAuthRepo.registerCalls, 1);
    expect(fakeAuthRepo.lastRegisteredEmail, 'student@university.ac.th');
    expect(fakeAuthRepo.lastRegisteredRole, UserRole.student);
  });
}

class _FakeAuthRepository implements AuthRepository {
  int registerCalls = 0;
  String? lastRegisteredEmail;
  UserRole? lastRegisteredRole;

  @override
  Future<AuthSession?> restore() async => null;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    throw const AppException('Not implemented in fake');
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    registerCalls++;
    lastRegisteredEmail = email;
    lastRegisteredRole = role;
    return AuthSession(
      accessToken: 'test-token',
      refreshToken: 'refresh-token',
      role: role,
    );
  }

  @override
  Future<void> logout() async {}
}
