class ApiConstants {
  // Base URL: In Android Emulator, localhost is 10.0.2.2. On iOS simulator / desktop, it is localhost.
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const String localHostUrl = 'http://localhost:3000/api';

  // Endpoints
  static const String healthCheck = '/';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
}
