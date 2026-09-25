import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../models/student_profile_model.dart';

class StudentProfileRemoteDataSource {
  StudentProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<StudentProfileModel> fetchMe() {
    return _read(() {
      return _dio.get<Map<String, dynamic>>(ApiConstants.studentProfile);
    });
  }

  Future<StudentProfileModel> update(StudentProfileModel profile) {
    return _read(() {
      return _dio.patch<Map<String, dynamic>>(
        ApiConstants.studentProfile,
        data: profile.toJson(),
      );
    });
  }

  Future<StudentProfileModel> uploadAvatar({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      final DioMediaType contentType;
      switch (ext) {
        case 'png':
          contentType = DioMediaType('image', 'png');
          break;
        case 'jpg':
        case 'jpeg':
          contentType = DioMediaType('image', 'jpeg');
          break;
        case 'webp':
          contentType = DioMediaType('image', 'webp');
          break;
        case 'svg':
          contentType = DioMediaType('image', 'svg+xml');
          break;
        case 'gif':
          contentType = DioMediaType('image', 'gif');
          break;
        default:
          contentType = DioMediaType('image', 'png');
          break;
      }

      final MultipartFile file;
      if (bytes != null && bytes.isNotEmpty) {
        file = MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: contentType,
        );
      } else {
        file = await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: contentType,
        );
      }

      final formData = FormData.fromMap({'file': file});

      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.studentAvatar,
        data: formData,
      );

      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return StudentProfileModel.fromJson(data);
    } on DioException catch (error) {
      throw mapStudentProfileError(error);
    }
  }

  Future<StudentProfileModel> deleteAvatar() {
    return _read(() {
      return _dio.delete<Map<String, dynamic>>(ApiConstants.studentAvatar);
    });
  }

  Future<StudentProfileModel> _read(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return StudentProfileModel.fromJson(data);
    } on DioException catch (error) {
      throw mapStudentProfileError(error);
    }
  }
}

AppException mapStudentProfileError(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic> && data['message'] != null) {
    final msg = data['message'];
    if (msg is String) return AppException(msg);
    if (msg is List && msg.isNotEmpty)
      return AppException(msg.first.toString());
  }
  switch (error.response?.statusCode) {
    case 400:
      return const AppException('ข้อมูลไม่ถูกต้อง');
    case 403:
      return const AppException('เฉพาะนักศึกษาเท่านั้น');
    case 404:
      return const AppException('ไม่พบโปรไฟล์');
    default:
      return const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
  }
}
