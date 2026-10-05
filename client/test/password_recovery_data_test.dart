import 'package:client/core/constants/api_constants.dart';
import 'package:client/core/network/auth_interceptor.dart';
import 'package:client/core/storage/token_storage.dart';
import 'package:client/features/auth/data/datasources/password_recovery_remote_data_source.dart';
import 'package:client/features/auth/domain/entities/auth_session.dart';
import 'package:client/features/auth/domain/entities/password_recovery_email_policy.dart';
import 'package:client/features/auth/domain/entities/password_recovery_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'recovery sends expected JSON without bearer auth or changing session',
    () async {
      final storage = MemoryTokenStorage();
      await storage.write(
        const AuthSession(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
          role: UserRole.student,
        ),
      );
      final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'));
      final refreshDio = Dio();
      addTearDown(dio.close);
      addTearDown(refreshDio.close);
      dio.interceptors.add(
        AuthInterceptor(tokenStorage: storage, refreshDio: refreshDio),
      );
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response<void>(requestOptions: options, statusCode: 200),
            );
          },
        ),
      );
      final remote = PasswordRecoveryRemoteDataSource(dio);
      await remote.requestPasswordReset(email: ' Student@EMAIL.PSU.AC.TH ');
      await remote.resetPassword(
        token: 'secret-token',
        password: 'new-password',
      );
      expect(requests[0].path, ApiConstants.forgotPassword);
      expect(requests[0].data, {'email': 'Student@EMAIL.PSU.AC.TH'});
      expect(requests[1].path, ApiConstants.resetPassword);
      expect(requests[1].data, {
        'token': 'secret-token',
        'password': 'new-password',
      });
      expect(
        requests.every(
          (request) => !request.headers.containsKey('Authorization'),
        ),
        isTrue,
      );
      expect(storage.accessToken, 'old-access');
    },
  );

  test(
    'recovery error 401 cannot refresh or destroy an existing session',
    () async {
      final storage = MemoryTokenStorage();
      await storage.write(
        const AuthSession(
          accessToken: 'old-access',
          refreshToken: 'old-refresh',
          role: UserRole.student,
        ),
      );
      final dio = Dio();
      final refreshDio = Dio();
      addTearDown(dio.close);
      addTearDown(refreshDio.close);
      var refreshCalls = 0;
      refreshDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            refreshCalls++;
            handler.resolve(
              Response<void>(requestOptions: options, statusCode: 500),
            );
          },
        ),
      );
      dio.interceptors.add(
        AuthInterceptor(tokenStorage: storage, refreshDio: refreshDio),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<void>(
                  requestOptions: options,
                  statusCode: 401,
                ),
              ),
              true,
            );
          },
        ),
      );
      await expectLater(
        PasswordRecoveryRemoteDataSource(
          dio,
        ).requestPasswordReset(email: 'student@email.psu.ac.th'),
        throwsA(isA<PasswordRecoveryException>()),
      );
      expect(refreshCalls, 0);
      expect(storage.accessToken, 'old-access');
    },
  );

  test(
    'forgot-password 400 explains the two permitted PSU email domains',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 400,
                  data: {'message': 'internal validation detail'},
                ),
              ),
            );
          },
        ),
      );
      await expectLater(
        PasswordRecoveryRemoteDataSource(
          dio,
        ).requestPasswordReset(email: 'student@gmail.com'),
        throwsA(
          isA<PasswordRecoveryException>()
              .having(
                (error) => error.message,
                'allowed domain message',
                PasswordRecoveryEmailPolicy.allowedDomainMessage,
              )
              .having((error) => error.invalidLink, 'invalidLink', false),
        ),
      );
    },
  );

  for (final status in [400, 429, 503, 500]) {
    test('maps recovery $status safely without server secrets', () async {
      final dio = Dio();
      addTearDown(dio.close);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: status,
                  data: {'message': 'sensitive token secret-token'},
                  headers: Headers.fromMap({
                    'retry-after': ['120'],
                  }),
                ),
              ),
            );
          },
        ),
      );
      try {
        await PasswordRecoveryRemoteDataSource(
          dio,
        ).resetPassword(token: 'secret-token', password: 'new-password');
        fail('Expected a recovery failure');
      } on PasswordRecoveryException catch (error) {
        expect(error.message, isNot(contains('secret-token')));
        expect(error.invalidLink, status == 400);
        expect(error.retryAfterSeconds, status == 429 ? 120 : null);
      }
    });
  }

  for (final status in [409, 400]) {
    test(
      'PASSWORD_REUSE $status lets the same reset token be retried',
      () async {
        final dio = Dio();
        addTearDown(dio.close);
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.badResponse,
                  response: Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: status,
                    data: {
                      'code': 'PASSWORD_REUSE',
                      'message': 'Server diagnostic secret-token',
                    },
                  ),
                ),
              );
            },
          ),
        );
        await expectLater(
          PasswordRecoveryRemoteDataSource(
            dio,
          ).resetPassword(token: 'secret-token', password: 'old-secret-123'),
          throwsA(
            isA<PasswordRecoveryException>()
                .having(
                  (error) => error.message,
                  'reuse message',
                  'รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม',
                )
                .having((error) => error.invalidLink, 'invalidLink', false),
          ),
        );
      },
    );
  }
}
