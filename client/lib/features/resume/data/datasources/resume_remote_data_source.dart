import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../models/resume_file_model.dart';

class ResumeRemoteDataSource {
  ResumeRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ResumeFileModel> uploadPdf({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async {
    try {
      final MultipartFile file;
      if (bytes != null && bytes.isNotEmpty) {
        file = MultipartFile.fromBytes(bytes, filename: fileName);
      } else {
        file = await MultipartFile.fromFile(filePath, filename: fileName);
      }

      final formData = FormData.fromMap({
        'file': file,
      });

      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.studentResume,
        data: formData,
      );

      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return ResumeFileModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapResumeError(e);
    }
  }

  AppException _mapResumeError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] != null) {
      final msg = data['message'];
      if (msg is String) return AppException(msg);
      if (msg is List && msg.isNotEmpty) return AppException(msg.first.toString());
    }

    switch (error.response?.statusCode) {
      case 400:
        return const AppException('เลือกได้เฉพาะไฟล์ PDF เท่านั้น');
      case 401:
        return const AppException('กรุณาเข้าสู่ระบบใหม่');
      case 403:
        return const AppException('เฉพาะนักศึกษาเท่านั้น');
      case 404:
        return const AppException('ไม่พบโปรไฟล์');
      default:
        return const AppException('อัปโหลดไฟล์ไม่สำเร็จ');
    }
  }
}
