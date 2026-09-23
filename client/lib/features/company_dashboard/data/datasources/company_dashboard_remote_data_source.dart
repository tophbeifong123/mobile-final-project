import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../models/company_dashboard_summary_model.dart';

class CompanyDashboardRemoteDataSource {
  CompanyDashboardRemoteDataSource(this._dio);

  final Dio _dio;

  Future<CompanyDashboardSummaryModel> fetchSummary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.companyDashboard,
      );
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return CompanyDashboardSummaryModel.fromJson(data);
    } on DioException catch (error) {
      throw mapCompanyDashboardError(error);
    }
  }
}

AppException mapCompanyDashboardError(DioException error) {
  final message = _serverMessage(error);
  switch (error.response?.statusCode) {
    case 401:
      return const AppException('กรุณาเข้าสู่ระบบใหม่');
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
