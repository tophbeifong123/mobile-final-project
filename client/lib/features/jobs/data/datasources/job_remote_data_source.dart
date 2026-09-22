import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/entities/job.dart';
import '../models/job_model.dart';

class JobRemoteDataSource {
  JobRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<JobModel>> fetchFeed(JobFilter filter) {
    throwNotConnected(_dio, ApiConstants.jobs);
  }

  Future<JobModel> fetchDetail(String jobId) {
    throwNotConnected(_dio, '${ApiConstants.jobs}/$jobId');
  }

  Future<void> save(String jobId) {
    throwNotConnected(_dio, '${ApiConstants.jobs}/$jobId/save');
  }

  Future<void> unsave(String jobId) {
    throwNotConnected(_dio, '${ApiConstants.jobs}/$jobId/save');
  }
}
