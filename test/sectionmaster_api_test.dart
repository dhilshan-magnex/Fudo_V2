import 'package:flutter_test/flutter_test.dart';
import 'package:fudo_v2/api/sectionmaster_api.dart';

void main() {
  group('SectionMasterPayload', () {
    test('reads rows from nested payloads and normalizes keys', () {
      const json = {
        'data': [
          {
            'Section_ID': '01',
            'Section_Name': 'Dining',
            'Section_Order': '1',
          },
        ],
      };

      final rows = SectionMasterPayload.rowsFromJson(json);

      expect(rows, hasLength(1));
      expect(rows.first['Section_ID'], '01');
      expect(rows.first['Section_Name'], 'Dining');
    });
  });
}
