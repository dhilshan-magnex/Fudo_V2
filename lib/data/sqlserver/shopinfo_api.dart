import '../../core/config/server_settings.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/api_http_client.dart';

class ShopInfoApi {
  ShopInfoApi({http.Client? client, String? baseUrl})
    : _client = client ?? ApiHttpClient.instance,
      _baseUrl = (baseUrl ?? '').trim();

  final http.Client _client;
  final String _baseUrl;

  Future<List<Map<String, dynamic>>> getShopInfo() async {
    final response = await _client.get(
      await _uri('/shop-info'),
      headers: const {'Accept': 'application/json'},
    );
    final payload = _payloadFromResponse(response, 'Get shop information');
    final data = payload['data'];
    if (data is! List || data.any((row) => row is! Map)) {
      throw const FormatException(
        'Get shop information returned invalid data.',
      );
    }
    return data.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<void> createShopInfo({
    required String clientId,
    required String locationId,
    required String locationName,
    String? locationAddress1,
    String? locationAddress2,
    String? locationPhone,
    String? locationMobile,
    String? locationEmail,
    String? footerMessage1,
    String? footerMessage2,
    String? footerMessageL1,
    String? footerMessage2L1,
    String? currencyCode,
    int currencyDecimal = 2,
    int taxInclusive = 0,
    num serviceCharge = 0,
    num deliveryCharge = 0,
    num salesTarget = 0,
  }) async {
    final response = await _client.post(
      await _uri('/shop-info'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Client_ID': clientId,
        'Location_ID': locationId,
        'Location_Name': locationName,
        'Location_Address1': locationAddress1,
        'Location_Address2': locationAddress2,
        'Location_Phone': locationPhone,
        'Location_Mobile': locationMobile,
        'Location_Email': locationEmail,
        'Footer_Message1': footerMessage1,
        'Footer_Message2': footerMessage2,
        'Footer_Message_L1': footerMessageL1,
        'Footer_Message2_L1': footerMessage2L1,
        'Currency_Code': currencyCode,
        'Currency_Decimal': currencyDecimal,
        'Tax_Inclusive': taxInclusive,
        'Service_Charge': serviceCharge,
        'Delivery_Charge': deliveryCharge,
        'Sales_target': salesTarget,
      }),
    );
    _payloadFromResponse(response, 'Create shop information');
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
      String? detail;
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map) {
          final messages = <String>{};
          for (final key in ['message', 'error', 'detail']) {
            final value = payload[key];
            final message = value is String
                ? value
                : value is Map && value['message'] is String
                ? value['message'] as String
                : null;
            if (message != null && message.trim().isNotEmpty) {
              messages.add(message.trim());
            }
          }
          if (messages.isNotEmpty) detail = messages.join(' — ');
        }
      } on FormatException {
        // Proxies may return HTML rather than a JSON API error.
      }
      throw Exception(
        '$operation failed with status ${response.statusCode}. '
        '${detail ?? 'The API did not provide an error message. The server administrator needs to check this request.'}',
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
