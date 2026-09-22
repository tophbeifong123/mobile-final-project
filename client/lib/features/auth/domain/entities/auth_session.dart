enum UserRole {
  student,
  company;

  static UserRole fromApi(String value) {
    return UserRole.values.firstWhere((role) => role.name == value);
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
  });

  final String accessToken;
  final String refreshToken;
  final UserRole role;
}
