import 'package:client/core/error/app_exception.dart';
import 'package:client/core/network/dio_client.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/core/theme/app_theme.dart';
import 'package:client/features/auth/domain/entities/auth_session.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/presentation/providers/auth_controller.dart';
import 'package:client/features/auth/presentation/screens/login_screen.dart';
import 'package:client/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'renders Neo-Brutalist login screen with all elements matching design',
    (tester) async {
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
      expect(find.text('เข้าสู่ระบบ InternFinder'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบนักศึกษา'), findsNothing);

      // Form Labels & Helpers
      expect(find.text('อีเมล'), findsOneWidget);
      expect(find.text('อีเมลที่ใช้สมัครสมาชิก'), findsOneWidget);
      expect(find.text('you@example.com'), findsOneWidget);
      expect(find.text('อีเมลนักศึกษา / มหาวิทยาลัย'), findsNothing);
      expect(find.text('รหัสนักศึกษาหรืออีเมลมหาวิทยาลัย'), findsNothing);
      expect(find.text('รหัสผ่าน'), findsOneWidget);
      expect(find.textContaining('PIN'), findsNothing);

      // Checkbox & Forgot Password
      expect(find.text('จดจำฉันไว้ในระบบ'), findsOneWidget);
      expect(find.text('ลืมรหัสผ่าน?'), findsOneWidget);

      // Action button
      expect(find.text('เข้าสู่ระบบ'), findsOneWidget);

      // Divider
      expect(find.text('หรือเข้าสู่ระบบด้วย'), findsOneWidget);

      // Social buttons
      expect(find.text('เข้าสู่ระบบด้วย Google'), findsOneWidget);
      expect(find.text('GitHub'), findsNothing);

      // Bottom prompt & partner badge
      expect(find.text('ยังไม่มีบัญชีผู้ใช้?'), findsOneWidget);
      expect(find.text('ลงทะเบียนสมาชิก'), findsOneWidget);
      expect(
        find.text('เชื่อมต่อกับระบบมหาวิทยาลัยพันธมิตรกว่า 250+ แห่ง'),
        findsOneWidget,
      );
    },
  );

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

    // Verify error text appears below the input area
    final emailFieldCenter = tester.getCenter(find.byType(TextFormField).first);
    final emailErrorTop = tester.getTopLeft(find.text('กรอกอีเมลให้ถูกต้อง'));
    expect(emailErrorTop.dy, greaterThan(emailFieldCenter.dy));

    final passwordFieldCenter = tester.getCenter(
      find.byType(TextFormField).last,
    );
    final passwordErrorTop = tester.getTopLeft(find.text('กรอกรหัสผ่าน'));
    expect(passwordErrorTop.dy, greaterThan(passwordFieldCenter.dy));
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

  for (final email in [
    'student+intern@email.psu.ac.th',
    'company@example.com',
  ]) {
    testWidgets('forgot password opens the reset request form with $email', (
      tester,
    ) async {
      final fakeAuthRepo = _FakeAuthRepository();
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
          GoRoute(
            path: '/forgot-password',
            builder: (_, state) => ForgotPasswordScreen(
              initialEmail: state.uri.queryParameters['email'] ?? '',
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, email);
      await tester.tap(find.text('ลืมรหัสผ่าน?'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/forgot-password',
      );
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.text('ส่งลิงก์รีเซ็ตรหัสผ่าน'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        email,
      );
    });
  }

  for (final role in UserRole.values) {
    testWidgets(
      'shared login opens a ${role.name} session with unchanged credentials',
      (tester) async {
        final repository = _FakeAuthRepository(role: role);
        final container = ProviderContainer(
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            authRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const LoginScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final email = '${role.name}@example.com';
        await tester.enterText(find.byType(TextFormField).first, ' $email ');
        await tester.enterText(find.byType(TextFormField).last, 'secret1234');
        await tester.tap(find.text('เข้าสู่ระบบ'));
        await tester.pumpAndSettle();
        expect(repository.loginCalls, 1);
        expect(repository.lastEmail, email);
        expect(repository.lastPassword, 'secret1234');
        expect(container.read(authControllerProvider).value?.role, role);
        expect(find.textContaining('PIN'), findsNothing);
      },
    );
  }
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.shouldFail = false, this.role = UserRole.student});

  final bool shouldFail;
  final UserRole role;
  int loginCalls = 0;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<AuthSession?> restore() async => null;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    lastEmail = email;
    lastPassword = password;
    if (shouldFail) {
      throw const AppException('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
    }
    return AuthSession(
      accessToken: 'test-token',
      refreshToken: 'test-refresh',
      role: role,
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
  Future<bool> authenticateWithGoogle({
    required String idToken,
    UserRole? role,
  }) async {
    throw const AppException('Not implemented in fake');
  }

  @override
  Future<AuthSession> linkGoogle({
    required String idToken,
    required String password,
  }) async {
    throw const AppException('Not implemented in fake');
  }

  @override
  Future<void> logout() async {}
}
