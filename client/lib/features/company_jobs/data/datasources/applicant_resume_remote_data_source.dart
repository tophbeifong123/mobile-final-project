import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';

class ApplicantResumeRemoteDataSource {
  ApplicantResumeRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<int>> fetch(String jobId, String applicationId) async {
    try {
      final response = await _dio.get<List<int>>(
        '${ApiConstants.companyJobs}/$jobId/applications/$applicationId/resume',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null ||
          bytes.length < 4 ||
          String.fromCharCodes(bytes.take(4)) != '%PDF') {
        throw const AppException(
          'เปิดไฟล์ Resume ไม่สำเร็จ ไฟล์ PDF ไม่ถูกต้อง',
        );
      }
      return bytes;
    } on DioException catch (error) {
      final message = switch (error.response?.statusCode) {
        403 => 'คุณไม่มีสิทธิ์เปิด Resume ของใบสมัครนี้',
        404 => 'ไม่พบไฟล์ Resume ของใบสมัคร',
        _ => 'เปิดไฟล์ Resume ไม่สำเร็จ กรุณาลองใหม่',
      };
      throw AppException(message);
    }
  }
}
