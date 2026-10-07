import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: AuthRemoteDataSource(ref.watch(dioProvider)),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() {
    return ref.watch(authRepositoryProvider).restore();
  }

  Future<String?> login({required String email, required String password}) {
    return _openSession(
      () => ref
          .read(authRepositoryProvider)
          .login(email: email, password: password),
    );
  }

  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) {
    return _openSession(
      () => ref
          .read(authRepositoryProvider)
          .register(
            fullName: fullName,
            email: email,
            password: password,
            role: role,
          ),
    );
  }

  Future<GoogleAuthResult> authenticateWithGoogle({
    required String idToken,
    UserRole? role,
  }) async {
    try {
      final roleRequired = await ref
          .read(authRepositoryProvider)
          .authenticateWithGoogle(idToken: idToken, role: role);
      if (!roleRequired) {
        state = await AsyncValue.guard(
          () => ref.read(authRepositoryProvider).restore(),
        );
      }
      return GoogleAuthResult(roleRequired: roleRequired);
    } on AppException catch (error) {
      return GoogleAuthResult(
        error: error.message,
        email: error.email,
        passwordLinkRequired: error.code == 'password_link_required',
      );
    } catch (_) {
      return const GoogleAuthResult(error: 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
    }
  }

  Future<String?> linkGoogle({
    required String idToken,
    required String password,
  }) {
    return _openSession(
      () => ref
          .read(authRepositoryProvider)
          .linkGoogle(idToken: idToken, password: password),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  /// Password recovery revokes server sessions. Finish any pending restore
  /// before clearing local state so it cannot restore the old session later.
  Future<void> clearLocalSession() async {
    if (state.isLoading) {
      try {
        await future;
      } catch (_) {
        // A failed restore also needs to become a signed-out session.
      }
    }
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }

  Future<String?> _openSession(Future<AuthSession> Function() request) async {
    try {
      final session = await request();
      state = AsyncData(session);
      return null;
    } on AppException catch (error) {
      return error.message;
    } catch (_) {
      return 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้';
    }
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

/// Account-scoped providers watch this. A new login replaces the cached
/// profile, feed, and applications instead of keeping the previous account.
final signedInSessionProvider = Provider<AuthSession?>((ref) {
  return ref.watch(authControllerProvider).asData?.value;
});
