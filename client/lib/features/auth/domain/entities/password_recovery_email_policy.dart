abstract final class PasswordRecoveryEmailPolicy {
  static const allowedDomains = {'email.psu.ac.th', 'psu.ac.th'};
  static const allowedDomainMessage =
      'ใช้ได้เฉพาะอีเมล @email.psu.ac.th หรือ @psu.ac.th ที่ใช้สมัครสมาชิก';

  static String? validate(String? value) {
    final email = value?.trim() ?? '';
    if (email.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'กรอกอีเมลให้ถูกต้อง';
    }
    final domain = email.substring(email.lastIndexOf('@') + 1).toLowerCase();
    if (!allowedDomains.contains(domain)) {
      return allowedDomainMessage;
    }
    return null;
  }
}
