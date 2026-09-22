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

AppException mapAuthError(DioException error) {
  switch (error.response?.statusCode) {
    case 409:
      return const AppException('อีเมลนี้ถูกใช้แล้ว');
    case 401:
      return const AppException('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
    case 400:
      return const AppException('ข้อมูลไม่ถูกต้อง');
    default:
      return const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
  }
}
