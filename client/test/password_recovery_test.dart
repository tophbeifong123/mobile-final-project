import 'dart:async';

import 'package:client/core/network/dio_client.dart';
import 'package:client/core/router/app_router.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/features/auth/domain/entities/auth_session.dart';
import 'package:client/features/auth/domain/entities/password_recovery_email_policy.dart';
import 'package:client/features/auth/domain/entities/password_recovery_exception.dart';
import 'package:client/features/auth/domain/repositories/auth_repository.dart';
import 'package:client/features/auth/domain/repositories/password_recovery_repository.dart';
import 'package:client/features/auth/presentation/providers/auth_controller.dart';
import 'package:client/features/auth/presentation/providers/password_recovery_controller.dart';
import 'package:client/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:client/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:client/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _token = List.filled(64, 'a').join();
const _session = AuthSession(
  accessToken: 'old-access',
  refreshToken: 'old-refresh',
  role: UserRole.student,
);

void main() {
  Future<ProviderContainer> openApp(
    WidgetTester tester, {
    required String location,
    required _FakeRecoveryRepository recovery,
    _FakeAuthRepository? auth,
    MemoryTokenStorage? storage,
  }) async {
    tester.view.physicalSize = const Size(390, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.binding.platformDispatcher.defaultRouteNameTestValue = location;
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    final container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage ?? MemoryTokenStorage()),
        authRepositoryProvider.overrideWithValue(auth ?? _FakeAuthRepository()),
        passwordRecoveryRepositoryProvider.overrideWithValue(recovery),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('email from login is prefilled; invalid emails do not call API', (
    tester,
  ) async {
    final repository = _FakeRecoveryRepository();
    await openApp(
      tester,
      location: '/forgot-password?email=student%2Bintern%40gmail.com',
      recovery: repository,
    );
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(find.textContaining('กรอกอีเมลที่ใช้สมัครสมาชิก'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'student+intern@gmail.com',
    );
    await tester.enterText(find.byType(TextFormField), 'invalid');
    await tester.tap(find.text('ส่งลิงก์รีเซ็ตรหัสผ่าน'));
    await tester.pumpAndSettle();
    expect(find.text('กรอกอีเมลให้ถูกต้อง'), findsOneWidget);
    expect(repository.requestCalls, 0);
  });

  for (final email in [
    'student@email.psu.ac.th',
    ' Student@EMAIL.PSU.AC.TH ',
    'staff@psu.ac.th',
    ' Staff@PSU.AC.TH ',
  ]) {
    testWidgets('sends recovery to the entered registered email: $email', (
      tester,
    ) async {
      final repository = _FakeRecoveryRepository();
      await openApp(tester, location: '/forgot-password', recovery: repository);
      await tester.enterText(find.byType(TextFormField), email);
      await tester.tap(find.text('ส่งลิงก์รีเซ็ตรหัสผ่าน'));
      await tester.pumpAndSettle();
      expect(repository.requestCalls, 1);
      expect(repository.lastEmail, email.trim());
      expect(
        find.text('หากอีเมลนี้มีบัญชีอยู่ ระบบจะส่งลิงก์รีเซ็ตรหัสผ่านให้คุณ'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final email in [
    'student@gmail.com',
    'student@outlook.com',
    'student@university.ac.th',
    'student@email.psu.ac.th.evil.example',
    'student@psu.ac.th.evil.example',
    'student@sub.email.psu.ac.th',
    'student@sub.psu.ac.th',
    'student@notemail.psu.ac.th',
    'student@notpsu.ac.th',
  ]) {
    testWidgets('accepts recovery outside PSU domains: $email', (tester) async {
      final repository = _FakeRecoveryRepository();
      await openApp(tester, location: '/forgot-password', recovery: repository);
      await tester.enterText(find.byType(TextFormField), email);
      await tester.tap(find.text('ส่งลิงก์รีเซ็ตรหัสผ่าน'));
      await tester.pumpAndSettle();
      expect(
        find.text('หากอีเมลนี้มีบัญชีอยู่ ระบบจะส่งลิงก์รีเซ็ตรหัสผ่านให้คุณ'),
        findsOneWidget,
      );
      expect(repository.requestCalls, 1);
      expect(repository.lastEmail, email);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final email in [
    '',
    'invalid',
    'user@@example.com',
    '@example.com',
    'user name@example.com',
  ]) {
    testWidgets('rejects malformed recovery email: $email', (tester) async {
      final repository = _FakeRecoveryRepository();
      await openApp(tester, location: '/forgot-password', recovery: repository);
      await tester.enterText(find.byType(TextFormField), email);
      await tester.tap(find.text('ส่งลิงก์รีเซ็ตรหัสผ่าน'));
      await tester.pumpAndSettle();
      expect(
        find.text(PasswordRecoveryEmailPolicy.invalidEmailMessage),
        findsOneWidget,
      );
      expect(repository.requestCalls, 0);
    });
  }

  testWidgets(
    'request prevents duplicates, shows generic success and cooldown',
    (tester) async {
      final request = Completer<void>();
      final repository = _FakeRecoveryRepository(requestCompleter: request);
      final container = await openApp(
        tester,
        location: '/forgot-password',
        recovery: repository,
      );
      await tester.enterText(
        find.byType(TextFormField),
        ' student@email.psu.ac.th ',
      );
      await tester.tap(find.text('ส่งลิงก์รีเซ็ตรหัสผ่าน'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(container.read(authControllerProvider).isLoading, isFalse);
      expect(repository.requestCalls, 1);
      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pump();
      expect(repository.requestCalls, 1);
      request.complete();
      await tester.pumpAndSettle();
      expect(repository.lastEmail, 'student@email.psu.ac.th');
      expect(
        find.text('หากอีเมลนี้มีบัญชีอยู่ ระบบจะส่งลิงก์รีเซ็ตรหัสผ่านให้คุณ'),
        findsOneWidget,
      );
      expect(find.text('ส่งอีกครั้งใน 60 วินาที'), findsOneWidget);
      await tester.tap(find.text('ส่งอีกครั้งใน 60 วินาที'));
      await tester.pump();
      expect(repository.requestCalls, 1);
      await tester.pump(const Duration(seconds: 60));
      expect(find.text('ส่งลิงก์อีกครั้ง'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'rate limits honor cooldown; mail failure stays on recovery page',
    (tester) async {
      final repository = _FakeRecoveryRepository(
        failure: const PasswordRecoveryException(
          'กรุณารอสักครู่แล้วลองใหม่',
          retryAfterSeconds: 3,
        ),
      );
      await openApp(tester, location: '/forgot-password', recovery: repository);
      await tester.enterText(
        find.byType(TextFormField),
        'student@email.psu.ac.th',
      );
      await tester.tap(find.text('ส่งลิงก์รีเซ็ตรหัสผ่าน'));
      await tester.pumpAndSettle();
      expect(find.text('กรุณารอสักครู่แล้วลองใหม่'), findsOneWidget);
      expect(find.text('ส่งอีกครั้งใน 3 วินาที'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      repository.failure = const PasswordRecoveryException(
        'ระบบรีเซ็ตรหัสผ่านยังไม่พร้อมใช้งาน กรุณาลองใหม่ภายหลัง',
      );
      await tester.tap(find.text('ส่งลิงก์รีเซ็ตรหัสผ่าน'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(
        find.text('ระบบรีเซ็ตรหัสผ่านยังไม่พร้อมใช้งาน กรุณาลองใหม่ภายหลัง'),
        findsOneWidget,
      );
      expect(repository.requestCalls, 2);
    },
  );

  testWidgets('direct reset token survives pending session restore', (
    tester,
  ) async {
    final restore = Completer<AuthSession?>();
    final container = await openApp(
      tester,
      location: '/reset-password?token=$_token',
      recovery: _FakeRecoveryRepository(),
      auth: _FakeAuthRepository(restoreCompleter: restore),
    );
    expect(container.read(authControllerProvider).isLoading, isTrue);
    expect(find.byType(ResetPasswordScreen), findsOneWidget);
    expect(
      container
          .read(goRouterProvider)
          .routeInformationProvider
          .value
          .uri
          .queryParameters['token'],
      _token,
    );
    expect(find.textContaining(_token), findsNothing);
    restore.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('รหัสผ่านใหม่'), findsOneWidget);
  });

  testWidgets('password length, UTF-8 limit and confirmation guard API', (
    tester,
  ) async {
    final repository = _FakeRecoveryRepository();
    await openApp(
      tester,
      location: '/reset-password?token=$_token',
      recovery: repository,
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'short');
    await tester.enterText(fields.last, 'different');
    await tester.tap(find.text('บันทึกรหัสผ่านใหม่'));
    await tester.pumpAndSettle();
    expect(find.text('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร'), findsOneWidget);
    expect(find.text('รหัสผ่านทั้งสองช่องไม่ตรงกัน'), findsOneWidget);
    final tooLong = List.filled(25, 'ก').join();
    await tester.enterText(fields.first, tooLong);
    await tester.enterText(fields.last, tooLong);
    await tester.tap(find.text('บันทึกรหัสผ่านใหม่'));
    await tester.pumpAndSettle();
    expect(
      find.text('รหัสผ่านยาวเกินไป กรุณาใช้รหัสผ่านที่สั้นลง'),
      findsOneWidget,
    );
    expect(repository.resetCalls, 0);
    final passwordInput = find.descendant(
      of: fields.first,
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(passwordInput).obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined).first);
    await tester.pump();
    expect(tester.widget<TextField>(passwordInput).obscureText, isFalse);
  });

  testWidgets('minimum password length counts Unicode characters', (
    tester,
  ) async {
    final repository = _FakeRecoveryRepository();
    await openApp(
      tester,
      location: '/reset-password?token=$_token',
      recovery: repository,
    );
    final fields = find.byType(TextFormField);
    final fourEmojis = List.filled(4, '🔐').join();
    await tester.enterText(fields.first, fourEmojis);
    await tester.enterText(fields.last, fourEmojis);
    await tester.tap(find.text('บันทึกรหัสผ่านใหม่'));
    await tester.pumpAndSettle();
    expect(find.text('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร'), findsOneWidget);
    expect(repository.resetCalls, 0);

    final eightEmojis = List.filled(8, '🔐').join();
    await tester.enterText(fields.first, eightEmojis);
    await tester.enterText(fields.last, eightEmojis);
    await tester.tap(find.text('บันทึกรหัสผ่านใหม่'));
    await tester.pumpAndSettle();
    expect(repository.resetCalls, 1);
    expect(repository.lastPassword, eightEmojis);
    expect(find.text('เรียบร้อยแล้ว!'), findsOneWidget);
  });

  for (final token in ['', 'invalid-token']) {
    testWidgets('missing/malformed reset link offers a new link ($token)', (
      tester,
    ) async {
      final repository = _FakeRecoveryRepository();
      await openApp(
        tester,
        location: '/reset-password?token=$token',
        recovery: repository,
      );
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('ขอลิงก์รีเซ็ตใหม่'), findsOneWidget);
      await tester.tap(find.text('ขอลิงก์รีเซ็ตใหม่'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(repository.resetCalls, 0);
    });
  }

  testWidgets('expired token error offers recovery without exposing token', (
    tester,
  ) async {
    final repository = _FakeRecoveryRepository(
      failure: const PasswordRecoveryException(
        'ลิงก์รีเซ็ตรหัสผ่านไม่ถูกต้องหรือหมดอายุแล้ว กรุณาขอลิงก์ใหม่',
        invalidLink: true,
      ),
    );
    await openApp(
      tester,
      location: '/reset-password?token=$_token',
      recovery: repository,
    );
    await tester.enterText(find.byType(TextFormField).first, 'new-secret-123');
    await tester.enterText(find.byType(TextFormField).last, 'new-secret-123');
    await tester.tap(find.text('บันทึกรหัสผ่านใหม่'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('ขอลิงก์รีเซ็ตใหม่'), findsOneWidget);
    expect(find.textContaining(_token), findsNothing);
  });

  testWidgets(
    'reused password keeps reset form and token available for retry',
    (tester) async {
      final repository = _FakeRecoveryRepository(
        failure: const PasswordRecoveryException(
          'รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม',
        ),
      );
      final container = await openApp(
        tester,
        location: '/reset-password?token=$_token',
        recovery: repository,
      );
      expect(find.textContaining('ต้องไม่ซ้ำกับรหัสผ่านเดิม'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'old-secret-123');
      await tester.enterText(fields.last, 'old-secret-123');
      await tester.tap(find.text('บันทึกรหัสผ่านใหม่'));
      await tester.pumpAndSettle();
      expect(
        find.text('รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม'),
        findsOneWidget,
      );
      expect(fields, findsNWidgets(2));
      expect(
        container
            .read(goRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .queryParameters['token'],
        _token,
      );
      expect(
        tester.widget<TextFormField>(fields.first).controller!.text,
        'old-secret-123',
      );
      repository.failure = null;
      await tester.enterText(fields.first, 'different-secret-123');
      await tester.enterText(fields.last, 'different-secret-123');
      await tester.tap(find.text('บันทึกรหัสผ่านใหม่'));
      await tester.pumpAndSettle();
      expect(repository.resetCalls, 2);
      expect(repository.lastToken, _token);
      expect(repository.lastPassword, 'different-secret-123');
      expect(find.text('เรียบร้อยแล้ว!'), findsOneWidget);
    },
  );

  testWidgets('signed-in reset clears old local session and token URL', (
    tester,
  ) async {
    final storage = MemoryTokenStorage();
    await storage.write(_session);
    final repository = _FakeRecoveryRepository();
    final container = await openApp(
      tester,
      location: '/reset-password?token=$_token',
      recovery: repository,
      auth: _FakeAuthRepository(session: _session),
      storage: storage,
    );
    expect(container.read(authControllerProvider).value, _session);
    await tester.enterText(find.byType(TextFormField).first, 'new-secret-123');
    await tester.enterText(find.byType(TextFormField).last, 'new-secret-123');
    await tester.tap(find.text('บันทึกรหัสผ่านใหม่'));
    await tester.pumpAndSettle();
    expect(repository.resetCalls, 1);
    expect(repository.lastToken, _token);
    expect(repository.lastPassword, 'new-secret-123');
    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
    expect(container.read(authControllerProvider).value, isNull);
    expect(
      find.text('ตั้งรหัสผ่านใหม่เรียบร้อยแล้ว กรุณาเข้าสู่ระบบอีกครั้ง'),
      findsOneWidget,
    );
    expect(
      container
          .read(goRouterProvider)
          .routeInformationProvider
          .value
          .uri
          .queryParameters['token'],
      isNull,
    );
    await tester.tap(find.text('เข้าสู่ระบบด้วยรหัสผ่านใหม่'));
    await tester.pumpAndSettle();
    expect(find.text('เข้าสู่ระบบ InternFinder'), findsOneWidget);
  });

  testWidgets('reset finishing before restore cannot resurrect old session', (
    tester,
  ) async {
    final restore = Completer<AuthSession?>();
    final storage = MemoryTokenStorage();
    await storage.write(_session);
    final container = await openApp(
      tester,
      location: '/reset-password?token=$_token',
      recovery: _FakeRecoveryRepository(),
      auth: _FakeAuthRepository(restoreCompleter: restore),
      storage: storage,
    );
    await tester.enterText(find.byType(TextFormField).first, 'new-secret-123');
    await tester.enterText(find.byType(TextFormField).last, 'new-secret-123');
    await tester.tap(find.text('บันทึกรหัสผ่านใหม่'));
    await tester.pump();
    restore.complete(_session);
    await tester.pumpAndSettle();
    expect(container.read(authControllerProvider).value, isNull);
    expect(storage.accessToken, isNull);
    expect(find.text('เรียบร้อยแล้ว!'), findsOneWidget);
  });
}

class _FakeRecoveryRepository implements PasswordRecoveryRepository {
  _FakeRecoveryRepository({this.requestCompleter, this.failure});

  final Completer<void>? requestCompleter;
  PasswordRecoveryException? failure;
  int requestCalls = 0;
  int resetCalls = 0;
  String? lastEmail;
  String? lastToken;
  String? lastPassword;

  @override
  Future<void> requestPasswordReset({required String email}) async {
    requestCalls++;
    lastEmail = email;
    if (failure != null) throw failure!;
    await requestCompleter?.future;
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    resetCalls++;
    lastToken = token;
    lastPassword = password;
    if (failure != null) throw failure!;
  }
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.restoreCompleter, this.session});

  final Completer<AuthSession?>? restoreCompleter;
  final AuthSession? session;

  @override
  Future<AuthSession?> restore() =>
      restoreCompleter?.future ?? Future.value(session);

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required UserRole role,
  }) async => throw UnimplementedError();

  @override
  Future<void> logout() async {}
}
