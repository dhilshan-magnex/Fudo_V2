import 'package:flutter_test/flutter_test.dart';
import 'package:fudo_v2/api/posmast_api.dart';

void main() {
  group('PosMastPayload', () {
    test('reads rows from nested payloads and normalizes keys', () {
      const json = {
        'data': [
          {
            'Counter_No': '01',
            'Counter_Name': 'Main Counter',
            'Receipt_Prn_Code': 'R1',
            'Cash_Drawer_Code': 'CD1',
            'Customer_Display_Code': 'D1',
          },
        ],
      };

      final rows = PosMastPayload.rowsFromJson(json);

      expect(rows, hasLength(1));
      expect(rows.first['Counter_No'], '01');
      expect(rows.first['Counter_Name'], 'Main Counter');
    });
  });
}
