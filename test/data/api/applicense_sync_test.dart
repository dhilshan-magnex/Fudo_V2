import 'package:flutter_test/flutter_test.dart';
import 'package:fudo_v2/data/api/applicense_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  for (final clearExistingData in [false, true]) {
    test(
      'license refresh preserves device address (clear=$clearExistingData)',
      () async {
        final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
        addTearDown(db.close);
        await db.execute(
          'CREATE TABLE App_License '
          '(Client_ID TEXT PRIMARY KEY, Client_Name TEXT, Server_Info TEXT)',
        );
        await db.insert('App_License', {
          'Client_ID': '01',
          'Client_Name': 'Old',
          'Server_Info': 'http://localhost:3000',
        });
        for (final address in [null, '', 'http://different-server:3000']) {
          await AppLicenseApi().saveAppLicenseRows(
            [
              {
                'Client_ID': '01',
                'Client_Name': 'Updated',
                'Server_Info': ?address,
              },
            ],
            database: db,
            clearExistingData: clearExistingData,
          );
          final row = (await db.query('App_License')).single;
          expect(row['Server_Info'], 'http://localhost:3000');
          expect(row['Client_Name'], 'Updated');
        }
      },
    );
  }
}
