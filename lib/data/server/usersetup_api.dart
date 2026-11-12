import 'package:sqflite/sqflite.dart';
import '../../core/config/server_settings.dart';
import '../database/db_manager.dart';
import '../../functions/uservalidation/app_functions.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/api_http_client.dart';

class UserSetupApi {
  UserSetupApi({http.Client? client, String? baseUrl})
    : _client = client ?? ApiHttpClient.instance,
      _baseUrl = (baseUrl ?? '').trim();

  final http.Client _client;
  final String _baseUrl;

  static const _screenIds = [
    AppFunctions.billingScreen,
    AppFunctions.dataSyncScreen,
  ];

  Future<List<Map<String, dynamic>>> getUserSetup() async {
    final groups = await getUserGroups();
    final rows = <Map<String, dynamic>>[];
    final groupCodes = <String>{};
    for (final group in groups) {
      final code = group['Group_Code']?.toString().trim() ?? '';
      if (code.isEmpty) {
        throw FormatException('User group is missing Group_Code.');
      }
      groupCodes.add(code);
    }
    for (final groupCode in groupCodes) {
      for (final screenId in _screenIds) {
        rows.addAll(
          await getUserSetupByGroupScreen(
            groupCode: groupCode,
            screenId: screenId,
          ),
        );
      }
    }
    return rows;
  }

  Future<int> syncUserSetup({
    bool clearExistingData = false,
    Database? database,
  }) async {
    final baseUrl = _baseUrl.isNotEmpty
        ? _baseUrl
        : await ServerSettings.getBaseUrl();
    final rows = await UserSetupApi(
      client: _client,
      baseUrl: baseUrl,
    ).getUserSetup();
    const table = 'User_setup';
    final db = database ?? await DBManager.getDatabase(AppDatabase.fudo);
    return db.transaction((txn) async {
      final schema = await txn.rawQuery('PRAGMA table_info("$table")');
      if (schema.isEmpty) throw StateError('Missing SQLite table $table.');
      final columns = schema.map((c) => c['name'] as String).toList();
      final keys = schema
          .where((c) => (c['pk'] as int) > 0)
          .map((c) => c['name'] as String)
          .toList();
      if (keys.isEmpty) throw StateError('$table has no primary key.');
      if (clearExistingData) {
        await txn.delete(
          table,
          where: 'Screen_ID IN (?, ?)',
          whereArgs: _screenIds,
        );
      }
      for (final row in rows) {
        final fields = {
          for (final e in row.entries) e.key.toLowerCase(): e.value,
        };
        final values = <String, Object?>{
          for (final column in columns)
            if (fields.containsKey(column.toLowerCase()))
              column: fields[column.toLowerCase()] is bool
                  ? (fields[column.toLowerCase()] == true ? 1 : 0)
                  : fields[column.toLowerCase()],
        };
        for (final key in keys) {
          if (values[key] == null || values[key].toString().trim().isEmpty) {
            throw FormatException('$table server row is missing $key.');
          }
        }
        final updated = await txn.update(
          table,
          values,
          where: keys.map((key) => '"$key" = ?').join(' AND '),
          whereArgs: keys.map((key) => values[key]).toList(),
        );
        if (updated == 0) await txn.insert(table, values);
      }
      return rows.length;
    });
  }

  Future<int> syncUserGroups({
    bool clearExistingData = false,
    Database? database,
  }) async {
    final baseUrl = _baseUrl.isNotEmpty
        ? _baseUrl
        : await ServerSettings.getBaseUrl();
    final rows = await UserSetupApi(
      client: _client,
      baseUrl: baseUrl,
    ).getUserGroups();
    const table = 'User_Group';
    final db = database ?? await DBManager.getDatabase(AppDatabase.fudo);
    return db.transaction((txn) async {
      final schema = await txn.rawQuery('PRAGMA table_info("$table")');
      if (schema.isEmpty) throw StateError('Missing SQLite table $table.');
      final columns = schema.map((c) => c['name'] as String).toList();
      final keys = schema
          .where((c) => (c['pk'] as int) > 0)
          .map((c) => c['name'] as String)
          .toList();
      if (keys.isEmpty) throw StateError('$table has no primary key.');
      if (clearExistingData) await txn.delete(table);
      for (final row in rows) {
        final fields = {
          for (final e in row.entries) e.key.toLowerCase(): e.value,
        };
        final values = <String, Object?>{
          for (final column in columns)
            if (fields.containsKey(column.toLowerCase()))
              column: fields[column.toLowerCase()] is bool
                  ? (fields[column.toLowerCase()] == true ? 1 : 0)
                  : fields[column.toLowerCase()],
        };
        for (final key in keys) {
          if (values[key] == null || values[key].toString().trim().isEmpty) {
            throw FormatException('$table server row is missing $key.');
          }
        }
        final updated = await txn.update(
          table,
          values,
          where: keys.map((key) => '"$key" = ?').join(' AND '),
          whereArgs: keys.map((key) => values[key]).toList(),
        );
        if (updated == 0) await txn.insert(table, values);
      }
      return rows.length;
    });
  }

  Future<List<Map<String, dynamic>>> getUserSetupByGroupScreen({
    required String groupCode,
    required String screenId,
  }) async {
    final response = await _post('/user-setup/group-screen', {
      'Group_Code': groupCode,
      'Screen_ID': screenId,
    });
    return _rowsFromResponse(response, 'Get user setup by group and screen');
  }

  Future<List<Map<String, dynamic>>> getUserSetupByGroupFunction({
    required String groupCode,
    required String functionId,
  }) async {
    final response = await _post('/user-setup/group-function', {
      'Group_Code': groupCode,
      'Function_ID': functionId,
    });
    return _rowsFromResponse(response, 'Get user setup by group and function');
  }

  Future<List<Map<String, dynamic>>> getUserGroups() async {
    final response = await _client.get(
      await _uri('/user-group'),
      headers: const {'Accept': 'application/json'},
    );
    return _rowsFromResponse(response, 'Get user groups');
  }

  Future<void> createUserGroup({
    required String groupCode,
    required String groupName,
    required String groupDescr,
  }) async {
    final response = await _post('/user-group', {
      'Group_Code': groupCode,
      'Group_Name': groupName,
      'Group_Descr': groupDescr,
    });
    _payloadFromResponse(response, 'Create user group');
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    return _client.post(
      await _uri(path),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  Future<Uri> _uri(String path) async {
    final baseUrl = _baseUrl.isNotEmpty
        ? _baseUrl
        : (await ServerSettings.getBaseUrl() ?? '').trim();
    if (baseUrl.isEmpty) {
      throw StateError('Enter the Node.js API server address in device setup.');
    }
    final base = Uri.parse(baseUrl);
    final apiPath = '${base.path.replaceFirst(RegExp(r'/+$'), '')}/api$path';
    return base.replace(path: apiPath);
  }

  List<Map<String, dynamic>> _rowsFromResponse(
    http.Response response,
    String operation,
  ) {
    final payload = _payloadFromResponse(response, operation);
    final data = payload['data'];
    if (data is! List || data.any((row) => row is! Map)) {
      throw FormatException('$operation returned invalid data.');
    }
    return data.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Map<String, dynamic> _payloadFromResponse(
    http.Response response,
    String operation,
  ) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('$operation failed with status ${response.statusCode}.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw FormatException('$operation returned an invalid response.');
    }
    if (decoded['success'] == false) {
      throw Exception(
        '$operation failed: ${decoded['message'] ?? 'unknown error'}',
      );
    }
    return Map<String, dynamic>.from(decoded);
  }
}
