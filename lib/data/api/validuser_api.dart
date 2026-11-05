import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import 'api_http_client.dart';

class ValidUserApi {
  ValidUserApi({http.Client? client})
    : _client = client ?? ApiHttpClient.instance;

  static const String validUserEndpoint = 'validuser';

  final http.Client _client;

  Future<bool> isValidClientLocation({
    required String clientId,
    required String locationId,
    Map<String, String>? headers,
  }) async {
    final normalizedClientId = clientId.trim();
    final normalizedLocationId = locationId.trim();
    if (normalizedClientId.isEmpty || normalizedLocationId.isEmpty) {
      throw ArgumentError('Client_ID and Location_ID are required.');
    }

    final url = ApiConfig.urlForClient(
      validUserEndpoint,
      clientId: normalizedClientId,
      locationId: normalizedLocationId,
    );
    final response = await _client.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 400 || response.statusCode == 404) return false;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Client validation API failed with status ${response.statusCode}.',
      );
    }

    final body = response.body.trim();
    dynamic result;
    try {
      result = jsonDecode(body);
    } on FormatException {
      result = body;
    }

    if (result == true || result.toString().toLowerCase() == 'true') {
      return true;
    }
    if (result == false || result.toString().toLowerCase() == 'false') {
      return false;
    }

    throw const FormatException(
      'Client validation API must return true or false.',
    );
  }
}
