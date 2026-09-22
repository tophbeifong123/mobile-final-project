import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../models/resume_file_model.dart';

class ResumeRemoteDataSource {
  ResumeRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ResumeFileModel> uploadPdf({
    required String filePath,
    required String fileName,
  }) {
    throwNotConnected(_dio, ApiConstants.studentResume);
  }
}
