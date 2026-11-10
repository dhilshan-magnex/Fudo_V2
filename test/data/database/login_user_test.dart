import 'package:flutter_test/flutter_test.dart';
import 'package:fudo_v2/data/database/db_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Database database;

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute(
      'CREATE TABLE User_File (User_ID TEXT PRIMARY KEY, '
      'User_Name TEXT, User_Pwd TEXT, User_Active INTEGER)',
    );
    await database.insert('User_File', {
      'User_ID': '01',
      'User_Name': 'Cashier',
      'User_Pwd': 'test-password',
      'User_Active': 1,
    });
  });
  tearDown(() => database.close());

  for (final clientType in ['1', '2']) {
    test('client type $clientType finds synced users by ID and name', () async {
      for (final login in ['01', 'Cashier']) {
        final user = await DBManager.getUserForLogin(
          clientType,
          login,
          database: database,
        );
        expect(user?['User_ID'], '01');
        expect(user?['User_Pwd'], 'test-password');
      }
    });

    test(
      'client type $clientType rejects inactive and missing users',
      () async {
        await database.update('User_File', {'User_Active': 0});
        for (final login in ['01', 'missing']) {
          expect(
            await DBManager.getUserForLogin(
              clientType,
              login,
              database: database,
            ),
            isNull,
          );
        }
      },
    );
  }
}
