import 'package:client/features/company_profile/domain/entities/company_website_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final website in [
    '',
    ' https://example.com/careers?lang=th ',
    'http://example.co.th',
  ]) {
    test('allows blank or valid website $website', () {
      expect(validateCompanyWebsite(website), isNull);
    });
  }
  for (final website in [
    'example.com',
    'https://example.com:99999',
    'https://',
    'https://.',
    'https://invalid_domain.com',
    'https://example .com',
    'ftp://example.com',
    'javascript:alert(1)',
    'https://user:password@example.com',
    'https://example.com\\evil',
  ]) {
    test('rejects invalid website $website with an explanation', () {
      expect(validateCompanyWebsite(website), companyWebsiteError);
    });
  }
}
