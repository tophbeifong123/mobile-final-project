import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../constants/api_constants.dart';
import '../observability/sentry_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(tokenStorage: storage, refreshDio: refreshDio),
  );
  if (sentryEnabled) {
    dio.interceptors.add(_SentryNetworkInterceptor());
  }
  ref.onDispose(dio.close);
  ref.onDispose(refreshDio.close);
  return dio;
});

class _SentryNetworkInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'http',
        message: '${err.requestOptions.method} ${err.requestOptions.uri.path}',
        level: SentryLevel.error,
        data: {'statusCode': err.response?.statusCode},
      ),
    );
    handler.next(err);
  }
}
