import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../models/student_profile_model.dart';

class StudentProfileRemoteDataSource {
  StudentProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<StudentProfileModel> fetchMe() {
    throwNotConnected(_dio, ApiConstants.studentProfile);
  }

  Future<StudentProfileModel> update(StudentProfileModel profile) {
    throwNotConnected(_dio, ApiConstants.studentProfile);
  }
}
