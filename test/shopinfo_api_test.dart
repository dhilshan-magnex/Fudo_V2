import 'package:flutter_test/flutter_test.dart';
import 'package:fudo_v2/api/shopinfo_api.dart';

void main() {
  group('ShopInfoPayload', () {
    test('reads rows from nested payloads and normalizes keys', () {
      const json = {
        'data': [
          {
            'Client_ID': '940T0003',
            'Location_ID': '002',
            'Location_Name': 'Main Branch',
            'Location_Address1': '123 Main St',
            'Location_Phone': '555-1234',
            'Currency_Code': 'USD',
          },
        ],
      };

      final rows = ShopInfoPayload.rowsFromJson(json);

      expect(rows, hasLength(1));
      expect(rows.first['Client_ID'], '940T0003');
      expect(rows.first['Location_Name'], 'Main Branch');
    });
  });
}
