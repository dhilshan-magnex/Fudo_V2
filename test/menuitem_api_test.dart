import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fudo_v2/api/menuitem_api.dart';
import 'package:fudo_v2/database/db_manager.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    databaseFactory = databaseFactoryFfi;
  });

  test('skips columns that do not exist in the local Menu_Items table', () async {
    final db = await DBManager.getDatabase(AppDatabase.fudo);
    await db.execute('DROP TABLE IF EXISTS Menu_Items');
    await db.execute('''
      CREATE TABLE Menu_Items (
        Cat_Code TEXT,
        Cat_Lv2_Code TEXT,
        Menu_ID TEXT,
        Menu_Name TEXT
      )
    ''');

    final api = MenuItemApi();
    final result = await api.saveMenuItemRows([
      {
        'Cat_Code': '001',
        'Cat_Lv2_Code': '002',
        'Cat_Lv3_Code': '003',
        'Menu_ID': 'M001',
        'Menu_Name': 'Burger',
      },
    ]);

    expect(result.savedCount, 1);

    final rows = await db.query('Menu_Items');
    expect(rows, isNotEmpty);
    expect(rows.first['Menu_ID'], 'M001');
    expect(rows.first['Menu_Name'], 'Burger');
    expect(rows.first.containsKey('Cat_Lv3_Code'), false);
  });
}
