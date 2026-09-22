import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../models/company_profile_model.dart';

class CompanyProfileRemoteDataSource {
  CompanyProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<CompanyProfileModel> fetchMe() {
    throwNotConnected(_dio, ApiConstants.companyProfile);
  }

  Future<CompanyProfileModel> update(CompanyProfileModel profile) {
    throwNotConnected(_dio, ApiConstants.companyProfile);
  }

  Future<CompanyProfileModel> uploadLogo({
    required String filePath,
    required String fileName,
  }) {
    throwNotConnected(_dio, ApiConstants.companyLogo);
  }
}
