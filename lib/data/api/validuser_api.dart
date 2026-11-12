import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../core/config/server_settings.dart';
import 'api_http_client.dart';

class ValidUserApi {
  ValidUserApi({http.Client? client, String? baseUrl})
    : _client = client ?? ApiHttpClient.instance,
      _baseUrl = (baseUrl ?? '').trim();

  static const String validUserEndpoint = 'validuser';

  final http.Client _client;
  final String _baseUrl;

  Future<Map<String, dynamic>?> validateCredentials({
    required String userId,
    required String password,
  }) async {
    final baseUrl = _baseUrl.isNotEmpty
        ? _baseUrl
        : (await ServerSettings.getBaseUrl() ?? '').trim();
    if (baseUrl.isEmpty) {
      throw StateError('Enter the Node.js API server address in device setup.');
    }
    final base = Uri.parse(baseUrl);
    final path = base.path.replaceFirst(RegExp(r'/+$'), '');
    final apiPath = path.endsWith('/api') ? path : '$path/api';
    final url = base.replace(path: '$apiPath/validate-user');
    final response = await _client
        .post(
          url,
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'User_ID': userId.trim(), 'User_Pwd': password}),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 401 || response.statusCode == 403) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'User validation API failed with status ${response.statusCode}.',
      );
    }
    final result = jsonDecode(response.body);
    if (result is! Map || result['success'] is! bool) {
      throw const FormatException('User validation API returned invalid data.');
    }
    if (result['success'] == false) return null;
    final data = result['data'];
    if (data is! Map || (data['User_ID'] ?? '').toString().trim().isEmpty) {
      throw const FormatException(
        'User validation API returned no user profile.',
      );
    }
    final user = Map<String, dynamic>.from(data);
    final active = user['User_Active'];
    if (active != 1 && active != true && active != '1') return null;
    user.remove('User_Pwd');
    return user;
  }

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
