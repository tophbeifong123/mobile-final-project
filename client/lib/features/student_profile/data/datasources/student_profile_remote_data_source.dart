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
