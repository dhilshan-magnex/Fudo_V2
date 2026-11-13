import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fudo_v2/data/server/usersetup_api.dart';

void main() {
  for (final response in [
    http.Response('{"message":"Route not found"}', 404),
    http.Response('<html>Not Found</html>', 404),
    http.Response('{"message":"Internal server error"}', 500),
  ]) {
    test(
      'permission lookup preserves server error: ${response.body}',
      () async {
        final api = UserSetupApi(
          client: MockClient((_) async => response),
          baseUrl: 'http://example.test',
        );
        await expectLater(
          api.getUserSetupByGroupScreen(
            groupCode: 'ADMIN',
            screenId: 'SCREEN01',
          ),
          throwsA(
            predicate(
              (error) =>
                  error.toString().contains('HTTP ${response.statusCode}'),
            ),
          ),
        );
      },
    );
  }

  test('creates a user group using the documented POST contract', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), 'http://example.test/api/user-group');
      expect(request.headers['content-type'], contains('application/json'));
      expect(jsonDecode(request.body), {
        'Group_Code': 'ADMIN',
        'Group_Name': 'Administrators',
        'Group_Descr': 'Administrator group',
      });
      return http.Response(
        '{"success":true,"message":"User Group created successfully"}',
        200,
      );
    });
    await UserSetupApi(
      client: client,
      baseUrl: 'http://example.test',
    ).createUserGroup(
      groupCode: 'ADMIN',
      groupName: 'Administrators',
      groupDescr: 'Administrator group',
    );
  });

  test('does not treat a server error as successful creation', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{"success":false,"message":"Internal server error"}',
        500,
      ),
    );
    final api = UserSetupApi(client: client, baseUrl: 'http://example.test');
    await expectLater(
      api.createUserGroup(
        groupCode: 'ADMIN',
        groupName: 'Administrators',
        groupDescr: 'Administrator group',
      ),
      throwsA(
        predicate(
          (error) =>
              error.toString().contains('HTTP 500') &&
              error.toString().contains('Internal server error'),
        ),
      ),
    );
  });
}
