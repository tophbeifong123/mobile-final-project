import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession?> restore();

  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession> register({
    required String email,
    required String password,
    required UserRole role,
  });

  Future<void> logout();
}
