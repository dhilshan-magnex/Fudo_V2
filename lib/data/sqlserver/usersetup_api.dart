import '../../core/config/server_settings.dart';
import '../../functions/uservalidation/app_functions.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/api_http_client.dart';

class UserGroupAlreadyExistsException implements Exception {
  @override
  String toString() => 'User Group already exists';
}

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

  Future<int> syncUserSetup({bool clearExistingData = false}) async {
    final baseUrl = _baseUrl.isNotEmpty
        ? _baseUrl
        : await ServerSettings.getBaseUrl();
    final rows = await UserSetupApi(
      client: _client,
      baseUrl: baseUrl,
    ).getUserSetup();
    return rows.length;
  }

  Future<int> syncUserGroups({bool clearExistingData = false}) async {
    final baseUrl = _baseUrl.isNotEmpty
        ? _baseUrl
        : await ServerSettings.getBaseUrl();
    final rows = await UserSetupApi(
      client: _client,
      baseUrl: baseUrl,
    ).getUserGroups();
    return rows.length;
  }

  Future<void> createUserSetup({
    required String groupCode,
    required String functionId,
    required String screenId,
    required int accessLevel,
  }) async {
    if (groupCode.trim().isEmpty ||
        functionId.trim().isEmpty ||
        screenId.trim().isEmpty) {
      throw ArgumentError(
        'Group Code, Function ID and Screen ID are required.',
      );
    }
    final response = await _post('/user-setup', {
      'Group_Code': groupCode,
      'Function_ID': functionId,
      'Screen_ID': screenId,
      'Access_Level': accessLevel,
    });
    _payloadFromResponse(response, 'Create user setup');
  }

  Future<List<Map<String, dynamic>>> getUserSetupByGroupScreen({
    required String groupCode,
    required String screenId,
  }) async {
    final response = await _post('/user-setup/group-screen', {
      'Group_Code': groupCode,
      'Screen_ID': screenId,
    });
    // This API reports an empty permission set as a domain-specific 404.
    // Keep missing routes and other server errors visible to callers.
    if (response.statusCode == 404) {
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map &&
            (payload['message'] ?? payload['error'])
                    ?.toString()
                    .trim()
                    .toLowerCase() ==
                'no user setup records found for this group and screen') {
          return [];
        }
      } on FormatException {
        // The standard handler below reports non-JSON errors.
      }
    }
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
    try {
      final payload = jsonDecode(response.body);
      if (payload is Map &&
          payload['success'] == false &&
          payload['message']?.toString().trim().toLowerCase() ==
              'user group already exists') {
        throw UserGroupAlreadyExistsException();
      }
    } on FormatException {
      // Let the standard response handler report invalid server responses.
    }
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
