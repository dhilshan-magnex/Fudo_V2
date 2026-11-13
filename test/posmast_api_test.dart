import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fudo_v2/data/api/posmast_api.dart';
import 'package:fudo_v2/data/server/posprinter_api.dart';

void main() {
  test(
    'maps actual lowercase GET fields to the server POST contract',
    () async {
      final source = {
        'counter_no': '001',
        'counter_name': 'Front',
        'reciept_prn_code': 'R01',
        'cash_drawer_code': 'CD01',
        'customer_display_code': 'D01',
      };
      var posts = 0;
      final client = MockClient((request) async {
        if (request.url.host == 'server.test') {
          if (request.method == 'POST') {
            expect(jsonDecode(request.body), {
              'Counter_No': '001',
              'Counter_Name': 'Front',
              'Reciept_Prn_Code': 'R01',
              'Cash_Drawer_Code': 'CD01',
              'Customer_Display_Code': 'D01',
            });
            posts++;
            return http.Response('{"success":true}', 200);
          }
          return http.Response('{"data":[]}', 200);
        }
        return http.Response(
          jsonEncode({
            'data': [source],
          }),
          200,
        );
      });
      final api = PosMastApi(client: client);
      final fetched = await api.fetchPosMast(
        clientId: 'client',
        locationId: 'location',
      );
      expect(fetched.single['Receipt_Prn_Code'], 'R01');
      expect(fetched.single['Customer_Display_Code'], 'D01');
      final server = PosPrinterApi(
        client: client,
        baseUrl: 'http://server.test',
      );
      await api.savePosMastRowsOnServer(fetched, serverApi: server);
      // Direct sync also accepts the unnormalized source spelling.
      await api.savePosMastRowsOnServer([source], serverApi: server);
      expect(posts, 2);
    },
  );
  test('POST rejection includes server validation and counter number', () async {
    final api = PosPrinterApi(
      baseUrl: 'http://server.test',
      client: MockClient(
        (request) async => http.Response(
          '{"message":"Validation failed","errors":["Receipt code required"]}',
          400,
        ),
      ),
    );
    await expectLater(
      api.createPos(counterNo: '001', counterName: 'Front', receiptCode: ''),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'server error',
          allOf(
            contains('001'),
            contains('400'),
            contains('Receipt code required'),
          ),
        ),
      ),
    );
  });
  final rows = [
    {
      'Counter_No': '01',
      'Counter_Name': 'Front',
      'Receipt_Code': 'P1',
      'Cus_Display_Code': 'D1',
    },
    {'Counter_No': '02', 'Counter_Name': 'Back', 'Receipt_Prn_Code': 'P2'},
  ];

  test('fetches scoped posmast and normalizes peripheral aliases', () async {
    final api = PosMastApi(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1_5/posmast/client/location');
        return http.Response(jsonEncode({'data': rows}), 200);
      }),
    );
    final result = await api.fetchPosMast(
      clientId: 'client',
      locationId: 'location',
    );
    expect(result, hasLength(2));
    expect(result.first['Receipt_Prn_Code'], 'P1');
    expect(result.first['Customer_Display_Code'], 'D1');
  });

  test('SQLite saves all rows and rolls back invalid replacement', () async {
    sqfliteFfiInit();
    final source = await databaseFactoryFfi.openDatabase(
      File('assets/database/Fudo.db').absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    );
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async {
      await db.close();
      await source.close();
    });
    final schema = await source.rawQuery(
      "SELECT sql FROM sqlite_master WHERE lower(name) = 'pos_mast'",
    );
    await db.execute(schema.single['sql'] as String);
    final api = PosMastApi();
    expect((await api.savePosMastRows(rows, database: db)).savedCount, 2);
    final saved = await db.query('POS_Mast', orderBy: 'Counter_No');
    expect(saved, hasLength(2));
    expect(saved.first['Receipt_Prn_Code'], 'P1');
    expect(saved.first['Customer_Display_Code'], 'D1');
    await expectLater(
      api.savePosMastRows(
        [
          rows.first,
          {'Counter_Name': 'Invalid'},
        ],
        database: db,
        clearExistingData: true,
      ),
      throwsFormatException,
    );
    expect(await db.query('POS_Mast', orderBy: 'Counter_No'), saved);
  });

  test(
    'type 2 sends every counter to server and preserves existing counters',
    () async {
      final stored = <String, Map<String, dynamic>>{};
      var posts = 0;
      final client = MockClient((request) async {
        if (request.url.path == '/posmast') {
          return http.Response(jsonEncode({'data': rows}), 200);
        }
        expect(request.url.path, '/api/pos');
        if (request.method == 'POST') {
          final row = Map<String, dynamic>.from(
            jsonDecode(request.body) as Map,
          );
          expect(
            row.keys,
            containsAll(['Reciept_Prn_Code', 'Customer_Display_Code']),
          );
          expect(row.containsKey('Receipt_Prn_Code'), isFalse);
          expect(row.containsKey('Receipt_Code'), isFalse);
          expect(row.containsKey('Cus_Display_Code'), isFalse);
          expect(row['Reciept_Prn_Code'], isNotEmpty);
          stored[row['Counter_No'] as String] = row;
          posts++;
          return http.Response('{"success":true}', 200);
        }
        final row = stored[request.url.queryParameters['Counter_No']];
        return http.Response(
          jsonEncode({
            'data': [?row],
          }),
          200,
        );
      });
      final api = PosMastApi(client: client);
      for (var attempt = 0; attempt < 2; attempt++) {
        final result = await api.syncPosMast(
          apiUrl: 'https://example.test/posmast',
          clientType: '2',
          registerCounters: false,
          serverApi: PosPrinterApi(
            client: client,
            baseUrl: 'http://server.test',
          ),
        );
        expect(result.savedCount, 2);
      }
      expect(posts, 2);
      expect(stored['01']!['Reciept_Prn_Code'], 'P1');
      expect(stored['01']!['Customer_Display_Code'], 'D1');
      // A downloaded row may omit configuration already present on the server.
      final existing = await api.savePosMastRowsOnServer(
        [
          {'Counter_No': '01'},
        ],
        serverApi: PosPrinterApi(client: client, baseUrl: 'http://server.test'),
      );
      expect(existing.savedCount, 1);
      expect(posts, 2);
      final unassigned = await api.savePosMastRowsOnServer(
        [
          {'Counter_No': '001', 'Counter_Name': 'Unassigned'},
          {
            'Counter_No': '004',
            'Counter_Name': 'Null printer',
            'Receipt_Prn_Code': null,
          },
          {
            'Counter_No': '005',
            'Counter_Name': 'Blank printer',
            'Receipt_Code': '  ',
          },
        ],
        defaultReceiptCode: 'R01',
        serverApi: PosPrinterApi(client: client, baseUrl: 'http://server.test'),
      );
      expect(unassigned.savedCount, 3);
      expect(posts, 5);
      for (final counter in ['001', '004', '005']) {
        expect(stored[counter]!['Reciept_Prn_Code'], 'R01');
      }
      await expectLater(
        api.savePosMastRowsOnServer(
          [
            {'Counter_No': '03'},
          ],
          serverApi: PosPrinterApi(
            client: client,
            baseUrl: 'http://server.test',
          ),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'missing fields',
            contains('Counter_Name'),
          ),
        ),
      );
    },
  );
}
