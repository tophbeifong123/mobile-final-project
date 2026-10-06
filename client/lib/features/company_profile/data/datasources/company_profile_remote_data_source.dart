import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/app_exception.dart';
import '../models/company_profile_model.dart';

class CompanyProfileRemoteDataSource {
  CompanyProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<CompanyProfileModel> fetchMe() {
    return _read(() {
      return _dio.get<Map<String, dynamic>>(ApiConstants.companyProfile);
    });
  }

  Future<CompanyProfileModel> update(CompanyProfileModel profile) {
    return _read(() {
      return _dio.patch<Map<String, dynamic>>(
        ApiConstants.companyProfile,
        data: profile.toJson(),
      );
    });
  }

  Future<CompanyProfileModel> uploadLogo({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) {
    return _uploadImage(
      endpoint: ApiConstants.companyLogo,
      filePath: filePath,
      fileName: fileName,
      bytes: bytes,
    );
  }

  Future<CompanyProfileModel> deleteLogo() {
    return _read(() {
      return _dio.delete<Map<String, dynamic>>(ApiConstants.companyLogo);
    });
  }

  Future<CompanyProfileModel> uploadCover({
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) {
    return _uploadImage(
      endpoint: ApiConstants.companyCover,
      filePath: filePath,
      fileName: fileName,
      bytes: bytes,
    );
  }

  Future<CompanyProfileModel> deleteCover() {
    return _read(() {
      return _dio.delete<Map<String, dynamic>>(ApiConstants.companyCover);
    });
  }

  Future<CompanyProfileModel> _uploadImage({
    required String endpoint,
    required String filePath,
    required String fileName,
    List<int>? bytes,
  }) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      final DioMediaType contentType;
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          contentType = DioMediaType('image', 'jpeg');
          break;
        case 'webp':
          contentType = DioMediaType('image', 'webp');
          break;
        case 'svg':
          contentType = DioMediaType('image', 'svg+xml');
          break;
        case 'gif':
          contentType = DioMediaType('image', 'gif');
          break;
        case 'png':
        default:
          contentType = DioMediaType('image', 'png');
          break;
      }

      final MultipartFile file;
      if (bytes != null && bytes.isNotEmpty) {
        file = MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: contentType,
        );
      } else {
        file = await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: contentType,
        );
      }

      final formData = FormData.fromMap({'file': file});

      final response = await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: formData,
      );

      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return CompanyProfileModel.fromJson(data);
    } on DioException catch (error) {
      throw mapCompanyProfileError(error);
    }
  }

  Future<CompanyProfileModel> _read(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      final data = response.data;
      if (data == null) {
        throw const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
      }
      return CompanyProfileModel.fromJson(data);
    } on DioException catch (error) {
      throw mapCompanyProfileError(error);
    }
  }
}

AppException mapCompanyProfileError(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic> && data['message'] != null) {
    final msg = data['message'];
    if (msg is String) return AppException(msg);
    if (msg is List && msg.isNotEmpty) {
      return AppException(msg.first.toString());
    }
  }

  switch (error.response?.statusCode) {
    case 400:
      return const AppException('ข้อมูลไม่ถูกต้อง');
    case 401:
      return const AppException('กรุณาเข้าสู่ระบบใหม่');
    case 403:
      return const AppException('เฉพาะบริษัทเท่านั้น');
    case 404:
      return const AppException('ไม่พบโปรไฟล์บริษัท');
    default:
      return const AppException('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้');
  }
}
