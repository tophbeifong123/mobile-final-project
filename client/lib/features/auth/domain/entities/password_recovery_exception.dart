import '../../../../core/error/app_exception.dart';

class PasswordRecoveryException extends AppException {
  const PasswordRecoveryException(
    super.message, {
    this.retryAfterSeconds,
    this.invalidLink = false,
  });

  final int? retryAfterSeconds;
  final bool invalidLink;
}
