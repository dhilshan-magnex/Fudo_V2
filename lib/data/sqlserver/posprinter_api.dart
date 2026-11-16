import '../../core/config/server_settings.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/api_http_client.dart';

class PosPrinterApi {
  PosPrinterApi({http.Client? client, String? baseUrl})
    : _client = client ?? ApiHttpClient.instance,
      _baseUrl = (baseUrl ?? '').trim();

  final http.Client _client;
  final String _baseUrl;

  Future<void> createPrinter({
    required String printerCode,
    required String printerName,
    required String printerPath,
    required int printerPort,
    required String printerType,
    required String printerModel,
  }) async {
    final response = await _client.post(
      _uri('/printer'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Printer_Code': printerCode,
        'Printer_Name': printerName,
        'Printer_Path': printerPath,
        'Printer_Port': printerPort,
        'Printer_Type': printerType,
        'Printer_Model': printerModel,
      }),
    );
    _ensureSuccess(response, 'Create printer');
    final payload = jsonDecode(response.body);
    if (payload is! Map || payload['success'] != true) {
      throw Exception(
        'Create printer failed: ${payload is Map ? payload['message'] ?? 'unknown error' : 'invalid response'}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getPrinters() async {
    final response = await _client.get(
      _uri('/printers'),
      headers: const {'Accept': 'application/json'},
    );
    return _rowsFromResponse(response, 'Get Print_Mast');
  }

  Future<int> syncPrinters({bool clearExistingData = false}) async {
    final baseUrl = _baseUrl.isNotEmpty
        ? _baseUrl
        : await ServerSettings.getBaseUrl();
    final rows = await PosPrinterApi(
      client: _client,
      baseUrl: baseUrl,
    ).getPrinters();
    return rows.length;
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
      'Reciept_Prn_Code': receiptCode,
      'Cash_Drawer_Code': cashDrawerCode ?? '',
      'Customer_Display_Code': customerDisplayCode ?? '',
    };
    final response = await _client.post(
      _uri('/pos'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    _ensureSuccess(response, 'Create POS (counter "$counterNo")');
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
      var detail = response.body.trim();
      try {
        final payload = jsonDecode(detail);
        if (payload is Map) {
          final errors = [
            for (final key in ['message', 'error', 'errors', 'detail'])
              if (payload[key] != null) payload[key].toString(),
          ];
          if (errors.isNotEmpty) detail = errors.join('; ');
        }
      } on FormatException {
        // Some servers return plain text instead of a JSON error body.
      }
      if (detail.length > 1200) detail = '${detail.substring(0, 1200)}...';
      throw Exception(
        '$operation failed with status ${response.statusCode}. '
        '${detail.isEmpty ? "The server returned no error details." : detail}',
      );
    }
  }
}
