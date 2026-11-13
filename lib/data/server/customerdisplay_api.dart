import '../../core/config/server_settings.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/api_http_client.dart';

class CustomerDisplayApi {
  CustomerDisplayApi({http.Client? client, String? baseUrl})
    : _client = client ?? ApiHttpClient.instance,
      _baseUrl = (baseUrl ?? '').trim();

  final http.Client _client;
  final String _baseUrl;

  Future<int> syncCustomerDisplays({bool clearExistingData = false}) async {
    final baseUrl = _baseUrl.isNotEmpty
        ? _baseUrl
        : await ServerSettings.getBaseUrl();
    final rows = await CustomerDisplayApi(
      client: _client,
      baseUrl: baseUrl,
    ).getCustomerDisplays();
    return rows.length;
  }

  Future<List<Map<String, dynamic>>> getCustomerDisplay(
    String displayCode,
  ) async {
    final response = await _client.get(
      await _uri('/customer-display', {'Display_Code': displayCode}),
      headers: const {'Accept': 'application/json'},
    );
    return _rowsFromResponse(response, 'Get customer display');
  }

  Future<List<Map<String, dynamic>>> getCustomerDisplays() async {
    final response = await _client.get(
      await _uri('/customer-displays'),
      headers: const {'Accept': 'application/json'},
    );
    return _rowsFromResponse(response, 'Get customer displays');
  }

  Future<void> createCustomerDisplay({
    required String displayCode,
    required String displayName,
    required int displayPort,
    String? displayType,
  }) async {
    final response = await _client.post(
      await _uri('/customer-display'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Display_Code': displayCode,
        'Display_Name': displayName,
        'Display_Port': displayPort,
        'Display_Type': ?displayType,
      }),
    );
    _payloadFromResponse(response, 'Create customer display');
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
