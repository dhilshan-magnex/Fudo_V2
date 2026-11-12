import 'package:fudo_v2/core/config/server_settings.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import '../api/api_http_client.dart';
import '../database/db_manager.dart';

class UsersApi {
  UsersApi({http.Client? client, String? baseUrl})
    : _client = client ?? ApiHttpClient.instance,
      _baseUrl = (baseUrl ?? '').trim();

  final http.Client _client;
  final String _baseUrl;

  /// Merges server users without deleting local accounts or omitted passwords.
  Future<int> syncUsers({Database? database}) async {
    final baseUrl = _baseUrl.isNotEmpty
        ? _baseUrl
        : await ServerSettings.getBaseUrl();
    final rows = await UsersApi(client: _client, baseUrl: baseUrl).getUsers();
    final db = database ?? await DBManager.getDatabase(AppDatabase.fudo);
    return db.transaction((txn) async {
      final schema = await txn.rawQuery('PRAGMA table_info(User_File)');
      final columns = schema.map((column) => column['name'] as String);
      for (final row in rows) {
        final fields = {
          for (final entry in row.entries) entry.key.toLowerCase(): entry.value,
        };
        final values = <String, Object?>{
          for (final column in columns)
            if (fields.containsKey(column.toLowerCase()))
              column: fields[column.toLowerCase()] is bool
                  ? (fields[column.toLowerCase()] == true ? 1 : 0)
                  : fields[column.toLowerCase()],
        };
        final userId = values['User_ID'];
        if (userId == null || userId.toString().trim().isEmpty) {
          throw const FormatException('Server user is missing User_ID.');
        }
        // User-list responses may omit or redact credentials. Only replace a
        // saved password when the server supplies a non-empty value.
        values.removeWhere(
          (key, value) =>
              key.toLowerCase() == 'user_pwd' &&
              (value == null || value.toString().isEmpty),
        );
        final updated = await txn.update(
          'User_File',
          values,
          where: 'User_ID = ?',
          whereArgs: [userId],
        );
        if (updated == 0) await txn.insert('User_File', values);
      }
      return rows.length;
    });
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await _client
        .get(
          await _uri('/users'),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));
    final payload = _payloadFromResponse(response, 'Get users');
    final data = payload['data'];
    if (data is! List || data.any((row) => row is! Map)) {
      throw const FormatException('Get users returned invalid user data.');
    }
    return data.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<void> createUser({
    required String userId,
    required String userName,
    required String groupCode,
    required String userPwd,
    int userActive = 1,
  }) async {
    final response = await _client.post(
      await _uri('/users'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'User_ID': userId,
        'User_Name': userName,
        'Group_Code': groupCode,
        'User_Active': userActive,
        'User_Pwd': userPwd,
      }),
    );
    _payloadFromResponse(response, 'Create user');
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
