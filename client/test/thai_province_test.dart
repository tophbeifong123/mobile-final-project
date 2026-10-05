import 'package:client/core/network/dio_client.dart';
import 'package:client/core/provinces/thai_provinces_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads canonical province names and searches aliases', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/provinces');
          handler.resolve(
            Response<List<dynamic>>(
              requestOptions: options,
              data: [
                {
                  'id': 10,
                  'nameTh': 'กรุงเทพมหานคร',
                  'aliases': ['กรุงเทพฯ', 'กทม.'],
                  'centerLatitude': 13.7563,
                  'centerLongitude': '100.5018',
                },
              ],
            ),
          );
        },
      ),
    );
    final container = ProviderContainer(
      overrides: [dioProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);

    final provinces = await container.read(thaiProvincesProvider.future);

    expect(provinces, hasLength(1));
    expect(provinces.single.nameTh, 'กรุงเทพมหานคร');
    expect(provinces.single.centerLatitude, 13.7563);
    expect(provinces.single.centerLongitude, 100.5018);
    expect(provinces.single.matches('กทม'), isTrue);
    expect(provinces.single.matches('กรุงเทพ'), isTrue);
    expect(provinces.single.matches('สงขลา'), isFalse);
  });
}
