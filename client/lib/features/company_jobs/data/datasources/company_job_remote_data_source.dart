import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../models/company_job_model.dart';

class CompanyJobRemoteDataSource {
  CompanyJobRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<CompanyJobModel>> fetchMine() {
    throwNotConnected(_dio, ApiConstants.companyJobs);
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
