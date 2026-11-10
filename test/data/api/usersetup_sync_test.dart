import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:fudo_v2/data/server/usersetup_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<int> syncRows(
  String table,
  List<Map<String, dynamic>> rows, {
  required Database database,
  bool clearExistingData = false,
}) {
  final api = UserSetupApi(
    baseUrl: 'http://localhost:3000',
    client: MockClient((request) async {
      if (request.url.path == '/api/user-group' && table != 'User_Group') {
        return http.Response(
          jsonEncode({
            'data': [
              {'Group_Code': '01'},
            ],
          }),
          200,
        );
      }
      return http.Response(jsonEncode({'data': rows}), 200);
    }),
  );
  return table == 'User_Group'
      ? api.syncUserGroups(
          database: database,
          clearExistingData: clearExistingData,
        )
      : api.syncUserSetup(
          database: database,
          clearExistingData: clearExistingData,
        );
}

void main() {
  sqfliteFfiInit();
  late Database db;
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
      'CREATE TABLE User_Group (Group_Code TEXT PRIMARY KEY, Group_Name TEXT)',
    );
    await db.execute(
      'CREATE TABLE User_setup (Row_Index INTEGER PRIMARY KEY, Group_Code TEXT, Screen_ID TEXT, Access_Lvl INTEGER)',
    );
  });
  tearDown(() => db.close());
  test(
    'replacement clears fetched screens and preserves other screens',
    () async {
      await db.insert('User_setup', {'Row_Index': 1, 'Screen_ID': 'BILLING'});
      await db.insert('User_setup', {'Row_Index': 2, 'Screen_ID': 'OTHER'});
      await syncRows('User_setup', [], database: db, clearExistingData: true);
      expect((await db.query('User_setup')).single['Screen_ID'], 'OTHER');
    },
  );
  test('upserts by key, maps case and ignores unknown fields', () async {
    for (final name in ['Old', 'New']) {
      await syncRows('User_Group', [
        {'group_code': '01', 'group_name': name, 'extra': 1},
      ], database: db);
    }
    expect((await db.query('User_Group')).single['Group_Name'], 'New');
  });
  test('preserves distinct permission rows for one group', () async {
    final rows = [
      {'Row_Index': 1, 'Group_Code': '01', 'Access_Lvl': true},
      {'Row_Index': 2, 'Group_Code': '01', 'Access_Lvl': false},
    ];
    await syncRows('User_setup', rows, database: db);
    await syncRows('User_setup', rows, database: db);
    expect((await db.query('User_setup')).length, 2);
  });
  test('malformed replacement rolls back deletion', () async {
    await db.insert('User_Group', {'Group_Code': '01'});
    await expectLater(
      syncRows(
        'User_Group',
        [
          {'Group_Name': 'No key'},
        ],
        database: db,
        clearExistingData: true,
      ),
      throwsFormatException,
    );
    expect((await db.query('User_Group')).single['Group_Code'], '01');
  });
}
