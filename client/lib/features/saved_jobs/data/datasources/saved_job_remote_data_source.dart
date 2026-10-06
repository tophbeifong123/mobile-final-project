import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../models/saved_job_model.dart';

class SavedJobRemoteDataSource {
  SavedJobRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<SavedJobModel>> fetchSaved() async {
    try {
      final models = <SavedJobModel>[];
      var page = 1;
      while (true) {
        final response = await _dio.get<dynamic>(
          ApiConstants.savedJobs,
          queryParameters: {'page': page, 'limit': 100},
        );
        final data = response.data;
        if (data == null) {
          throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
        }
        final List<dynamic> list;
        if (data is Map<String, dynamic> && data['items'] is List) {
          list = data['items'] as List<dynamic>;
        } else if (data is List) {
          list = data;
        } else {
          throw const AppException('ข้อมูลไม่ถูกต้อง');
        }
        models.addAll(
          list
              .map(
                (item) => SavedJobModel.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
        );
        if (data is! Map<String, dynamic> ||
            page >= (data['totalPages'] as int? ?? 1)) {
          break;
        }
        page++;
      }
      return models;
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
