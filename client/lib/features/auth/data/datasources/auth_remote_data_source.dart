import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../models/auth_session_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) {
    return _postSession(ApiConstants.login, {
      'email': email,
      'password': password,
    });
  }

  Future<AuthSessionModel> register({
    required String email,
    required String password,
    required String role,
  }) {
    return _postSession(ApiConstants.register, {
      'email': email,
      'password': password,
      'role': role,
    });
  }

  Future<GoogleAuthResponse> authenticateWithGoogle({
    required String idToken,
    String? role,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.googleLogin,
        data: _googleAuthBody(idToken, role),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      if (data['code'] == 'role_required') {
        return const GoogleAuthResponse.roleRequired();
      }
      return GoogleAuthResponse.session(AuthSessionModel.fromJson(data));
    } on DioException catch (error) {
      throw mapAuthError(error);
    }
  }

  Future<AuthSessionModel> linkGoogle({
    required String idToken,
    required String password,
  }) {
    return _postSession(ApiConstants.googleLink, {
      'idToken': idToken,
      'password': password,
    });
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>(ApiConstants.logout);
    } on DioException {
      // The repository still clears the local session.
    }
  }

  Future<AuthSessionModel> _postSession(
    String path,
    Map<String, String> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return AuthSessionModel.fromJson(data);
    } on DioException catch (error) {
      throw mapAuthError(error);
    }
  }
}

Map<String, String> _googleAuthBody(String idToken, String? role) {
  final body = <String, String>{'idToken': idToken};
  if (role != null) {
    body['role'] = role;
  }
  return body;
}

AppException mapAuthError(DioException error) {
  switch (error.response?.statusCode) {
    case 409:
      final data = error.response?.data;
      final message = data is Map<String, dynamic> ? data['message'] : null;
      final code = data is Map<String, dynamic> ? data['code'] : null;
      final email = data is Map<String, dynamic> ? data['email'] : null;
      return AppException(
        message is String ? message : 'อีเมลนี้ถูกใช้แล้ว',
        code: code is String ? code : null,
        email: email is String ? email : null,
      );
    case 401:
      return const AppException('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
    case 400:
      return const AppException('ข้อมูลไม่ถูกต้อง');
    default:
      return const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
  }
}

class GoogleAuthResponse {
  const GoogleAuthResponse._({this.session, this.roleRequired = false});

  const GoogleAuthResponse.roleRequired() : this._(roleRequired: true);

  const GoogleAuthResponse.session(AuthSessionModel value)
    : this._(session: value);

  final AuthSessionModel? session;
  final bool roleRequired;
}
