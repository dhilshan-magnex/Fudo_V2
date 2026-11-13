import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fudo_v2/data/dummy_data.dart';

void main() {
  for (final confirmed in [true, false]) {
    test(
      'duplicate group is accepted only when confirmed: $confirmed',
      () async {
        var groupReads = 0;
        var userPosted = false;
        List<DummyTableResult> results = [];
        final client = MockClient((request) async {
          if (request.method == 'GET') {
            var data = <Map<String, Object?>>[];
            if (request.url.path == '/api/user-group') {
              groupReads++;
              data = [
                {'Group_Code': 'CASH'},
                if (confirmed && groupReads > 1) {'Group_Code': ' admin '},
              ];
            }
            return http.Response(
              jsonEncode({'success': true, 'data': data}),
              200,
            );
          }
          if (request.url.path == '/api/user-group') {
            return http.Response(
              '{"success":false,"message":"User Group already exists"}',
              500,
            );
          }
          if (request.url.path == '/api/users') userPosted = true;
          if (request.url.path == '/api/user-setup/group-screen') {
            return http.Response('{"success":true,"data":[]}', 200);
          }
          return http.Response('{"success":true}', 201);
        });
        final operation = DummyData.insert(
          clientType: '2',
          client: client,
          baseUrl: 'http://example.test',
          onResult: (value) => results = value,
        );
        if (confirmed) {
          await operation;
        } else {
          await expectLater(operation, throwsException);
        }
        final group = results.singleWhere((r) => r.table == 'User_Group');
        expect(group.inserted, 0);
        expect(group.existing, confirmed ? 2 : 0);
        expect(userPosted, confirmed);
        expect(groupReads, 2);
        expect(
          group.status,
          confirmed ? 'Complete' : contains('already exists'),
        );
      },
    );
  }

  test(
    'group rejection reports server details and still seeds peripherals',
    () async {
      List<DummyTableResult> results = [];
      final posts = <String>[];
      final client = MockClient((request) async {
        expect(request.url.path, isNot('/api/users'));
        if (request.method == 'GET') {
          return http.Response('{"success":true,"data":[]}', 200);
        }
        posts.add(request.url.path);
        if (request.url.path == '/api/user-group') {
          return http.Response(
            '{"success":false,"message":"Group description is too long"}',
            400,
          );
        }
        return http.Response('{"success":true}', 201);
      });
      await expectLater(
        DummyData.insert(
          clientType: '2',
          client: client,
          baseUrl: 'http://example.test',
          onResult: (value) => results = value,
        ),
        throwsException,
      );
      expect(posts, [
        '/api/user-group',
        '/api/printer',
        '/api/customer-display',
        '/api/cash-drawer',
      ]);
      final group = results.singleWhere((r) => r.table == 'User_Group');
      expect(group.status, contains('HTTP 400'));
      expect(group.status, contains('Group description is too long'));
      expect(
        results.singleWhere((r) => r.table == 'User_File').status,
        contains('user group setup failed'),
      );
      expect(results.singleWhere((r) => r.table == 'Cash_Drawer').inserted, 1);
    },
  );
  test(
    'SQLite seeds all six schemas and preserves existing rows on retry',
    () async {
      sqfliteFfiInit();
      final source = await databaseFactoryFfi.openDatabase(
        File('assets/database/Fudo.db').absolute.path,
        options: OpenDatabaseOptions(readOnly: true),
      );
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(() async {
        await db.close();
        await source.close();
      });
      for (final table in DummyData.rows.keys) {
        final schema = await source.rawQuery(
          'SELECT sql FROM sqlite_master WHERE lower(name) = lower(?)',
          [table],
        );
        await db.execute(schema.single['sql'] as String);
      }
      final network = MockClient(
        (_) async => throw StateError('Unexpected HTTP'),
      );
      expect(
        await DummyData.insert(clientType: '1', database: db, client: network),
        44,
      );
      for (final entry in DummyData.rows.entries) {
        expect(await db.query(entry.key), hasLength(entry.value.length));
      }
      await db.update('User_File', {'User_Pwd': 'existing-password'});
      expect(await DummyData.insert(clientType: '1', database: db), 0);
      expect(
        (await db.query('User_File')).single['User_Pwd'],
        'existing-password',
      );
    },
  );

  test('server seeds all six tables and retries partial failures', () async {
    final stored = <String, List<Map<String, dynamic>>>{
      'user-group': [],
      'users': [],
      'user-setup': [],
      'printer': [],
      'customer-display': [],
      'cash-drawer': [],
    };
    final posted = <String>[];
    var failDisplay = true;
    final client = MockClient((request) async {
      if (request.url.path == '/api/user-setup/group-screen') {
        final query = jsonDecode(request.body) as Map<String, dynamic>;
        if (stored['user-setup']!.isEmpty) {
          return http.Response(
            '{"success":false,"message":"No User Setup records found for this Group and Screen"}',
            404,
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': stored['user-setup']!
                .where(
                  (row) =>
                      row['Group_Code'] == query['Group_Code'] &&
                      row['Screen_ID'] == query['Screen_ID'],
                )
                .toList(),
          }),
          200,
        );
      }
      final route = request.url.path.split('/').last;
      final table = switch (route) {
        'printers' => 'printer',
        'customer-displays' => 'customer-display',
        'cash-drawers' => 'cash-drawer',
        _ => route,
      };
      expect(
        stored.containsKey(table),
        isTrue,
        reason: 'Unexpected endpoint: $route',
      );
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({'success': true, 'data': stored[table]}),
          200,
        );
      }
      expect(request.method, 'POST');
      final row = jsonDecode(request.body) as Map<String, dynamic>;
      if (table == 'customer-display' && failDisplay) {
        failDisplay = false;
        return http.Response('{"success":false}', 500);
      }
      if (table == 'users') {
        expect(
          stored['user-group']!.any(
            (g) => g['Group_Code'] == row['Group_Code'],
          ),
          isTrue,
        );
      }
      if (table == 'printer') {
        expect(row, {
          ...DummyData.rows['Print_Mast']!.single,
          'Printer_Port': 9100,
        });
      }
      if (table == 'customer-display') {
        expect(row['Display_Port'], isA<int>());
      }
      if (table == 'user-setup') {
        for (final key in ['Group_Code', 'Function_ID', 'Screen_ID']) {
          expect((row[key] as String).trim(), isNotEmpty);
        }
        final sample = DummyData.rows['User_setup']!.firstWhere(
          (sample) =>
              sample['Group_Code'] == row['Group_Code'] &&
              sample['Screen_ID'] == row['Screen_ID'] &&
              (sample['Function_ID'] == row['Function_ID'] ||
                  (sample['Function_ID'] == '' &&
                      row['Function_ID'] == sample['Screen_ID'])),
        );
        expect(
          row['Function_ID'],
          sample['Function_ID'] == ''
              ? sample['Screen_ID']
              : sample['Function_ID'],
        );
        expect(
          row.keys,
          unorderedEquals([
            'Group_Code',
            'Function_ID',
            'Screen_ID',
            'Access_Level',
          ]),
        );
        expect(row['Access_Level'], isA<int>());
        expect(
          stored['user-group']!.any(
            (group) => group['Group_Code'] == row['Group_Code'],
          ),
          isTrue,
        );
      }
      posted.add(table);
      stored[table]!.add(row);
      return http.Response('{"success":true}', 201);
    });
    List<DummyTableResult> results = [];
    Future<int> seed() => DummyData.insert(
      clientType: '2',
      client: client,
      baseUrl: 'http://example.test',
      onResult: (value) => results = value,
    );
    await expectLater(seed(), throwsException);
    expect(results.singleWhere((r) => r.table == 'User_Group').inserted, 2);
    expect(
      results.singleWhere((r) => r.table == 'Customer_Display').status,
      contains('not confirmed'),
    );
    expect(
      results.singleWhere((r) => r.table == 'Cash_Drawer').status,
      'Complete',
    );
    expect(
      results.singleWhere((r) => r.table == 'Print_Mast').status,
      'Complete',
    );
    expect(
      stored['user-setup'],
      hasLength(DummyData.rows['User_setup']!.length),
    );
    expect(
      results.singleWhere((r) => r.table == 'User_setup').status,
      'Complete',
    );
    expect(posted.where((table) => table != 'user-setup'), [
      'user-group',
      'user-group',
      'users',
      'printer',
      'cash-drawer',
    ]);
    stored['users']!.single['User_Pwd'] = 'preserved';
    expect(await seed(), 1);
    expect(await seed(), 0);
    expect(results.fold<int>(0, (count, r) => count + r.inserted), 0);
    expect(
      results.fold<int>(0, (count, r) => count + r.existing),
      6 + DummyData.rows['User_setup']!.length,
    );
    expect(
      posted.where((table) => table == 'user-setup'),
      hasLength(DummyData.rows['User_setup']!.length),
    );
    expect(posted.where((table) => table != 'user-setup'), [
      'user-group',
      'user-group',
      'users',
      'printer',
      'cash-drawer',
      'customer-display',
    ]);
    expect(stored['users']!.single['User_Pwd'], 'preserved');
  });

  test(
    'unsupported client types fail before accessing either destination',
    () async {
      await expectLater(DummyData.insert(clientType: '3'), throwsStateError);
    },
  );
}
