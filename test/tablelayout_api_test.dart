import 'package:flutter_test/flutter_test.dart';
import 'package:fudo_v2/api/tablelayout_api.dart';

void main() {
  group('TableLayoutPayload', () {
    test('reads rows from nested payloads and normalizes keys', () {
      const json = {
        'data': [
          {
            'Table_No': 'T1',
            'Section_ID': 'S1',
            'X_Axis': '10',
            'Y_Axis': '20',
            'Active': '1',
            'Table_Shape': 'Round',
            'Rotation': '0',
          },
        ],
      };

      final rows = TableLayoutPayload.rowsFromJson(json);

      expect(rows, hasLength(1));
      expect(rows.first['Table_No'], 'T1');
      expect(rows.first['Section_ID'], 'S1');
    });
  });
}
