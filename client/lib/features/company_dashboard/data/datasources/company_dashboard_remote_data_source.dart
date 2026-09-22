import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../models/company_dashboard_summary_model.dart';

class CompanyDashboardRemoteDataSource {
  CompanyDashboardRemoteDataSource(this._dio);

  final Dio _dio;

  Future<CompanyDashboardSummaryModel> fetchSummary() {
    throwNotConnected(_dio, ApiConstants.companyDashboard);
  }
}
