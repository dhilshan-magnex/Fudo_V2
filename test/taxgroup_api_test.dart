import 'package:flutter_test/flutter_test.dart';
import 'package:fudo_v2/api/taxgroup_api.dart';

void main() {
  group('TaxGroupPayload', () {
    test('reads rows from nested payloads and normalizes keys', () {
      const json = {
        'data': [
          {
            'Tax_Code': 'TAX1',
            'Tax_Group_Code': 'G1',
            'Tax_Group_Name': 'Standard',
          },
        ],
      };

      final rows = TaxGroupPayload.rowsFromJson(json);

      expect(rows, hasLength(1));
      expect(rows.first['Tax_Group_Code'], 'G1');
      expect(rows.first['Tax_Group_Name'], 'Standard');
    });
  });
}
