import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fudo_v2/data/server/users_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
      'CREATE TABLE User_File (User_ID TEXT PRIMARY KEY, '
      'User_Name TEXT, User_Pwd TEXT, User_Active INTEGER, Group_Code TEXT)',
    );
    await db.insert('User_File', {'User_ID': '01', 'User_Name': 'Old'});
  });
  tearDown(() => db.close());

  UsersApi api(List<Map<String, dynamic>> rows) => UsersApi(
    baseUrl: 'http://localhost:3000',
    client: MockClient((request) async {
      expect(request.url.path, '/api/users');
      expect(request.method, 'GET');
      return http.Response(jsonEncode({'data': rows}), 200);
    }),
  );

  test(
    'updates existing users and inserts server users without duplicates',
    () async {
      final users = api([
        {'user_id': '01', 'user_name': 'Updated', 'user_active': true},
        {'User_ID': '02', 'User_Name': 'New', 'User_Pwd': 'hash', 'extra': 1},
      ]);
      expect(await users.syncUsers(database: db), 2);
      await users.syncUsers(database: db);
      final rows = await db.query('User_File', orderBy: 'User_ID');
      expect(rows.length, 2);
      expect(rows.first['User_Name'], 'Updated');
      expect(rows.first['User_Active'], 1);
      expect(rows.last['User_Pwd'], 'hash');
    },
  );

  test('invalid server row rolls back updates and inserts', () async {
    await expectLater(
      api([
        {'User_ID': '02'},
        {'User_Name': 'Missing ID'},
      ]).syncUsers(database: db),
      throwsFormatException,
    );
    expect((await db.query('User_File')).single['User_Name'], 'Old');
  });

  test('sync preserves local users absent from the server', () async {
    await api([
      {'User_ID': '02'},
    ]).syncUsers(database: db);
    expect(
      (await db.query(
        'User_File',
        orderBy: 'User_ID',
      )).map((row) => row['User_ID']),
      ['01', '02'],
    );
  });

  test(
    'omitted, null and empty passwords preserve local credentials',
    () async {
      await db.update('User_File', {'User_Pwd': 'original'});
      for (final fields in <Map<String, dynamic>>[
        {},
        {'User_Pwd': null},
        {'user_pwd': ''},
      ]) {
        await api([
          {'User_ID': '01', 'User_Name': 'Updated', ...fields},
        ]).syncUsers(database: db);
        final user = (await db.query('User_File')).single;
        expect(user['User_Pwd'], 'original');
        expect(user['User_Name'], 'Updated');
      }
    },
  );

  test('server can update passwords and deactivate existing users', () async {
    await db.update('User_File', {'User_Pwd': 'original', 'User_Active': 1});
    await api([
      {'User_ID': '01', 'User_Pwd': 'new-password', 'User_Active': 0},
    ]).syncUsers(database: db);
    final user = (await db.query('User_File')).single;
    expect(user['User_Pwd'], 'new-password');
    expect(user['User_Active'], 0);
  });
}
