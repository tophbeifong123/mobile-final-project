import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/entities/auth_session.dart';

abstract class TokenStorage {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();

  String? get accessToken;

  String? get refreshToken;
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _roleKey = 'user_role';

  final FlutterSecureStorage _storage;
  AuthSession? _memory;

  @override
  String? get accessToken => _memory?.accessToken;

  @override
  String? get refreshToken => _memory?.refreshToken;

  @override
  Future<AuthSession?> read() async {
    if (_memory != null) {
      return _memory;
    }
    try {
      final accessToken = await _storage.read(key: _accessKey);
      final refreshToken = await _storage.read(key: _refreshKey);
      final role = await _storage.read(key: _roleKey);
      if (accessToken == null || refreshToken == null || role == null) {
        return null;
      }
      _memory = AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: UserRole.fromApi(role),
      );
      return _memory;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) async {
    _memory = session;
    await _storage.write(key: _accessKey, value: session.accessToken);
    await _storage.write(key: _refreshKey, value: session.refreshToken);
    await _storage.write(key: _roleKey, value: session.role.name);
  }

  @override
  Future<void> clear() async {
    _memory = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _roleKey);
  }
}

final class MemoryTokenStorage implements TokenStorage {
  AuthSession? _memory;

  @override
  String? get accessToken => _memory?.accessToken;

  @override
  String? get refreshToken => _memory?.refreshToken;

  @override
  Future<AuthSession?> read() async => _memory;

  @override
  Future<void> write(AuthSession session) async {
    _memory = session;
  }

  @override
  Future<void> clear() async {
    _memory = null;
  }
}
