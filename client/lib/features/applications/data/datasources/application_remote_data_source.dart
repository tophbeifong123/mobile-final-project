import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../models/job_application_model.dart';

class ApplicationRemoteDataSource {
  ApplicationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<JobApplicationModel>> fetchMine() {
    throwNotConnected(_dio, ApiConstants.applications);
  }

  Future<JobApplicationModel> fetchDetail(String applicationId) {
    throwNotConnected(_dio, '${ApiConstants.applications}/$applicationId');
  }

  Future<JobApplicationModel> apply({
    required String jobId,
    required String coverLetter,
  }) {
    throwNotConnected(_dio, '${ApiConstants.jobs}/$jobId/applications');
  }
}
