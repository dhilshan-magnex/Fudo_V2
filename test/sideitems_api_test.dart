import 'package:flutter_test/flutter_test.dart';
import 'package:fudo_v2/api/sideitems_api.dart';

void main() {
  group('SideItemsPayload', () {
    test('reads rows from nested payloads and normalizes keys', () {
      const json = {
        'data': [
          {
            'Menu_ID': '1001',
            'Side_Menu_ID': '2002',
            'Side_Menu_Price': '15.50',
            'Side_Menu_Group': 'Addon',
            'Dellvery_Price': '0.00',
            'TakeAway_Price': '0.00',
          },
        ],
      };

      final rows = SideItemsPayload.rowsFromJson(json);

      expect(rows, hasLength(1));
      expect(rows.first['Menu_ID'], '1001');
      expect(rows.first['Side_Menu_ID'], '2002');
    });
  });
}
