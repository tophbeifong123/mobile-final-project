import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/password_recovery_email_policy.dart';
import '../../domain/entities/password_recovery_exception.dart';

class PasswordRecoveryRemoteDataSource {
  PasswordRecoveryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> requestPasswordReset({required String email}) =>
      _post(ApiConstants.forgotPassword, {'email': email.trim()}, reset: false);

  Future<void> resetPassword({
    required String token,
    required String password,
  }) => _post(ApiConstants.resetPassword, {
    'token': token,
    'password': password,
  }, reset: true);

  Future<void> _post(
    String path,
    Map<String, String> body, {
    required bool reset,
  }) async {
    try {
      await _dio.post<void>(
        path,
        data: body,
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
    } on DioException catch (error) {
      final responseData = error.response?.data;
      final passwordReuse =
          responseData is Map && responseData['code'] == 'PASSWORD_REUSE';
      if (reset &&
          (error.response?.statusCode == 409 ||
              (error.response?.statusCode == 400 && passwordReuse))) {
        throw const PasswordRecoveryException(
          'รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม',
        );
      }
      switch (error.response?.statusCode) {
        case 400:
          throw PasswordRecoveryException(
            reset
                ? 'ลิงก์รีเซ็ตรหัสผ่านไม่ถูกต้องหรือหมดอายุแล้ว กรุณาขอลิงก์ใหม่'
                : PasswordRecoveryEmailPolicy.invalidEmailMessage,
            invalidLink: reset,
          );
        case 429:
          final seconds = int.tryParse(
            error.response?.headers.value('retry-after') ?? '',
          );
          throw PasswordRecoveryException(
            'คุณส่งคำขอบ่อยเกินไป กรุณารอสักครู่แล้วลองใหม่',
            retryAfterSeconds: (seconds ?? 60).clamp(1, 3600),
          );
        case 503:
          throw const PasswordRecoveryException(
            'ระบบรีเซ็ตรหัสผ่านยังไม่พร้อมใช้งาน กรุณาลองใหม่ภายหลัง',
          );
        default:
          throw const PasswordRecoveryException(
            'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาลองใหม่อีกครั้ง',
          );
      }
    }
  }
}
