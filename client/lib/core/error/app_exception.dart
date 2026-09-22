import 'package:dio/dio.dart';

class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

String userVisibleError(Object error) {
  if (error is AppException && error.message.startsWith('Not connected')) {
    return 'ยังเชื่อมต่อเซิร์ฟเวอร์ไม่ได้';
  }
  if (error is AppException) {
    return error.message;
  }
  return 'ทำรายการไม่สำเร็จ';
}

Never throwNotConnected(Dio dio, String path) {
  throw AppException('Not connected: ${dio.options.baseUrl}$path');
}
