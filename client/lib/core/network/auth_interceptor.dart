import 'package:dio/dio.dart';

import '../../features/auth/data/models/auth_session_model.dart';
import '../constants/api_constants.dart';
import '../error/app_exception.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this.tokenStorage, required this.refreshDio});

  final TokenStorage tokenStorage;
  final Dio refreshDio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenStorage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _refreshAfterUnauthorized(err, handler);
  }

  Future<void> _refreshAfterUnauthorized(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;
    if (statusCode != 401 || alreadyRetried) {
      handler.next(err);
      return;
    }

    final refreshToken = tokenStorage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await tokenStorage.clear();
      handler.next(err);
      return;
    }

    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
      );
      final body = response.data;
      if (body == null) {
        throw const AppException('Refresh response was empty');
      }
      final session = AuthSessionModel.fromJson(body).toEntity();
      await tokenStorage.write(session);
      final request = err.requestOptions;
      request.extra['retried'] = true;
      request.headers['Authorization'] = 'Bearer ${session.accessToken}';
      final retry = await refreshDio.fetch<dynamic>(request);
      handler.resolve(retry);
    } catch (_) {
      await tokenStorage.clear();
      handler.next(err);
    }
  }
}
