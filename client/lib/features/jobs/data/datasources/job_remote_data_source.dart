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
      final response = await _dio.get<dynamic>(
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
          'page': filter.page,
          'limit': filter.limit,
        },
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
      return list
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

  Future<void> save(String jobId) async {
    try {
      await _dio.post<void>('${ApiConstants.jobs}/$jobId/save');
    } on DioException catch (error) {
      throw mapJobError(error);
    }
  }

  Future<void> unsave(String jobId) async {
    try {
      await _dio.delete<void>('${ApiConstants.jobs}/$jobId/save');
    } on DioException catch (error) {
      throw mapJobError(error);
    }
  }
}

AppException mapJobError(DioException error) {
  switch (error.response?.statusCode) {
    case 400:
      return const AppException('ข้อมูลไม่ถูกต้อง');
    case 403:
      return const AppException('เฉพาะนักศึกษาเท่านั้น');
    case 404:
      final data = error.response?.data;
      if (data is Map && data['message'] == 'ไม่พบโปรไฟล์') {
        return const AppException('ไม่พบโปรไฟล์');
      }
      return const AppException('ไม่พบประกาศ');
    default:
      return const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
  }
}
