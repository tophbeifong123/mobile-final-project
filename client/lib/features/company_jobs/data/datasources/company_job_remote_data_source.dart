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
      final response = await _dio.get<List<dynamic>>(ApiConstants.companyJobs);
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return data
          .map((item) => CompanyJobModel.fromJson(item as Map<String, dynamic>))
          .toList();
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

  Future<void> setStatus({required String jobId, required String status}) {
    throwNotConnected(_dio, '${ApiConstants.companyJobs}/$jobId/status');
  }

  Future<List<ApplicantModel>> fetchApplicants(String jobId) {
    throwNotConnected(_dio, '${ApiConstants.companyJobs}/$jobId/applications');
  }

  Future<ApplicantModel> fetchApplicant({
    required String jobId,
    required String applicationId,
  }) {
    throwNotConnected(
      _dio,
      '${ApiConstants.companyJobs}/$jobId/applications/$applicationId',
    );
  }

  Future<void> updateApplicantStatus({
    required String jobId,
    required String applicationId,
    required String status,
  }) {
    throwNotConnected(
      _dio,
      '${ApiConstants.companyJobs}/$jobId/applications/$applicationId/status',
    );
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
