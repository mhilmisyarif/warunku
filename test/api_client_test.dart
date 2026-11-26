import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warunku/config/api_constants.dart';
import 'package:warunku/services/api_client.dart';

void main() {
  test('uri encodes query values and drops empty ones', () {
    final api = ApiClient(
      client: MockClient((_) async => http.Response('', 200)),
    );
    final uri = api.uri('/customers', {'search': 'a&b #1', 'status': ''});
    expect(uri.queryParameters, {'search': 'a&b #1'});
    expect(uri.toString(), contains('search=a%26b+%231'));
  });

  test('error responses surface the backend message', () async {
    final api = ApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'errors': [
              {'msg': 'Name is required'},
            ],
          }),
          400,
        ),
      ),
    );
    await expectLater(
      api.post('/customers', {}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', 'Name is required')
            .having((e) => e.statusCode, 'statusCode', 400),
      ),
    );
  });

  test('non-JSON error bodies still produce a readable error', () async {
    final api = ApiClient(
      client: MockClient((_) async => http.Response('<html>oops</html>', 502)),
    );
    await expectLater(
      api.get('/products'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Permintaan gagal (502).',
        ),
      ),
    );
  });

  test('imageUrl resolves relative upload paths against the server root', () {
    expect(ApiConstants.imageUrl(''), isNull);
    expect(ApiConstants.imageUrl('https://x/y.png'), 'https://x/y.png');
    expect(
      ApiConstants.imageUrl('/uploads/a.png'),
      '${ApiConstants.serverRoot}/uploads/a.png',
    );
  });
}
