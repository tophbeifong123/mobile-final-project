import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/entities/job.dart';
import '../models/job_model.dart';

class JobRemoteDataSource {
  JobRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<JobModel>> fetchFeed(JobFilter filter) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiConstants.jobs,
        queryParameters: {
          if (filter.search.trim().isNotEmpty) 'search': filter.search.trim(),
          if (filter.province != null && filter.province!.trim().isNotEmpty)
            'province': filter.province!.trim(),
          if (filter.workMode != null)
            'workMode': workModeToApi(filter.workMode!),
          if (filter.category != null && filter.category!.trim().isNotEmpty)
            'category': filter.category!.trim(),
          if (filter.hasAllowance != null) 'hasAllowance': filter.hasAllowance,
        },
      );
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return data
          .map((item) => JobModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapJobError(error);
    }
  }

  Future<JobDetailModel> fetchDetail(String jobId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiConstants.jobs}/$jobId',
      );
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return JobDetailModel.fromJson(data);
    } on DioException catch (error) {
      throw mapJobError(error);
    }
  }

  Future<void> save(String jobId) {
    throwNotConnected(_dio, '${ApiConstants.jobs}/$jobId/save');
  }

  Future<void> unsave(String jobId) {
    throwNotConnected(_dio, '${ApiConstants.jobs}/$jobId/save');
  }
}

AppException mapJobError(DioException error) {
  switch (error.response?.statusCode) {
    case 400:
      return const AppException('ข้อมูลไม่ถูกต้อง');
    case 403:
      return const AppException('เฉพาะนักศึกษาเท่านั้น');
    case 404:
      return const AppException('ไม่พบประกาศ');
    default:
      return const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
  }
}
