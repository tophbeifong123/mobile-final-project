import 'package:dio/dio.dart';

class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

Never throwNotConnected(Dio dio, String path) {
  throw AppException('Not connected: ${dio.options.baseUrl}$path');
}
