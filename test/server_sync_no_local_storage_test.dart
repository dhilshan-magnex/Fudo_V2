import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fudo_v2/data/server/cashdrawer_api.dart';
import 'package:fudo_v2/data/server/customerdisplay_api.dart';
import 'package:fudo_v2/data/server/posprinter_api.dart';
import 'package:fudo_v2/data/server/users_api.dart';
import 'package:fudo_v2/data/server/usersetup_api.dart';

void main() {
  test(
    'server sync works without a SQLite factory or local database',
    () async {
      final paths = <String>[];
      final client = MockClient((request) async {
        paths.add(request.url.path);
        return http.Response(
          '{"success":true,"data":[{"Group_Code":"STAFF"}]}',
          200,
        );
      });
      const baseUrl = 'http://example.test';
      expect(await UsersApi(client: client, baseUrl: baseUrl).syncUsers(), 1);
      final setup = UserSetupApi(client: client, baseUrl: baseUrl);
      expect(await setup.syncUserGroups(clearExistingData: true), 1);
      expect(await setup.syncUserSetup(clearExistingData: true), 2);
      expect(
        await PosPrinterApi(
          client: client,
          baseUrl: baseUrl,
        ).syncPrinters(clearExistingData: true),
        1,
      );
      expect(
        await CustomerDisplayApi(
          client: client,
          baseUrl: baseUrl,
        ).syncCustomerDisplays(clearExistingData: true),
        1,
      );
      expect(
        await CashDrawerApi(
          client: client,
          baseUrl: baseUrl,
        ).syncCashDrawers(clearExistingData: true),
        1,
      );
      expect(
        paths,
        containsAll([
          '/api/users',
          '/api/user-group',
          '/api/user-setup/group-screen',
          '/api/printers',
          '/api/customer-displays',
          '/api/cash-drawers',
        ]),
      );
      client.close();
    },
  );

  test('server sync still reports fetch errors', () async {
    final client = MockClient((_) async => http.Response('Unavailable', 503));
    await expectLater(
      CashDrawerApi(
        client: client,
        baseUrl: 'http://example.test',
      ).syncCashDrawers(),
      throwsException,
    );
    client.close();
  });
}
