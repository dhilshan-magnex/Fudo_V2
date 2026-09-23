import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fudo_v2/api/applicense_api.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    databaseFactory = databaseFactoryFfi;
  });

  test('accepts real app license payloads that only include client_id', () async {
    final api = AppLicenseApi();

    final result = await api.saveAppLicenseRows([
      {
        'client_id': '940T0003',
        'location_id': '002',
        'client_type': 2,
        'current_version': 1,
        'valid_to': '2026-12-31',
      },
    ]);

    expect(result.savedCount, 1);
  });
}
