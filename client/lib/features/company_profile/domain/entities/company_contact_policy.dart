const int maxCompanyContacts = 8;

const String companyContactLimitError = 'ช่องทางติดต่อได้ไม่เกิน 8 รายการ';

const Map<String, String> companyContactPlatformLabels = {
  'phone': 'เบอร์โทรศัพท์',
  'email': 'อีเมล',
  'line': 'Line',
  'linkedin': 'LinkedIn',
  'facebook': 'Facebook',
  'instagram': 'Instagram',
  'other': 'อื่นๆ',
};

String companyContactPlatformLabel(String platform) {
  return companyContactPlatformLabels[platform.toLowerCase()] ?? 'อื่นๆ';
}

String? validateCompanyContactValue(String platform, String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return 'กรอกข้อมูลติดต่อ';
  if (value.length > 500) return 'ข้อมูลติดต่อต้องไม่เกิน 500 ตัวอักษร';

  switch (platform.toLowerCase()) {
    case 'email':
      final email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (value.length > 254 || !email.hasMatch(value)) {
        return 'อีเมลติดต่อไม่ถูกต้อง';
      }
      return null;
    case 'phone':
      final digits = value.replaceAll(RegExp(r'[\s().-]'), '');
      if (!RegExp(r'^\+?\d{8,15}$').hasMatch(digits)) {
        return 'เบอร์โทรศัพท์ไม่ถูกต้อง';
      }
      return null;
    default:
      if (value.contains('://') ||
          value.toLowerCase().startsWith('javascript:')) {
        final uri = Uri.tryParse(value);
        if (uri == null ||
            (uri.scheme != 'http' && uri.scheme != 'https') ||
            uri.host.isEmpty ||
            uri.userInfo.isNotEmpty) {
          return 'ลิงก์ติดต่อต้องขึ้นต้นด้วย http:// หรือ https:// และไม่มีชื่อผู้ใช้หรือรหัสผ่าน';
        }
      }
      return null;
  }
}
