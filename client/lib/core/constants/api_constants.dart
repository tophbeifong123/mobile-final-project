import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:3000/api';
  static const String localHostUrl = 'http://localhost:3000/api';
  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Web, desktop, and the iOS simulator reach the API on this machine.
  /// Chrome device mode still reports Android, so web is chosen before that.
  /// The Android emulator uses 10.0.2.2. A physical device passes
  /// `--dart-define=API_BASE_URL=http://<lan-ip>:3000/api`.
  static String get baseUrl {
    if (_override.isNotEmpty) {
      return _override;
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return localHostUrl;
    }
    return androidEmulatorBaseUrl;
  }

  // Endpoints
  static const String healthCheck = '/';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String jobs = '/jobs';
  static const String savedJobs = '/jobs/saved';
  static const String studentProfile = '/students/me';
  static const String studentResume = '/students/me/resume';
  static const String studentResumeFile = '/students/me/resume/file';
  static const String applications = '/applications';
  static const String notifications = '/notifications';
  static const String companyProfile = '/companies/me';
  static const String companyLogo = '/companies/me/logo';
  static const String companyDashboard = '/companies/me/dashboard';
  static const String companyJobs = '/company/jobs';
}
