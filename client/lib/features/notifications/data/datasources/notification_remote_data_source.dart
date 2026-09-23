import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../models/app_notification_model.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<AppNotificationModel>> fetchAll() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiConstants.notifications);
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return data
          .map((item) =>
              AppNotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapNotificationError(e);
    }
  }

  Future<AppNotificationModel> markAsRead(String id) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '${ApiConstants.notifications}/$id/read',
      );
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return AppNotificationModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapNotificationError(e);
    }
  }

  AppException _mapNotificationError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] != null) {
      final msg = data['message'];
      if (msg is String) return AppException(msg);
      if (msg is List && msg.isNotEmpty) return AppException(msg.first.toString());
    }

    switch (error.response?.statusCode) {
      case 401:
        return const AppException('กรุณาเข้าสู่ระบบใหม่');
      case 403:
        return const AppException('เฉพาะนักศึกษาเท่านั้น');
      case 404:
        return const AppException('ไม่พบการแจ้งเตือน');
      default:
        return const AppException('โหลดการแจ้งเตือนไม่สำเร็จ');
    }
  }
}
