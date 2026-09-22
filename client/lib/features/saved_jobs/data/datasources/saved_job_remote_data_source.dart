import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../models/saved_job_model.dart';

class SavedJobRemoteDataSource {
  SavedJobRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<SavedJobModel>> fetchSaved() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiConstants.savedJobs);
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return data
          .map((item) => SavedJobModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapSavedJobError(error);
    }
  }
}

AppException mapSavedJobError(DioException error) {
  switch (error.response?.statusCode) {
    case 403:
      return const AppException('เฉพาะนักศึกษาเท่านั้น');
    case 404:
      return const AppException('ไม่พบโปรไฟล์');
    default:
      return const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
  }
}
