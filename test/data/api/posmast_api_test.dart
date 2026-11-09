import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fudo_v2/data/api/posmast_api.dart';
import 'package:fudo_v2/data/server/posprinter_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fetches counters before a local server address is configured', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      expect(request.method, 'GET');
      return http.Response(
        jsonEncode({
          'data': [
            {'counter_no': '001', 'counter_name': 'Main', 'receipt_code': '01'},
          ],
        }),
        200,
      );
    });

    final rows = await PosMastApi(client: client).fetchPosMast(
      clientId: 'client1',
      locationId: 'location1',
    );

    expect(requests, 1);
    expect(rows.single['Counter_No'], '001');
    expect(rows.single['Counter_Name'], 'Main');
    expect(rows.single['receipt_code'], '01');
  });

  test(
    'maps snake-case POS Mast fields when registering with the server',
    () async {
      late Map<String, dynamic> createdPos;
      final client = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'counter_no': '001',
                  'counter_name': 'Take Away Counter',
                  'receipt_prn_code': '01',
                  'cash_drawer_code': '01',
                  'customer_display_code': '',
                },
              ],
            }),
            200,
          );
        }

        createdPos = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('{"success":true}', 200);
      });

      final result = await PosMastApi(client: client).syncPosMast(
        apiUrl: 'https://example.test/posmast',
        clientType: '2',
        serverApi: PosPrinterApi(
          client: client,
          baseUrl: 'https://example.test',
        ),
        registerCounters: false,
      );

      expect(result.savedCount, 1);
      expect(createdPos['Counter_No'], '001');
      expect(createdPos['Counter_Name'], 'Take Away Counter');
      expect(createdPos['Receipt_Code'], '01');
      expect(createdPos['Receipt_Prn_Code'], '01');
      expect(createdPos['Cash_Drawer_Code'], '01');
      expect(createdPos.containsKey('Cus_Display_Code'), isFalse);
    },
  );
}
