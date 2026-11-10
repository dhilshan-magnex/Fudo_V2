import 'package:sqflite/sqflite.dart';
import '../../core/config/server_settings.dart';
import '../database/db_manager.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/api_http_client.dart';

class PosPrinterApi {
  PosPrinterApi({http.Client? client, String? baseUrl})
    : _client = client ?? ApiHttpClient.instance,
      _baseUrl = (baseUrl ?? '').trim();

  final http.Client _client;
  final String _baseUrl;

  Future<List<Map<String, dynamic>>> getPrinters() async {
    final response = await _client.get(
      _uri('/printers'),
      headers: const {'Accept': 'application/json'},
    );
    return _rowsFromResponse(response, 'Get Print_Mast');
  }

  Future<int> syncPrinters({
    bool clearExistingData = false,
    Database? database,
  }) async {
    final baseUrl = _baseUrl.isNotEmpty
        ? _baseUrl
        : await ServerSettings.getBaseUrl();
    final rows = await PosPrinterApi(
      client: _client,
      baseUrl: baseUrl,
    ).getPrinters();
    const table = 'Print_Mast';
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

  Future<List<Map<String, dynamic>>> getPos(String counterNo) async {
    final response = await _client.get(
      _uri('/pos', {'Counter_No': counterNo}),
      headers: const {'Accept': 'application/json'},
    );
    return _rowsFromResponse(response, 'Get POS');
  }

  Future<void> createPos({
    required String counterNo,
    required String counterName,
    required String receiptCode,
    String? cashDrawerCode,
    String? customerDisplayCode,
  }) async {
    final body = <String, dynamic>{
      'Counter_No': counterNo,
      'Counter_Name': counterName,
      'Receipt_Code': receiptCode,
      if (cashDrawerCode != null && cashDrawerCode.isNotEmpty)
        'Cash_Drawer_Code': cashDrawerCode,
      if (customerDisplayCode != null && customerDisplayCode.isNotEmpty)
        'Cus_Display_Code': customerDisplayCode,
    };
    final response = await _client.post(
      _uri('/pos'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    _ensureSuccess(response, 'Create POS');
    final payload = jsonDecode(response.body);
    if (payload is Map && payload['success'] == false) {
      throw Exception(
        'Create POS failed: ${payload['message'] ?? 'unknown error'}',
      );
    }
  }

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    if (_baseUrl.isEmpty) {
      throw StateError('Enter the Node.js API server address in device setup.');
    }
    final base = Uri.parse(_baseUrl);
    final apiPath = '${base.path.replaceFirst(RegExp(r'/+$'), '')}/api$path';
    return base.replace(path: apiPath, queryParameters: queryParameters);
  }

  List<Map<String, dynamic>> _rowsFromResponse(
    http.Response response,
    String operation,
  ) {
    _ensureSuccess(response, operation);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw FormatException('$operation returned an invalid response.');
    }
    if (decoded['success'] == false) {
      throw Exception(
        '$operation failed: ${decoded['message'] ?? 'unknown error'}',
      );
    }
    final data = decoded['data'];
    if (data is! List || data.any((row) => row is! Map)) {
      throw FormatException('Server returned invalid POS/printer data.');
    }
    return data
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  void _ensureSuccess(http.Response response, String operation) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('$operation failed with status ${response.statusCode}.');
    }
  }
}
