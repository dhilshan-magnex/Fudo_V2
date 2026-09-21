import 'package:flutter_test/flutter_test.dart';
import 'package:fudo_v2/api/taxmaster_api.dart';

void main() {
  group('TaxMasterPayload', () {
    test('reads rows from nested payloads and normalizes keys', () {
      const json = {
        'data': [
          {
            'Tax_Code': 'TAX1',
            'Tax_Name': 'VAT',
            'Tax_Rate': '10',
            'Formula': 'Inclusive',
          },
        ],
      };

      final rows = TaxMasterPayload.rowsFromJson(json);

      expect(rows, hasLength(1));
      expect(rows.first['Tax_Code'], 'TAX1');
      expect(rows.first['Tax_Name'], 'VAT');
    });
  });
}
