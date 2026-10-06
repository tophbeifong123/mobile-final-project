import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/password_recovery_remote_data_source.dart';
import '../../data/repositories/password_recovery_repository_impl.dart';
import '../../domain/entities/password_recovery_exception.dart';
import '../../domain/repositories/password_recovery_repository.dart';
import 'auth_controller.dart';

final passwordRecoveryRepositoryProvider = Provider<PasswordRecoveryRepository>(
  (ref) => PasswordRecoveryRepositoryImpl(
    PasswordRecoveryRemoteDataSource(ref.watch(dioProvider)),
  ),
);

// Recovery requests never change the login/loading state used by the router.
final forgotPasswordControllerProvider =
    NotifierProvider.autoDispose<PasswordRecoveryController, AsyncValue<void>>(
      PasswordRecoveryController.new,
    );
final resetPasswordControllerProvider =
    NotifierProvider.autoDispose<PasswordRecoveryController, AsyncValue<void>>(
      PasswordRecoveryController.new,
    );

class PasswordRecoveryController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> requestPasswordReset(String email) => _run(
    () => ref
        .read(passwordRecoveryRepositoryProvider)
        .requestPasswordReset(email: email),
  );

  Future<bool> resetPassword(String token, String password) {
    final repository = ref.read(passwordRecoveryRepositoryProvider);
    final auth = ref.read(authControllerProvider.notifier);
    return _run(() async {
      await repository.resetPassword(token: token, password: password);
      await auth.clearLocalSession();
    });
  }

  Future<bool> _run(Future<void> Function() request) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    try {
      await request();
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) {
        state = AsyncError(
          error is PasswordRecoveryException
              ? error
              : const PasswordRecoveryException(
                  'ทำรายการไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
                ),
          stack,
        );
      }
      return false;
    }
  }
}
