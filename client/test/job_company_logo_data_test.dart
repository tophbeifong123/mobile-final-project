import 'package:client/core/error/app_exception.dart';
import 'package:client/features/jobs/data/datasources/job_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('logo bytes use the job-scoped API and retain the image type', () async {
    final dio = Dio();
    addTearDown(dio.close);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/jobs/job-1/company-logo');
          expect(options.responseType, ResponseType.bytes);
          handler.resolve(
            Response<List<int>>(
              requestOptions: options,
              data: [1, 2, 3],
              statusCode: 200,
              headers: Headers.fromMap({
                'content-type': ['image/svg+xml'],
              }),
            ),
          );
        },
      ),
    );
    final logo = await JobRemoteDataSource(dio).fetchCompanyLogo('job-1');
    expect(logo?.bytes, [1, 2, 3]);
    expect(logo?.mimeType, 'image/svg+xml');
  });

  for (final status in [404, 500]) {
    test(
      'logo response $status is handled without losing job details',
      () async {
        final dio = Dio();
        addTearDown(dio.close);
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response<dynamic>(
                    requestOptions: options,
                    statusCode: status,
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
            },
          ),
        );
        final result = JobRemoteDataSource(dio).fetchCompanyLogo('job-1');
        if (status == 404) {
          expect(await result, isNull);
        } else {
          await expectLater(result, throwsA(isA<AppException>()));
        }
      },
    );
  }
}
