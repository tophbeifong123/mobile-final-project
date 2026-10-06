abstract final class PasswordRecoveryEmailPolicy {
  static const invalidEmailMessage = 'กรอกอีเมลให้ถูกต้อง';

  static String? validate(String? value) {
    final email = value?.trim() ?? '';
    if (email.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return invalidEmailMessage;
    }
    return null;
  }
}
