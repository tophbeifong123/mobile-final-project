const companyWebsiteError =
    'เว็บไซต์ต้องเป็น URL ที่ถูกต้องและขึ้นต้นด้วย http:// หรือ https:// โดยไม่มีชื่อผู้ใช้หรือรหัสผ่าน';

String? validateCompanyWebsite(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final uri = Uri.tryParse(text);
  final hostPattern = RegExp(
    r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$',
  );
  if (text.length > 1024 ||
      RegExp(r'\s|\\').hasMatch(text) ||
      uri == null ||
      !['http', 'https'].contains(uri.scheme.toLowerCase()) ||
      (uri.hasPort && (uri.port < 1 || uri.port > 65535)) ||
      uri.userInfo.isNotEmpty ||
      !hostPattern.hasMatch(uri.host)) {
    return companyWebsiteError;
  }
  return null;
}
