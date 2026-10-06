import 'dart:convert';

/// Registration feedback only; recovery uses its existing validation.
class RegistrationPasswordPolicy {
  const RegistrationPasswordPolicy(this.password, this.confirmation);

  final String password;
  final String confirmation;

  bool get hasMinimumCharacters => password.runes.length >= 8;
  bool get withinByteLimit => utf8.encode(password).length <= 72;
  bool get confirmationMatches =>
      password.isNotEmpty && confirmation == password;

  String? get passwordError {
    if (!hasMinimumCharacters) return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
    if (!withinByteLimit) return 'รหัสผ่านต้องไม่เกิน 72 ไบต์';
    return null;
  }

  String? get confirmationError {
    if (confirmation.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
    if (!confirmationMatches) return 'รหัสผ่านทั้งสองช่องไม่ตรงกัน';
    return null;
  }
}
