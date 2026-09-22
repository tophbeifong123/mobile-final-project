import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../models/saved_job_model.dart';

class SavedJobRemoteDataSource {
  SavedJobRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<SavedJobModel>> fetchSaved() {
    throwNotConnected(_dio, ApiConstants.savedJobs);
  }
}
