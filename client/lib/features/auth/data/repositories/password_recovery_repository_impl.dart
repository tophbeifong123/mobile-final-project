import '../../domain/repositories/password_recovery_repository.dart';
import '../datasources/password_recovery_remote_data_source.dart';

class PasswordRecoveryRepositoryImpl implements PasswordRecoveryRepository {
  PasswordRecoveryRepositoryImpl(this.remote);

  final PasswordRecoveryRemoteDataSource remote;

  @override
  Future<void> requestPasswordReset({required String email}) =>
      remote.requestPasswordReset(email: email);

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) => remote.resetPassword(token: token, password: password);
}
