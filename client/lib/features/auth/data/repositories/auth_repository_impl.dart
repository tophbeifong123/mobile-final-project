import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remote, required this.tokenStorage});

  final AuthRemoteDataSource remote;
  final TokenStorage tokenStorage;

  @override
  Future<AuthSession?> restore() => tokenStorage.read();

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final model = await remote.login(email: email, password: password);
    final session = model.toEntity();
    await tokenStorage.write(session);
    return session;
  }

  @override
  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final model = await remote.register(
      fullName: fullName,
      email: email,
      password: password,
      role: role.name,
    );
    final session = model.toEntity();
    await tokenStorage.write(session);
    return session;
  }

  @override
  Future<bool> authenticateWithGoogle({
    required String idToken,
    UserRole? role,
  }) async {
    final response = await remote.authenticateWithGoogle(
      idToken: idToken,
      role: role?.name,
    );
    final model = response.session;
    if (model == null) {
      return response.roleRequired;
    }
    await tokenStorage.write(model.toEntity());
    return false;
  }

  @override
  Future<AuthSession> linkGoogle({
    required String idToken,
    required String password,
  }) async {
    final model = await remote.linkGoogle(idToken: idToken, password: password);
    final session = model.toEntity();
    await tokenStorage.write(session);
    return session;
  }

  @override
  Future<void> logout() async {
    try {
      await remote.logout();
    } finally {
      await tokenStorage.clear();
    }
  }
}
