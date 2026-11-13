import '../../core/config/server_settings.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/api_http_client.dart';

class CashDrawerApi {
  CashDrawerApi({http.Client? client, String? baseUrl})
    : _client = client ?? ApiHttpClient.instance,
      _baseUrl = (baseUrl ?? '').trim();

  final http.Client _client;
  final String _baseUrl;

  Future<int> syncCashDrawers({bool clearExistingData = false}) async {
    final baseUrl = _baseUrl.isNotEmpty
        ? _baseUrl
        : await ServerSettings.getBaseUrl();
    final rows = await CashDrawerApi(
      client: _client,
      baseUrl: baseUrl,
    ).getCashDrawers();
    return rows.length;
  }

  Future<List<Map<String, dynamic>>> getCashDrawers() async {
    final response = await _client.get(
      await _uri('/cash-drawers'),
      headers: const {'Accept': 'application/json'},
    );
    return _rowsFromResponse(response, 'Get cash drawers');
  }

  Future<List<Map<String, dynamic>>> getCashDrawer(String drawerCode) async {
    _validateDrawerCode(drawerCode);
    final response = await _client.get(
      await _uri('/cash-drawer', {'Drawer_Code': drawerCode}),
      headers: const {'Accept': 'application/json'},
    );
    return _rowsFromResponse(response, 'Get cash drawer');
  }

  Future<void> createCashDrawer({
    required String drawerCode,
    String? drawerName,
    String? drawerPort,
    String? drawerType,
  }) async {
    _validateDrawerCode(drawerCode);
    _validateLength(drawerName, 'Drawer_Name', 30);
    _validateLength(drawerPort, 'Drawer_Port', 10);
    _validateLength(drawerType, 'Drawer_Type', 10);

    final response = await _client.post(
      await _uri('/cash-drawer'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Drawer_Code': drawerCode,
        'Drawer_Name': drawerName,
        'Drawer_Port': drawerPort,
        'Drawer_Type': drawerType,
      }),
    );
    _payloadFromResponse(response, 'Create cash drawer');
  }

  void _validateDrawerCode(String drawerCode) {
    if (drawerCode.trim().isEmpty) {
      throw ArgumentError('Drawer_Code is required.');
    }
    _validateLength(drawerCode, 'Drawer_Code', 10);
  }

  void _validateLength(String? value, String field, int maxLength) {
    if (value != null && value.length > maxLength) {
      throw ArgumentError('$field must be at most $maxLength characters.');
    }
  }

  Future<Uri> _uri(String path, [Map<String, String>? queryParameters]) async {
    final baseUrl = _baseUrl.isNotEmpty
        ? _baseUrl
        : (await ServerSettings.getBaseUrl() ?? '').trim();
    if (baseUrl.isEmpty) {
      throw StateError('Enter the Node.js API server address in device setup.');
    }
    final base = Uri.parse(baseUrl);
    final apiPath = '${base.path.replaceFirst(RegExp(r'/+$'), '')}/api$path';
    return base.replace(path: apiPath, queryParameters: queryParameters);
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
      String detail = '';
      try {
        final body = jsonDecode(response.body);
        if (body is Map) {
          final message = body['message'] ?? body['error'];
          if (message is String) detail = message;
        }
      } on FormatException {
        // HTML or empty error responses have no API message to display.
      }
      throw Exception(
        '$operation failed (HTTP ${response.statusCode})'
        '${detail.isEmpty ? '.' : ': $detail'}',
      );
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
