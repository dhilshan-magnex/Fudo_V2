import 'package:fudo_v2/core/config/server_settings.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/api_http_client.dart';

class UsersApi {
  UsersApi({http.Client? client, String? baseUrl})
    : _client = client ?? ApiHttpClient.instance,
      _baseUrl = (baseUrl ?? '').trim();

  final http.Client _client;
  final String _baseUrl;

  /// Fetches server users without persisting a local copy.
  Future<int> syncUsers() async {
    final baseUrl = _baseUrl.isNotEmpty
        ? _baseUrl
        : await ServerSettings.getBaseUrl();
    final rows = await UsersApi(client: _client, baseUrl: baseUrl).getUsers();
    return rows.length;
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
