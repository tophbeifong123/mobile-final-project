import 'dart:convert';

/// Registration feedback only; recovery uses its existing validation.
class RegistrationPasswordPolicy {
  const RegistrationPasswordPolicy(this.password, this.confirmation);

  final String password;
  final String confirmation;

  bool get hasMinimumCharacters => password.runes.length >= 8;
  bool get withinByteLimit => utf8.encode(password).length <= 72;
  bool get hasUppercase => RegExp(r'[A-Z]').hasMatch(password);
  bool get hasLowercase => RegExp(r'[a-z]').hasMatch(password);
  bool get hasDigit => RegExp(r'[0-9]').hasMatch(password);
  bool get hasSpecialCharacter =>
      RegExp(r'[\x21-\x2f\x3a-\x40\x5b-\x60\x7b-\x7e]').hasMatch(password);
  bool get confirmationMatches =>
      password.isNotEmpty && confirmation == password;

  String? get passwordError {
    if (!hasMinimumCharacters) return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
    if (!withinByteLimit) return 'รหัสผ่านต้องไม่เกิน 72 ไบต์';
    if (!hasUppercase) {
      return 'ต้องมีตัวอักษรภาษาอังกฤษพิมพ์ใหญ่อย่างน้อย 1 ตัว';
    }
    if (!hasLowercase) {
      return 'ต้องมีตัวอักษรภาษาอังกฤษพิมพ์เล็กอย่างน้อย 1 ตัว';
    }
    if (!hasDigit) return 'ต้องมีตัวเลขอย่างน้อย 1 ตัว';
    if (!hasSpecialCharacter) return 'ต้องมีอักขระพิเศษอย่างน้อย 1 ตัว';
    return null;
  }

  String? get confirmationError {
    if (confirmation.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
    if (!confirmationMatches) return 'รหัสผ่านทั้งสองช่องไม่ตรงกัน';
    return null;
  }
}
