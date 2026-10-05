abstract class PasswordRecoveryRepository {
  Future<void> requestPasswordReset({required String email});

  Future<void> resetPassword({required String token, required String password});
}
