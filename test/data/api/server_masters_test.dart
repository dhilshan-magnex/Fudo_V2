import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fudo_v2/data/server/usersetup_api.dart';
import 'package:fudo_v2/data/server/posprinter_api.dart';
import 'package:fudo_v2/data/server/customerdisplay_api.dart';
import 'package:fudo_v2/data/server/cashdrawer_api.dart';

void main() {
  sqfliteFfiInit();
  test('downloads all five master lists into SQLite', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    final definitions = {
      '/api/user-group': ['User_Group', 'Group_Code', '01'],
      '/api/user-setup/group-screen': ['User_setup', 'Row_Index', '1'],
      '/api/printers': ['Print_Mast', 'Printer_Code', '01'],
      '/api/customer-displays': ['Customer_Display', 'Display_Code', '01'],
      '/api/cash-drawers': ['Cash_Drawer', 'Drawer_Code', '01'],
    };
    for (final def in definitions.values) {
      await db.execute('CREATE TABLE ${def[0]} (${def[1]} TEXT PRIMARY KEY)');
    }
    final seen = <String>{};
    final client = MockClient((request) async {
      expect(
        request.method,
        request.url.path.endsWith('/group-screen') ? 'POST' : 'GET',
      );
      if (request.method == 'POST') {
        expect(jsonDecode(request.body)['Group_Code'], '01');
        expect([
          'BILLING',
          'DATASYNC',
        ], contains(jsonDecode(request.body)['Screen_ID']));
        if (jsonDecode(request.body)['Screen_ID'] == 'DATASYNC') {
          return http.Response(jsonEncode({'data': []}), 200);
        }
      }
      seen.add(request.url.path);
      final def = definitions[request.url.path]!;
      return http.Response(
        jsonEncode({
          'data': [
            {def[1]: def[2]},
          ],
        }),
        200,
      );
    });
    const url = 'http://localhost:3000';
    final users = UserSetupApi(client: client, baseUrl: url);
    final printers = PosPrinterApi(client: client, baseUrl: url);
    final displays = CustomerDisplayApi(client: client, baseUrl: url);
    final drawers = CashDrawerApi(client: client, baseUrl: url);
    for (var i = 0; i < 2; i++) {
      expect(await users.syncUserGroups(database: db), 1);
      expect(await users.syncUserSetup(database: db), 1);
      expect(await printers.syncPrinters(database: db), 1);
      expect(await displays.syncCustomerDisplays(database: db), 1);
      expect(await drawers.syncCashDrawers(database: db), 1);
    }
    expect(seen, definitions.keys.toSet());
    for (final def in definitions.values) {
      expect((await db.query(def[0])).single[def[1]], def[2]);
    }
  });
}
