import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/entities/company_job.dart';
import '../models/company_job_model.dart';

class CompanyJobRemoteDataSource {
  CompanyJobRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<CompanyJobModel>> fetchMine() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.companyJobs);
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
          .map((item) => CompanyJobModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapCompanyJobError(error);
    }
  }

  Future<EditableJobModel> fetchOne(String jobId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiConstants.companyJobs}/$jobId',
      );
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return EditableJobModel.fromJson(data);
    } on DioException catch (error) {
      throw mapCompanyJobError(error);
    }
  }

  Future<CreatedJobModel> create(JobPosting posting) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.companyJobs,
        data: {
          'title': posting.title,
          'description': posting.description,
          'province': posting.province,
          'workMode': posting.workMode,
          'category': posting.category,
          'hasAllowance': posting.hasAllowance,
          'requirements': posting.requirements,
        },
      );
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return CreatedJobModel.fromJson(data);
    } on DioException catch (error) {
      throw mapCompanyJobError(error);
    }
  }

  Future<EditableJobModel> update({
    required String jobId,
    required JobPosting posting,
    required int version,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '${ApiConstants.companyJobs}/$jobId',
        data: {
          'title': posting.title,
          'description': posting.description,
          'province': posting.province,
          'workMode': posting.workMode,
          'category': posting.category,
          'hasAllowance': posting.hasAllowance,
          'requirements': posting.requirements,
          'version': version,
        },
      );
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return EditableJobModel.fromJson(data);
    } on DioException catch (error) {
      throw mapCompanyJobError(error);
    }
  }

  Future<void> remove(String jobId) async {
    try {
      await _dio.delete<void>('${ApiConstants.companyJobs}/$jobId');
    } on DioException catch (error) {
      throw mapCompanyJobError(error);
    }
  }

  Future<void> setStatus({
    required String jobId,
    required String status,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '${ApiConstants.companyJobs}/$jobId/status',
        data: {'status': status},
      );
    } on DioException catch (error) {
      throw mapCompanyJobError(error);
    }
  }

  Future<List<ApplicantModel>> fetchApplicants(String jobId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '${ApiConstants.companyJobs}/$jobId/applications',
      );
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return data
          .map((item) => ApplicantModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw mapCompanyJobError(error);
    }
  }

  Future<ApplicantModel> fetchApplicant({
    required String jobId,
    required String applicationId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiConstants.companyJobs}/$jobId/applications/$applicationId',
      );
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return ApplicantModel.fromJson(data);
    } on DioException catch (error) {
      throw mapCompanyJobError(error);
    }
  }

  Future<void> updateApplicantStatus({
    required String jobId,
    required String applicationId,
    required String status,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '${ApiConstants.companyJobs}/$jobId/applications/$applicationId/status',
        data: {'status': status},
      );
    } on DioException catch (error) {
      throw mapCompanyJobError(error);
    }
  }
}

AppException mapCompanyJobError(DioException error) {
  final message = _serverMessage(error);
  switch (error.response?.statusCode) {
    case 400:
      return const AppException('ข้อมูลไม่ถูกต้อง');
    case 403:
      return AppException(message ?? 'เฉพาะบริษัทเท่านั้น');
    case 404:
      return AppException(message ?? 'ไม่พบโปรไฟล์บริษัท');
    case 409:
      return AppException(message ?? 'ประกาศถูกแก้ไปแล้ว โหลดข้อมูลใหม่');
    default:
      return const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
  }
}

String? _serverMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['message'] is String) {
    return data['message'] as String;
  }
  return null;
}
