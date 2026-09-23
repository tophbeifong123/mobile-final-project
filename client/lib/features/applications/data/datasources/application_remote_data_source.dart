import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../models/job_application_model.dart';

class ApplicationRemoteDataSource {
  ApplicationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<JobApplicationModel>> fetchMine() {
    throwNotConnected(_dio, ApiConstants.applications);
  }

  Future<JobApplicationModel> fetchDetail(String applicationId) {
    throwNotConnected(_dio, '${ApiConstants.applications}/$applicationId');
  }

  Future<JobApplicationModel> apply({
    required String jobId,
    required String coverLetter,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiConstants.jobs}/$jobId/applications',
        data: {'coverLetter': coverLetter},
      );
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return JobApplicationModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapApplicationError(e);
    }
  }

  AppException _mapApplicationError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] != null) {
      final msg = data['message'];
      if (msg is String) return AppException(msg);
      if (msg is List && msg.isNotEmpty) return AppException(msg.first.toString());
    }

    switch (error.response?.statusCode) {
      case 400:
        return const AppException('ข้อมูลการสมัครไม่ถูกต้อง หรือยังไม่มี Resume');
      case 401:
        return const AppException('กรุณาเข้าสู่ระบบใหม่');
      case 403:
        return const AppException('เฉพาะนักศึกษาเท่านั้น');
      case 404:
        return const AppException('ไม่พบประกาศงานหรือโปรไฟล์');
      case 409:
        return const AppException('สมัครงานนี้ไปแล้ว');
      default:
        return const AppException('สมัครงานไม่สำเร็จ');
    }
  }
}
