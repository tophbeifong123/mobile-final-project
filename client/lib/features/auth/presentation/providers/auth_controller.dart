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

  Future<String?> login({
    required String email,
    required String password,
  }) {
    return _openSession(
      () => ref.read(authRepositoryProvider).login(
        email: email,
        password: password,
      ),
    );
  }

  Future<String?> register({
    required String email,
    required String password,
    required UserRole role,
  }) {
    return _openSession(
      () => ref.read(authRepositoryProvider).register(
        email: email,
        password: password,
        role: role,
      ),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
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
