import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fudo_v2/data/api/validuser_api.dart';
import 'package:fudo_v2/functions/authentication/auth_service.dart';

void main() {
  AuthService service({
    int status = 200,
    String? result,
    int active = 1,
    String baseUrl = 'http://192.168.1.160:81',
  }) => AuthService(
    validUserApi: ValidUserApi(
      baseUrl: baseUrl,
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'http://192.168.1.160:81/api/validate-user',
        );
        expect(request.headers['content-type'], 'application/json');
        expect(jsonDecode(request.body), {
          'User_ID': 'u01',
          'User_Pwd': ' secret ',
        });
        return http.Response(
          result ??
              jsonEncode({
                'success': true,
                'message': 'Login successful',
                'data': {
                  'User_ID': 'u01',
                  'User_Name': 'Alex',
                  'Group_Code': 'ADMIN',
                  'User_Active': active,
                },
              }),
          status,
        );
      }),
    ),
  );
  Future<Map<String, dynamic>?> login(AuthService auth) =>
      auth.validateLogin('2', ' u01 ', ' secret ');

  test(
    'authenticates using returned profile without users list or SQLite',
    () async {
      final user = await login(service());
      expect(user?['User_ID'], 'u01');
      expect(user?['User_Name'], 'Alex');
      expect(user?['Group_Code'], 'ADMIN');
    },
  );
  test(
    'supports server addresses with an API suffix or trailing slash',
    () async {
      for (final suffix in ['/', '/api', '/api/']) {
        expect(
          await login(service(baseUrl: 'http://192.168.1.160:81$suffix')),
          isNotNull,
        );
      }
    },
  );
  test('rejects failed or inactive users', () async {
    expect(await login(service(result: '{"success":false}')), isNull);
    expect(await login(service(active: 0)), isNull);
    for (final status in [401, 403]) {
      expect(await login(service(status: status)), isNull);
    }
  });
  test('server errors propagate', () async {
    await expectLater(login(service(status: 500)), throwsException);
  });
  test('malformed success responses cannot authenticate', () async {
    for (final result in [
      'true',
      '{}',
      'null',
      'invalid',
      '{"success":true}',
      '{"success":true,"data":{}}',
    ]) {
      await expectLater(login(service(result: result)), throwsFormatException);
    }
  });
}
